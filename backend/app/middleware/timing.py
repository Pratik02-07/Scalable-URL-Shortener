"""
Request timing middleware.

Emits one structured log line per request with:
  - method, path, status_code, duration_ms
  - A CloudWatch metric filter can extract duration_ms for latency dashboards.

Example log line (JSON mode):
  {"timestamp":"...","level":"INFO","logger":"app.middleware.timing",
   "message":"request","method":"GET","path":"/health",
   "status_code":200,"duration_ms":0.45}
"""

from __future__ import annotations

import time

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from app.core.logging import get_logger

logger = get_logger(__name__)

# Paths to skip (high-volume ops probes clutter dashboards)
_SKIP_PATHS = {"/health", "/ready", "/favicon.ico"}


class RequestTimingMiddleware(BaseHTTPMiddleware):
    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        if request.url.path in _SKIP_PATHS:
            return await call_next(request)

        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = round((time.perf_counter() - start) * 1000, 2)

        logger.info(
            "request",
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=duration_ms,
        )

        # Surface latency as a response header (useful during load testing)
        response.headers["X-Response-Time-Ms"] = str(duration_ms)
        return response
