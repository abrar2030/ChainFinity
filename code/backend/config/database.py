"""
Database configuration and connection management
Production-ready database setup with connection pooling, read replicas, and monitoring
"""

import logging
from typing import AsyncGenerator, Optional
from sqlalchemy import create_engine, event, pool
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import QueuePool
import redis.asyncio as redis
from contextlib import asynccontextmanager

from config.settings import settings

logger = logging.getLogger(__name__)

# Base class for all models
Base = declarative_base()

# Async Engine for primary database
async_engine = create_async_engine(
    settings.database.DATABASE_URL,
    echo=settings.database.DB_ECHO,
    echo_pool=settings.database.DB_ECHO_POOL,
    pool_size=settings.database.DB_POOL_SIZE,
    max_overflow=settings.database.DB_MAX_OVERFLOW,
    pool_timeout=settings.database.DB_POOL_TIMEOUT,
    pool_recycle=settings.database.DB_POOL_RECYCLE,
    poolclass=QueuePool,
    future=True,
)

# Async Engine for read replica (if configured)
async_read_engine = None
if settings.database.DATABASE_READ_URL:
    async_read_engine = create_async_engine(
        settings.database.DATABASE_READ_URL,
        echo=settings.database.DB_ECHO,
        echo_pool=settings.database.DB_ECHO_POOL,
        pool_size=settings.database.DB_POOL_SIZE,
        max_overflow=settings.database.DB_MAX_OVERFLOW,
        pool_timeout=settings.database.DB_POOL_TIMEOUT,
        pool_recycle=settings.database.DB_POOL_RECYCLE,
        poolclass=QueuePool,
        future=True,
    )

# Session makers
AsyncSessionLocal = async_sessionmaker(
    bind=async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)

AsyncReadSessionLocal = None
if async_read_engine:
    AsyncReadSessionLocal = async_sessionmaker(
        bind=async_read_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autoflush=False,
        autocommit=False,
    )

# Synchronous engine for migrations and admin tasks
sync_engine = create_engine(
    settings.database.DATABASE_URL.replace("+asyncpg", ""),
    echo=settings.database.DB_ECHO,
    pool_size=settings.database.DB_POOL_SIZE,
    max_overflow=settings.database.DB_MAX_OVERFLOW,
    pool_timeout=settings.database.DB_POOL_TIMEOUT,
    pool_recycle=settings.database.DB_POOL_RECYCLE,
)

SyncSessionLocal = sessionmaker(
    bind=sync_engine,
    autocommit=False,
    autoflush=False,
)

# Redis connection
redis_client: Optional[redis.Redis] = None


async def init_redis():
    """Initialize Redis connection"""
    global redis_client
    try:
        redis_client = redis.from_url(
            settings.redis.REDIS_URL,
            password=settings.redis.REDIS_PASSWORD,
            db=settings.redis.REDIS_DB,
            max_connections=settings.redis.REDIS_MAX_CONNECTIONS,
            socket_timeout=settings.redis.REDIS_SOCKET_TIMEOUT,
            socket_connect_timeout=settings.redis.REDIS_SOCKET_CONNECT_TIMEOUT,
            decode_responses=True,
        )
        # Test connection
        await redis_client.ping()
        logger.info("Redis connection established successfully")
    except Exception as e:
        logger.error(f"Failed to connect to Redis: {e}")
        redis_client = None


async def close_redis():
    """Close Redis connection"""
    global redis_client
    if redis_client:
        await redis_client.close()
        redis_client = None
        logger.info("Redis connection closed")


def get_redis() -> Optional[redis.Redis]:
    """Get Redis client instance"""
    return redis_client


# Database event listeners for monitoring
@event.listens_for(async_engine.sync_engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    """Set database connection parameters"""
    if "postgresql" in str(dbapi_connection):
        # Set PostgreSQL specific parameters
        with dbapi_connection.cursor() as cursor:
            cursor.execute("SET timezone TO 'UTC'")
            cursor.execute("SET statement_timeout = '30s'")


@event.listens_for(async_engine.sync_engine, "checkout")
def receive_checkout(dbapi_connection, connection_record, connection_proxy):
    """Log database connection checkout"""
    logger.debug("Database connection checked out")


@event.listens_for(async_engine.sync_engine, "checkin")
def receive_checkin(dbapi_connection, connection_record):
    """Log database connection checkin"""
    logger.debug("Database connection checked in")


# Dependency functions
async def get_async_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency function to get async database session
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def get_async_read_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency function to get async read-only database session
    Uses read replica if available, otherwise falls back to primary
    """
    session_maker = AsyncReadSessionLocal if AsyncReadSessionLocal else AsyncSessionLocal
    async with session_maker() as session:
        try:
            yield session
        finally:
            await session.close()


def get_sync_session() -> Session:
    """
    Get synchronous database session for migrations and admin tasks
    """
    return SyncSessionLocal()


@asynccontextmanager
async def get_async_session_context():
    """
    Context manager for async database session
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


# Health check functions
async def check_database_health() -> bool:
    """
    Check database connectivity and health
    """
    try:
        async with AsyncSessionLocal() as session:
            result = await session.execute("SELECT 1")
            return result.scalar() == 1
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return False


async def check_redis_health() -> bool:
    """
    Check Redis connectivity and health
    """
    try:
        if redis_client:
            await redis_client.ping()
            return True
        return False
    except Exception as e:
        logger.error(f"Redis health check failed: {e}")
        return False


# Database initialization
async def init_database():
    """
    Initialize database connections and create tables
    """
    try:
        # Test primary database connection
        async with AsyncSessionLocal() as session:
            await session.execute("SELECT 1")
        logger.info("Primary database connection established")
        
        # Test read replica connection if configured
        if AsyncReadSessionLocal:
            async with AsyncReadSessionLocal() as session:
                await session.execute("SELECT 1")
            logger.info("Read replica database connection established")
        
        # Initialize Redis
        await init_redis()
        
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        raise


async def close_database():
    """
    Close all database connections
    """
    try:
        await async_engine.dispose()
        if async_read_engine:
            await async_read_engine.dispose()
        await close_redis()
        logger.info("All database connections closed")
    except Exception as e:
        logger.error(f"Error closing database connections: {e}")


# Cache utilities
class CacheManager:
    """Redis cache manager with TTL support"""
    
    @staticmethod
    async def get(key: str) -> Optional[str]:
        """Get value from cache"""
        if redis_client:
            try:
                return await redis_client.get(key)
            except Exception as e:
                logger.error(f"Cache get error: {e}")
        return None
    
    @staticmethod
    async def set(key: str, value: str, ttl: int = None) -> bool:
        """Set value in cache with optional TTL"""
        if redis_client:
            try:
                ttl = ttl or settings.redis.CACHE_TTL
                await redis_client.setex(key, ttl, value)
                return True
            except Exception as e:
                logger.error(f"Cache set error: {e}")
        return False
    
    @staticmethod
    async def delete(key: str) -> bool:
        """Delete value from cache"""
        if redis_client:
            try:
                await redis_client.delete(key)
                return True
            except Exception as e:
                logger.error(f"Cache delete error: {e}")
        return False
    
    @staticmethod
    async def exists(key: str) -> bool:
        """Check if key exists in cache"""
        if redis_client:
            try:
                return await redis_client.exists(key) > 0
            except Exception as e:
                logger.error(f"Cache exists error: {e}")
        return False


# Global cache manager instance
cache = CacheManager()

