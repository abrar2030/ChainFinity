"""
API dependencies for authentication and common functionality
"""

import logging
from typing import Dict, Optional
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from config.database import get_async_session
from services.auth import AuthService
from models.user import User

logger = logging.getLogger(__name__)

# Security scheme
security = HTTPBearer()
auth_service = AuthService()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_async_session)
) -> User:
    """
    Get current authenticated user
    """
    try:
        token = credentials.credentials
        user = await auth_service.verify_current_user(db, token)
        return user
    except Exception as e:
        logger.error(f"Authentication error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Get current active user (additional check for user status)
    """
    if not current_user.is_active():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    return current_user


def get_client_info(request: Request) -> Dict[str, str]:
    """
    Extract client information from request
    """
    # Get IP address considering proxies
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        ip_address = forwarded_for.split(",")[0].strip()
    else:
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            ip_address = real_ip
        else:
            ip_address = request.client.host if request.client else "unknown"
    
    # Get user agent
    user_agent = request.headers.get("User-Agent", "unknown")
    
    return {
        "ip_address": ip_address,
        "user_agent": user_agent
    }


class PermissionChecker:
    """
    Permission checker for role-based access control
    """
    
    def __init__(self, required_permissions: list):
        self.required_permissions = required_permissions
    
    def __call__(self, current_user: User = Depends(get_current_active_user)) -> User:
        """
        Check if user has required permissions
        """
        # For now, we'll implement basic permission checking
        # In a full implementation, you would check user roles and permissions
        
        # Admin users have all permissions
        if hasattr(current_user, 'is_admin') and current_user.is_admin:
            return current_user
        
        # Check specific permissions based on user role or attributes
        # This is a simplified implementation
        for permission in self.required_permissions:
            if not self._user_has_permission(current_user, permission):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Permission denied: {permission} required"
                )
        
        return current_user
    
    def _user_has_permission(self, user: User, permission: str) -> bool:
        """
        Check if user has specific permission
        """
        # Implement permission logic based on your requirements
        # This could check user roles, groups, or specific permissions
        
        # Basic permissions based on user status
        basic_permissions = [
            "read_own_data",
            "update_own_profile",
            "view_own_transactions",
            "manage_own_portfolio"
        ]
        
        if permission in basic_permissions:
            return user.is_active()
        
        # Admin permissions
        admin_permissions = [
            "read_all_users",
            "manage_compliance",
            "view_audit_logs",
            "manage_risk_settings"
        ]
        
        if permission in admin_permissions:
            return hasattr(user, 'is_admin') and user.is_admin
        
        return False


# Common permission dependencies
require_admin = PermissionChecker(["admin_access"])
require_compliance_access = PermissionChecker(["manage_compliance"])
require_risk_access = PermissionChecker(["manage_risk_settings"])

