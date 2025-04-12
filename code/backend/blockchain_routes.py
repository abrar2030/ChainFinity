from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models import User, Transaction
from schemas import Transaction as TransactionSchema, Portfolio
from auth import get_current_active_user
from blockchain import (
    get_eth_balance,
    get_token_balance,
    get_transactions,
    get_portfolio_value
)

router = APIRouter()

@router.get("/portfolio", response_model=Portfolio)
async def get_portfolio(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user's portfolio value and assets"""
    try:
        portfolio_data = get_portfolio_value(current_user.wallet_address)
        
        # Get recent transactions from database
        recent_transactions = db.query(Transaction).filter(
            Transaction.user_id == current_user.id
        ).order_by(Transaction.timestamp.desc()).limit(10).all()
        
        portfolio_data["recent_transactions"] = recent_transactions
        return portfolio_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/transactions", response_model=List[TransactionSchema])
async def get_user_transactions(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user's transaction history"""
    try:
        # Get transactions from database
        transactions = db.query(Transaction).filter(
            Transaction.user_id == current_user.id
        ).order_by(Transaction.timestamp.desc()).all()
        
        return transactions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/balance/{token_address}")
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

@router.get("/eth-balance")
async def get_eth_balance_endpoint(
    current_user: User = Depends(get_current_active_user)
):
    """Get ETH balance"""
    try:
        balance = get_eth_balance(current_user.wallet_address)
        return {"balance": balance}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 