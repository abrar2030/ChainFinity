from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import List, Optional
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import database and models
from database import SessionLocal, engine, Base
from models import User, Transaction
from schemas import UserCreate, UserResponse, Token, TokenData, Portfolio
from services.auth import (
    verify_password,
    get_password_hash,
    create_access_token,
    get_current_user,
    get_current_active_user,
    ACCESS_TOKEN_EXPIRE_MINUTES
)
from services.blockchain import (
    get_web3_provider,
    get_eth_balance,
    get_token_balance,
    get_transactions,
    get_portfolio_value
)
from middleware.logging_middleware import LoggingMiddleware

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="ChainFinity API",
    description="API for ChainFinity - DeFi Analytics Platform",
    version="1.0.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add logging middleware
app.add_middleware(LoggingMiddleware)

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Auth routes
@app.post("/api/auth/register", response_model=UserResponse, tags=["authentication"])
async def register(user: UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        hashed_password=hashed_password,
        wallet_address=user.wallet_address
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/api/auth/token", response_model=Token, tags=["authentication"])
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/api/auth/me", response_model=UserResponse, tags=["authentication"])
async def read_users_me(current_user: User = Depends(get_current_active_user)):
    return current_user

# Blockchain routes
@app.get("/api/blockchain/portfolio/{wallet_address}", response_model=Portfolio, tags=["blockchain"])
async def get_portfolio(
    wallet_address: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.wallet_address != wallet_address:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this wallet"
        )
    
    # Get portfolio data from blockchain
    try:
        portfolio_data = get_portfolio_value(wallet_address)
        
        # Get recent transactions from database
        recent_transactions = db.query(Transaction).filter(
            Transaction.user_id == current_user.id
        ).order_by(Transaction.timestamp.desc()).limit(10).all()
        
        portfolio_data["recent_transactions"] = recent_transactions
        return portfolio_data
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@app.get("/api/blockchain/transactions/{wallet_address}", tags=["blockchain"])
async def get_user_transactions(
    wallet_address: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.wallet_address != wallet_address:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this wallet"
        )
    
    # Get transactions from blockchain
    try:
        # Get transactions from database
        transactions = db.query(Transaction).filter(
            Transaction.user_id == current_user.id
        ).order_by(Transaction.timestamp.desc()).all()
        
        return transactions
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@app.get("/api/blockchain/balance/{token_address}", tags=["blockchain"])
async def get_token_balance_endpoint(
    token_address: str,
    network: str = "ethereum",
    current_user: User = Depends(get_current_active_user)
):
    """Get balance for a specific token"""
    try:
        balance_data = get_token_balance(
            token_address,
            current_user.wallet_address,
            network
        )
        return balance_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/blockchain/eth-balance", tags=["blockchain"])
async def get_eth_balance_endpoint(
    current_user: User = Depends(get_current_active_user)
):
    """Get ETH balance"""
    try:
        balance = get_eth_balance(current_user.wallet_address)
        return {"balance": balance}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Health check endpoint
@app.get("/health", tags=["system"])
async def health_check():
    return {"status": "healthy"}

# Root endpoint
@app.get("/", tags=["system"])
async def root():
    return {
        "message": "Welcome to ChainFinity API",
        "docs_url": "/docs",
        "redoc_url": "/redoc"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
