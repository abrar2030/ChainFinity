from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    wallet_address: str

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class TransactionBase(BaseModel):
    tx_hash: str
    from_address: str
    to_address: str
    value: str
    timestamp: datetime

class TransactionCreate(TransactionBase):
    pass

class Transaction(TransactionBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        orm_mode = True

class Asset(BaseModel):
    symbol: str
    balance: float
    value_usd: float

class Portfolio(BaseModel):
    total_value: float
    assets: List[Asset]
    recent_transactions: Optional[List[Transaction]] = []
