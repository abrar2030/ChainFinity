"""
User-related Pydantic schemas
"""

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field
from schemas.base import BaseSchema


class UserCreate(BaseModel):
    """User creation schema"""

    email: EmailStr
    password: str = Field(..., min_length=8)
    wallet_address: Optional[str] = None


class UserUpdate(BaseModel):
    """User update schema"""

    email: Optional[EmailStr] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None


class UserResponse(BaseSchema):
    """User response schema"""

    id: UUID
    email: str
    is_active: bool
    is_verified: bool
    created_at: datetime


class UserProfile(BaseSchema):
    """User profile schema"""

    id: UUID
    email: str
    first_name: Optional[str]
    last_name: Optional[str]
    wallet_address: Optional[str]
    created_at: datetime


class UserKYC(BaseModel):
    """User KYC submission schema"""

    document_type: str
    document_number: str
    country: str


class UserRiskProfile(BaseSchema):
    """User risk profile schema"""

    id: UUID
    risk_tolerance: str
    investment_goals: Optional[List[str]]
    created_at: datetime
