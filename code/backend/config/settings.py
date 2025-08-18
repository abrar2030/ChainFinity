"""
ChainFinity Backend Configuration Settings
Production-ready configuration with environment-specific settings
"""

import os
from typing import List, Optional, Any
from pydantic import BaseSettings, validator, Field
from functools import lru_cache


class DatabaseSettings(BaseSettings):
    """Database configuration settings"""
    
    # Primary Database
    DATABASE_URL: str = Field(
        default="postgresql+asyncpg://postgres:postgres@localhost:5432/chainfinity",
        env="DATABASE_URL"
    )
    
    # Read Replica (for scaling)
    DATABASE_READ_URL: Optional[str] = Field(default=None, env="DATABASE_READ_URL")
    
    # Connection Pool Settings
    DB_POOL_SIZE: int = Field(default=20, env="DB_POOL_SIZE")
    DB_MAX_OVERFLOW: int = Field(default=30, env="DB_MAX_OVERFLOW")
    DB_POOL_TIMEOUT: int = Field(default=30, env="DB_POOL_TIMEOUT")
    DB_POOL_RECYCLE: int = Field(default=3600, env="DB_POOL_RECYCLE")
    
    # Query Settings
    DB_ECHO: bool = Field(default=False, env="DB_ECHO")
    DB_ECHO_POOL: bool = Field(default=False, env="DB_ECHO_POOL")

    class Config:
        env_prefix = "DB_"


class RedisSettings(BaseSettings):
    """Redis configuration for caching and sessions"""
    
    REDIS_URL: str = Field(default="redis://localhost:6379/0", env="REDIS_URL")
    REDIS_PASSWORD: Optional[str] = Field(default=None, env="REDIS_PASSWORD")
    REDIS_DB: int = Field(default=0, env="REDIS_DB")
    REDIS_MAX_CONNECTIONS: int = Field(default=20, env="REDIS_MAX_CONNECTIONS")
    REDIS_SOCKET_TIMEOUT: int = Field(default=5, env="REDIS_SOCKET_TIMEOUT")
    REDIS_SOCKET_CONNECT_TIMEOUT: int = Field(default=5, env="REDIS_SOCKET_CONNECT_TIMEOUT")
    
    # Cache Settings
    CACHE_TTL: int = Field(default=3600, env="CACHE_TTL")  # 1 hour
    SESSION_TTL: int = Field(default=86400, env="SESSION_TTL")  # 24 hours

    class Config:
        env_prefix = "REDIS_"


class SecuritySettings(BaseSettings):
    """Security and authentication settings"""
    
    # JWT Settings
    SECRET_KEY: str = Field(env="SECRET_KEY")
    ALGORITHM: str = Field(default="HS256", env="JWT_ALGORITHM")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=30, env="ACCESS_TOKEN_EXPIRE_MINUTES")
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(default=7, env="REFRESH_TOKEN_EXPIRE_DAYS")
    
    # Password Settings
    PASSWORD_MIN_LENGTH: int = Field(default=8, env="PASSWORD_MIN_LENGTH")
    PASSWORD_REQUIRE_UPPERCASE: bool = Field(default=True, env="PASSWORD_REQUIRE_UPPERCASE")
    PASSWORD_REQUIRE_LOWERCASE: bool = Field(default=True, env="PASSWORD_REQUIRE_LOWERCASE")
    PASSWORD_REQUIRE_NUMBERS: bool = Field(default=True, env="PASSWORD_REQUIRE_NUMBERS")
    PASSWORD_REQUIRE_SPECIAL: bool = Field(default=True, env="PASSWORD_REQUIRE_SPECIAL")
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = Field(default=60, env="RATE_LIMIT_PER_MINUTE")
    RATE_LIMIT_BURST: int = Field(default=100, env="RATE_LIMIT_BURST")
    
    # API Security
    API_KEY_HEADER: str = Field(default="X-API-Key", env="API_KEY_HEADER")
    CORS_ORIGINS: List[str] = Field(default=["*"], env="CORS_ORIGINS")
    CORS_ALLOW_CREDENTIALS: bool = Field(default=True, env="CORS_ALLOW_CREDENTIALS")
    
    # Encryption
    ENCRYPTION_KEY: Optional[str] = Field(default=None, env="ENCRYPTION_KEY")
    FIELD_ENCRYPTION_ENABLED: bool = Field(default=True, env="FIELD_ENCRYPTION_ENABLED")
    
    @validator("CORS_ORIGINS", pre=True)
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v

    class Config:
        env_prefix = "SECURITY_"


