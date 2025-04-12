from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
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
from schemas import UserCreate, UserResponse, Token, TokenData
from services.auth import (
    verify_password,
    get_password_hash,
    create_access_token,
    get_current_user,
)
from services.blockchain import get_web3_provider

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

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

@app.post("/auth/register", response_model=UserResponse)
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

@app.post("/auth/login", response_model=Token)
async def login(email: str, password: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user

@app.get("/transactions/{wallet_address}")
async def get_transactions(
    wallet_address: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.wallet_address != wallet_address:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this wallet"
        )
    
    # Get transactions from blockchain
    w3 = get_web3_provider()
    try:
        # TODO: Implement actual transaction fetching from blockchain
        # This is a mock implementation
        transactions = [
            {
                "hash": "0x123...",
                "from": wallet_address,
                "to": "0x456...",
                "value": "1.0",
                "timestamp": datetime.now().timestamp()
            }
        ]
        return transactions
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@app.get("/portfolio/{wallet_address}")
async def get_portfolio(
    wallet_address: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.wallet_address != wallet_address:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this wallet"
        )
    
    # Get portfolio data from blockchain
    w3 = get_web3_provider()
    try:
        # TODO: Implement actual portfolio data fetching
        # This is a mock implementation
        portfolio = {
            "total_value": "1000.00",
            "assets": [
                {"symbol": "ETH", "amount": "1.5", "value": "3000.00"},
                {"symbol": "BTC", "amount": "0.1", "value": "4000.00"}
            ]
        }
        return portfolio
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
