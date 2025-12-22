"""
Compliance-related Pydantic schemas
"""

from datetime import datetime
from uuid import UUID

from schemas.base import BaseSchema


class ComplianceCheckResponse(BaseSchema):
    """Compliance check response schema"""

    id: UUID
    check_type: str
    status: str
    created_at: datetime


class AuditLogResponse(BaseSchema):
    """Audit log response schema"""

    id: UUID
    event_type: str
    entity_type: str
    entity_id: str
    created_at: datetime


class RegulatoryReportResponse(BaseSchema):
    """Regulatory report response schema"""

    id: UUID
    report_type: str
    status: str
    created_at: datetime