class BlockchainSettings(BaseSettings):
    """Blockchain and Web3 configuration"""
    
    # Ethereum Settings
    ETH_RPC_URL: str = Field(default="https://mainnet.infura.io/v3/YOUR_PROJECT_ID", env="ETH_RPC_URL")
    ETH_WEBSOCKET_URL: Optional[str] = Field(default=None, env="ETH_WEBSOCKET_URL")
    ETH_CHAIN_ID: int = Field(default=1, env="ETH_CHAIN_ID")
    
    # Polygon Settings
    POLYGON_RPC_URL: Optional[str] = Field(default=None, env="POLYGON_RPC_URL")
    POLYGON_CHAIN_ID: int = Field(default=137, env="POLYGON_CHAIN_ID")
    
    # BSC Settings
    BSC_RPC_URL: Optional[str] = Field(default=None, env="BSC_RPC_URL")
    BSC_CHAIN_ID: int = Field(default=56, env="BSC_CHAIN_ID")
    
    # Gas Settings
    GAS_PRICE_STRATEGY: str = Field(default="medium", env="GAS_PRICE_STRATEGY")
    MAX_GAS_PRICE: int = Field(default=100, env="MAX_GAS_PRICE")  # Gwei
    
    # Contract Addresses
    GOVERNANCE_TOKEN_ADDRESS: Optional[str] = Field(default=None, env="GOVERNANCE_TOKEN_ADDRESS")
    ASSET_VAULT_ADDRESS: Optional[str] = Field(default=None, env="ASSET_VAULT_ADDRESS")
    
    # API Keys
    ETHERSCAN_API_KEY: Optional[str] = Field(default=None, env="ETHERSCAN_API_KEY")
    POLYGONSCAN_API_KEY: Optional[str] = Field(default=None, env="POLYGONSCAN_API_KEY")

    class Config:
        env_prefix = "BLOCKCHAIN_"


class ComplianceSettings(BaseSettings):
    """Compliance and regulatory settings"""
    
    # KYC Settings
    KYC_ENABLED: bool = Field(default=True, env="KYC_ENABLED")
    KYC_PROVIDER: str = Field(default="jumio", env="KYC_PROVIDER")
    KYC_API_KEY: Optional[str] = Field(default=None, env="KYC_API_KEY")
    KYC_API_SECRET: Optional[str] = Field(default=None, env="KYC_API_SECRET")
    
    # AML Settings
    AML_ENABLED: bool = Field(default=True, env="AML_ENABLED")
    AML_PROVIDER: str = Field(default="chainalysis", env="AML_PROVIDER")
    AML_API_KEY: Optional[str] = Field(default=None, env="AML_API_KEY")
    
    # Transaction Monitoring
    TRANSACTION_MONITORING_ENABLED: bool = Field(default=True, env="TRANSACTION_MONITORING_ENABLED")
    SUSPICIOUS_AMOUNT_THRESHOLD: float = Field(default=10000.0, env="SUSPICIOUS_AMOUNT_THRESHOLD")
    DAILY_TRANSACTION_LIMIT: float = Field(default=50000.0, env="DAILY_TRANSACTION_LIMIT")
    
    # Reporting
    REGULATORY_REPORTING_ENABLED: bool = Field(default=True, env="REGULATORY_REPORTING_ENABLED")
    AUDIT_LOG_RETENTION_DAYS: int = Field(default=2555, env="AUDIT_LOG_RETENTION_DAYS")  # 7 years

    class Config:
        env_prefix = "COMPLIANCE_"


class MonitoringSettings(BaseSettings):
    """Monitoring and observability settings"""
    
    # Logging
    LOG_LEVEL: str = Field(default="INFO", env="LOG_LEVEL")
    LOG_FORMAT: str = Field(default="json", env="LOG_FORMAT")
    LOG_FILE: Optional[str] = Field(default=None, env="LOG_FILE")
    
    # Metrics
    METRICS_ENABLED: bool = Field(default=True, env="METRICS_ENABLED")
    METRICS_PORT: int = Field(default=8001, env="METRICS_PORT")
    
    # Health Checks
    HEALTH_CHECK_INTERVAL: int = Field(default=30, env="HEALTH_CHECK_INTERVAL")
    
    # Sentry
    SENTRY_DSN: Optional[str] = Field(default=None, env="SENTRY_DSN")
    SENTRY_ENVIRONMENT: str = Field(default="production", env="SENTRY_ENVIRONMENT")

    class Config:
        env_prefix = "MONITORING_"


class AppSettings(BaseSettings):
    """Main application settings"""
    
    # Application
    APP_NAME: str = Field(default="ChainFinity API", env="APP_NAME")
    APP_VERSION: str = Field(default="2.0.0", env="APP_VERSION")
    APP_DESCRIPTION: str = Field(default="Production-ready DeFi Analytics Platform", env="APP_DESCRIPTION")
    
    # Environment
    ENVIRONMENT: str = Field(default="production", env="ENVIRONMENT")
    DEBUG: bool = Field(default=False, env="DEBUG")
    
    # Server
    HOST: str = Field(default="0.0.0.0", env="HOST")
    PORT: int = Field(default=8000, env="PORT")
    WORKERS: int = Field(default=4, env="WORKERS")
    
    # API
    API_V1_PREFIX: str = Field(default="/api/v1", env="API_V1_PREFIX")
    DOCS_URL: str = Field(default="/docs", env="DOCS_URL")
    REDOC_URL: str = Field(default="/redoc", env="REDOC_URL")
    
    # External Services
    NOTIFICATION_SERVICE_URL: Optional[str] = Field(default=None, env="NOTIFICATION_SERVICE_URL")
    ANALYTICS_SERVICE_URL: Optional[str] = Field(default=None, env="ANALYTICS_SERVICE_URL")

    class Config:
        env_prefix = "APP_"


class Settings(BaseSettings):
    """Main settings class combining all configuration sections"""
    
    # Sub-settings
    database: DatabaseSettings = DatabaseSettings()
    redis: RedisSettings = RedisSettings()
    security: SecuritySettings = SecuritySettings()
    blockchain: BlockchainSettings = BlockchainSettings()
    compliance: ComplianceSettings = ComplianceSettings()
    monitoring: MonitoringSettings = MonitoringSettings()
    app: AppSettings = AppSettings()
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


# Global settings instance
settings = get_settings()

