"""
Audit logging middleware and utility functions
"""

import logging
from datetime import datetime
from typing import Optional

from models.compliance import AuditLog
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)


async def audit_log(
    db: AsyncSession,
    user_id: str,
    event_type: str,
    entity_type: str,
    entity_id: str,
    changes: Optional[dict] = None,
    ip_address: Optional[str] = None,
) -> None:
    """
    Create an audit log entry
    """
    try:
        log_entry = AuditLog(
            user_id=user_id,
            event_type=event_type,
            entity_type=entity_type,
            entity_id=entity_id,
            changes_made=changes,
            ip_address=ip_address,
            timestamp=datetime.utcnow(),
        )
        db.add(log_entry)
        await db.commit()
        logger.info(f"Audit log created: {event_type} for {entity_type}:{entity_id}")
    except Exception as e:
        logger.error(f"Failed to create audit log: {e}")
        # Don't fail the request if audit logging fails
