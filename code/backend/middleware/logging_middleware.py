"""
Logging middleware for request/response logging
"""

import json
import logging
import time
from typing import Any, Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)


class LoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware for comprehensive request and response logging
    """

    def __init__(self, app: Any) -> None:
        super().__init__(app)
        self.skip_paths = ["/health", "/metrics"]

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Log request and response details
        """
        # Skip logging for health check and metrics endpoints
        if request.url.path in self.skip_paths:
            return await call_next(request)

        # Start timing
        start_time = time.time()

        # Get request details
        client_ip = self._get_client_ip(request)

        # Log request
        logger.info(f"Request: {request.method} {request.url.path} from {client_ip}")

        # Process request
        try:
            response = await call_next(request)
        except Exception as e:
            logger.error(f"Request processing error: {e}", exc_info=True)
            raise

        # Calculate processing time
        processing_time = time.time() - start_time

        # Log response
        log_data = {
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "processing_time": f"{processing_time:.3f}s",
            "client_ip": client_ip,
        }

        if response.status_code >= 400:
            logger.warning(f"Response: {json.dumps(log_data)}")
        else:
            logger.info(f"Response: {json.dumps(log_data)}")

        # Add custom headers
        response.headers["X-Process-Time"] = str(processing_time)

        return response

    def _get_client_ip(self, request: Request) -> str:
        """
        Extract client IP address from request
        """
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()

        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip

        return request.client.host if request.client else "unknown"
