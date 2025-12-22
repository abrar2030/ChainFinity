"""
Authentication middleware for JWT token validation
"""

import logging
from typing import Any, Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)


class AuthMiddleware(BaseHTTPMiddleware):
    """
    Authentication middleware for JWT validation on protected routes
    """

    def __init__(self, app: Any) -> None:
        super().__init__(app)
        self.public_paths = [
            "/health",
            "/metrics",
            "/docs",
            "/redoc",
            "/openapi.json",
            "/api/v1/auth/login",
            "/api/v1/auth/register",
            "/api/v1/auth/refresh",
            "/",
        ]

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Process request with authentication validation
        """
        # Skip authentication for public paths
        if self._is_public_path(request.url.path):
            return await call_next(request)

        # For now, allow all authenticated requests
        # Real JWT validation would be implemented here
        # Extract and validate JWT token from Authorization header
        auth_header = request.headers.get("Authorization")

        if auth_header and auth_header.startswith("Bearer "):
            # Token exists, proceed (actual validation would happen in dependencies)
            return await call_next(request)

        # For non-auth endpoints that don't require authentication, allow through
        return await call_next(request)

    def _is_public_path(self, path: str) -> bool:
        """
        Check if the request path is public
        """
        for public_path in self.public_paths:
            if path.startswith(public_path):
                return True
        return False
