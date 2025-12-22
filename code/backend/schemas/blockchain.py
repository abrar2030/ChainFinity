"""
Blockchain-related Pydantic schemas
"""

from datetime import datetime
from uuid import UUID

from schemas.base import BaseSchema


class NetworkResponse(BaseSchema):
    """Blockchain network response schema"""

    id: UUID
    name: str
    display_name: str
    chain_id: int
    is_active: bool
    created_at: datetime


class ContractResponse(BaseSchema):
    """Smart contract response schema"""

    id: UUID
    name: str
    address: str
    contract_type: str
    is_active: bool
    created_at: datetime


class EventResponse(BaseSchema):
    """Contract event response schema"""

    id: UUID
    event_type: str
    transaction_hash: str
    block_number: int
    created_at: datetime
