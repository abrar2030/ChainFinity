"""
Security middleware for enhanced request security
"""

import logging
from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
import time

logger = logging.getLogger(__name__)


class SecurityMiddleware(BaseHTTPMiddleware):
    """
    Security middleware for adding security headers and basic protection
    """
    
    def __init__(self, app):
        super().__init__(app)
        self.security_headers = {
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "DENY",
            "X-XSS-Protection": "1; mode=block",
            "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
            "Referrer-Policy": "strict-origin-when-cross-origin",
            "Content-Security-Policy": "default-src 'self'",
            "Permissions-Policy": "geolocation=(), microphone=(), camera=()"
        }
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Process request with security enhancements
        """
        start_time = time.time()
        
        # Check for suspicious patterns
        if self._is_suspicious_request(request):
            logger.warning(f"Suspicious request detected: {request.url}")
            return JSONResponse(
                status_code=403,
                content={"error": "Request blocked for security reasons"}
            )
        
        # Process request
        response = await call_next(request)
        
        # Add security headers
        for header, value in self.security_headers.items():
            response.headers[header] = value
        
        # Add processing time header
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = str(process_time)
        
        return response
    
    def _is_suspicious_request(self, request: Request) -> bool:
        """
        Check for suspicious request patterns
        """
        # Check for common attack patterns in URL
        suspicious_patterns = [
            "../", "..\\", "<script", "javascript:", "vbscript:",
            "onload=", "onerror=", "eval(", "alert(", "document.cookie",
            "union select", "drop table", "insert into", "delete from"
        ]
        
        url_str = str(request.url).lower()
        for pattern in suspicious_patterns:
            if pattern in url_str:
                return True
        
        # Check User-Agent for suspicious patterns
        user_agent = request.headers.get("user-agent", "").lower()
        suspicious_agents = [
            "sqlmap", "nikto", "nmap", "masscan", "nessus",
            "burp", "zap", "w3af", "acunetix"
        ]
        
        for agent in suspicious_agents:
            if agent in user_agent:
                return True
        
        # Check for excessive header count
        if len(request.headers) > 50:
            return True
        
        # Check for suspicious header values
        for header_name, header_value in request.headers.items():
            if len(header_value) > 8192:  # Unusually long header value
                return True
        
        return False

