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
from services.blockchain import (
    get_web3_provider,
    get_transactions,
    get_portfolio_value,
    get_eth_balance,
    get_token_balance
)

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
async def get_wallet_transactions(
    wallet_address: str,
    network: str = "ethereum",
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.wallet_address != wallet_address:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this wallet"
        )
    
    # Get transactions from blockchain
    try:
        # Actual implementation of transaction fetching from blockchain
        w3 = get_web3_provider(network)
        
        # Get the latest block number
        latest_block = w3.eth.block_number
        
        # Initialize transactions list
        transactions = []
        
        # Fetch the most recent transactions
        for i in range(limit):
            if latest_block - i < 0:
                break
                
            block = w3.eth.get_block(latest_block - i, full_transactions=True)
            
            for tx in block.transactions:
                # Check if transaction involves the wallet address
                if tx['from'].lower() == wallet_address.lower() or tx['to'] and tx['to'].lower() == wallet_address.lower():
                    # Format transaction data
                    transaction = {
                        "hash": tx['hash'].hex(),
                        "from": tx['from'],
                        "to": tx['to'],
                        "value": w3.from_wei(tx['value'], 'ether'),
                        "gas": tx['gas'],
                        "gas_price": w3.from_wei(tx['gasPrice'], 'gwei'),
                        "block_number": tx['blockNumber'],
                        "timestamp": block.timestamp,
                        "network": network
                    }
                    
                    transactions.append(transaction)
                    
                    # Break if we've reached the limit
                    if len(transactions) >= limit:
                        break
            
            # Break if we've reached the limit
            if len(transactions) >= limit:
                break
        
        # Store transactions in database for future reference
        for tx in transactions:
            db_tx = Transaction(
                tx_hash=tx['hash'],
                from_address=tx['from'],
                to_address=tx['to'],
                value=float(tx['value']),
                timestamp=datetime.fromtimestamp(tx['timestamp']),
                user_id=current_user.id
            )
            db.add(db_tx)
        
        db.commit()
        
        return transactions
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching transactions: {str(e)}"
        )

@app.get("/portfolio/{wallet_address}")
async def get_wallet_portfolio(
    wallet_address: str,
    network: str = "ethereum",
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.wallet_address != wallet_address:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this wallet"
        )
    
    try:
        # Actual implementation of portfolio data fetching
        w3 = get_web3_provider(network)
        
        # Get ETH balance
        eth_balance = get_eth_balance(wallet_address)
        
        # Get current ETH price (in a real implementation, this would come from a price oracle)
        # For this implementation, we'll use a hardcoded price
        eth_price = 3000.00  # Example price in USD
        
        # Common ERC20 tokens to check (in a real implementation, this would be more comprehensive)
        tokens = [
            {"address": "0xdAC17F958D2ee523a2206206994597C13D831ec7", "symbol": "USDT", "price": 1.0},  # Tether
            {"address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "symbol": "USDC", "price": 1.0},  # USD Coin
            {"address": "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", "symbol": "WBTC", "price": 40000.0},  # Wrapped BTC
            {"address": "0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0", "symbol": "MATIC", "price": 1.5},  # Polygon
            {"address": "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", "symbol": "UNI", "price": 20.0},  # Uniswap
        ]
        
        # Initialize portfolio
        portfolio = {
            "total_value_usd": eth_balance * eth_price,
            "assets": [
                {
                    "symbol": "ETH",
                    "amount": eth_balance,
                    "value_usd": eth_balance * eth_price,
                    "price_usd": eth_price
                }
            ]
        }
        
        # Check token balances
        for token in tokens:
            try:
                token_data = get_token_balance(token["address"], wallet_address, network)
                
                if token_data["balance"] > 0:
                    token_value_usd = token_data["balance"] * token["price"]
                    portfolio["total_value_usd"] += token_value_usd
                    
                    portfolio["assets"].append({
                        "symbol": token_data["symbol"],
                        "amount": token_data["balance"],
                        "value_usd": token_value_usd,
                        "price_usd": token["price"],
                        "token_address": token["address"]
                    })
            except Exception as token_error:
                print(f"Error fetching token {token['symbol']}: {token_error}")
                continue
        
        # Sort assets by value (highest first)
        portfolio["assets"] = sorted(portfolio["assets"], key=lambda x: x["value_usd"], reverse=True)
        
        # Format values for better readability
        portfolio["total_value_usd"] = round(portfolio["total_value_usd"], 2)
        for asset in portfolio["assets"]:
            asset["value_usd"] = round(asset["value_usd"], 2)
            asset["amount"] = round(asset["amount"], 6)
        
        return portfolio
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching portfolio: {str(e)}"
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
