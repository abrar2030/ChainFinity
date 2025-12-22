"""
Risk management Pydantic schemas
"""

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from schemas.base import BaseSchema


class RiskAssessmentResponse(BaseSchema):
    """Risk assessment response schema"""

    id: UUID
    risk_score: Decimal
    risk_level: str
    assessment_date: datetime
    created_at: datetime


class RiskMetricsResponse(BaseSchema):
    """Risk metrics response schema"""

    id: UUID
    metric_type: str
    value: Decimal
    created_at: datetime


class AlertResponse(BaseSchema):
    """Risk alert response schema"""

    id: UUID
    alert_type: str
    severity: str
    message: str
    is_active: bool
    created_at: datetime
