"""
Base Pydantic schemas and common types
"""

from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field, validator


class BaseSchema(BaseModel):
    """Base schema with common configuration"""

    class Config:
        orm_mode = True
        use_enum_values = True
        validate_assignment = True
        arbitrary_types_allowed = True
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            Decimal: lambda v: str(v),
            UUID: lambda v: str(v),
        }


class TimestampSchema(BaseSchema):
    """Schema with timestamp fields"""

    created_at: datetime
    updated_at: datetime


class PaginationParams(BaseModel):
    """Pagination parameters"""

    page: int = Field(default=1, ge=1, description="Page number")
    size: int = Field(default=20, ge=1, le=100, description="Page size")

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.size


class PaginatedResponse(BaseModel):
    """Paginated response wrapper"""

    items: List[Any]
    total: int
    page: int
    size: int
    pages: int

    @validator("pages", always=True)
    def calculate_pages(cls, v, values):
        total = values.get("total", 0)
        size = values.get("size", 20)
        return (total + size - 1) // size if total > 0 else 0


class FilterParams(BaseModel):
    """Base filter parameters"""

    search: Optional[str] = Field(None, description="Search term")
    sort_by: Optional[str] = Field(None, description="Sort field")
    sort_order: Optional[str] = Field(
        "asc", regex="^(asc|desc)$", description="Sort order"
    )

    @validator("search")
    def validate_search(cls, v):
        if v is not None and len(v.strip()) < 2:
            raise ValueError("Search term must be at least 2 characters")
        return v.strip() if v else None


class DateRangeFilter(BaseModel):
    """Date range filter"""

    start_date: Optional[datetime] = Field(None, description="Start date")
    end_date: Optional[datetime] = Field(None, description="End date")

    @validator("end_date")
    def validate_date_range(cls, v, values):
        start_date = values.get("start_date")
        if start_date and v and v < start_date:
            raise ValueError("End date must be after start date")
        return v


class SuccessResponse(BaseModel):
    """Standard success response"""

    success: bool = True
    message: str
    data: Optional[Dict[str, Any]] = None


class ErrorResponse(BaseModel):
    """Standard error response"""

    success: bool = False
    error: str
    details: Optional[Dict[str, Any]] = None
    code: Optional[str] = None


class HealthCheckResponse(BaseModel):
    """Health check response"""

    status: str
    timestamp: datetime
    version: str
    services: Dict[str, str]
    uptime_seconds: int


class MetricsResponse(BaseModel):
    """Metrics response"""

    metric_name: str
    value: float
    unit: Optional[str] = None
    timestamp: datetime
    labels: Optional[Dict[str, str]] = None


class ValidationError(BaseModel):
    """Validation error details"""

    field: str
    message: str
    value: Any


class BulkOperationResponse(BaseModel):
    """Bulk operation response"""

    total_items: int
    successful_items: int
    failed_items: int
    errors: List[ValidationError] = []
    results: List[Dict[str, Any]] = []
