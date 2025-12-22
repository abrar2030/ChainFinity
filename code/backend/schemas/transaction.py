"""
Transaction-related Pydantic schemas
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel
from schemas.base import BaseSchema


class TransactionCreate(BaseModel):
    """Transaction creation schema"""

    transaction_type: str
    amount: Decimal
    asset_symbol: str
    wallet_address: str


class TransactionUpdate(BaseModel):
    """Transaction update schema"""

    status: Optional[str] = None
    notes: Optional[str] = None


class TransactionResponse(BaseSchema):
    """Transaction response schema"""

    id: UUID
    transaction_type: str
    amount: Decimal
    asset_symbol: str
    status: str
    created_at: datetime


class TransactionFilter(BaseModel):
    """Transaction filter schema"""

    transaction_type: Optional[str] = None
    asset_symbol: Optional[str] = None
    status: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
