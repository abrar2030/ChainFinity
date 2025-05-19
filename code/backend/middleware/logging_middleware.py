from fastapi import Request, Response
from typing import Callable
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LoggingMiddleware:
    """
    Middleware for logging request information and timing
    """
    async def __call__(self, request: Request, call_next: Callable) -> Response:
        start_time = time.time()
        
        # Log request details
        logger.info(f"Request started: {request.method} {request.url.path}")
        
        # Process the request
        response = await call_next(request)
        
        # Calculate processing time
        process_time = time.time() - start_time
        
        # Log response details
        logger.info(f"Request completed: {request.method} {request.url.path} - Status: {response.status_code} - Time: {process_time:.4f}s")
        
        # Add custom header with processing time
        response.headers["X-Process-Time"] = str(process_time)
        
        return response
