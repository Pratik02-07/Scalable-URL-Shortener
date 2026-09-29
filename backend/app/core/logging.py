"""
Structured JSON logger for the URL Shortener service.

Produces log lines that CloudWatch Logs Insights can parse directly:
  { "timestamp": "...", "level": "INFO", "logger": "...",
    "message": "...", "event": "cache_hit", "short_code": "aB91xK" }

Usage:
    from app.core.logging import get_logger
    logger = get_logger(__name__)
    logger.info("cache_hit", short_code=code)
"""

from __future__ import annotations

import json
import logging
import sys
from typing import Any


class _JSONFormatter(logging.Formatter):
    """Emit each log record as a single JSON object on one line."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        # Attach any extra keyword args passed to logger.info("msg", extra={...})
        for key, val in record.__dict__.items():
            if key not in (
                "name",
                "msg",
                "args",
                "created",
                "filename",
                "funcName",
                "levelname",
                "levelno",
                "lineno",
                "module",
                "msecs",
                "message",
                "pathname",
                "process",
                "processName",
                "relativeCreated",
                "stack_info",
                "thread",
                "threadName",
                "exc_info",
                "exc_text",
                "taskName",
            ):
                payload[key] = val

        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)

        return json.dumps(payload, default=str)


class _StructuredAdapter(logging.LoggerAdapter):
    """
    Wraps a standard Logger so callers can pass keyword args directly:

        logger.info("redirect", short_code="aB91xK", latency_ms=3.2)

    instead of the verbose:

        logger.info("redirect", extra={"short_code": "aB91xK", ...})
    """

    def process(self, msg: str, kwargs: dict[str, Any]) -> tuple[str, dict[str, Any]]:
        extra = kwargs.pop("extra", {})
        extra.update(
            {k: v for k, v in kwargs.items() if k not in ("exc_info", "stack_info")}
        )
        # Remove non-logging kwargs so the base Logger doesn't complain
        for k in list(kwargs):
            if k not in ("exc_info", "stack_info"):
                del kwargs[k]
        kwargs["extra"] = extra
        return msg, kwargs


def configure_logging(json_logs: bool = True, level: str = "INFO") -> None:
    """
    Call once at application startup.

    Args:
        json_logs: Emit JSON (True in production / ECS) or plain text (False locally).
        level:     Root log level string, e.g. "INFO", "DEBUG".
    """
    root = logging.getLogger()
    root.setLevel(getattr(logging, level.upper(), logging.INFO))

    # Remove any handlers added by basicConfig / uvicorn
    root.handlers.clear()

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(
        _JSONFormatter()
        if json_logs
        else logging.Formatter(
            "%(asctime)s %(levelname)-8s %(name)s  %(message)s",
            datefmt="%H:%M:%S",
        )
    )
    root.addHandler(handler)

    # Silence noisy third-party loggers
    for name in ("uvicorn.access", "sqlalchemy.engine", "sqlalchemy.pool"):
        logging.getLogger(name).setLevel(logging.WARNING)


def get_logger(name: str) -> _StructuredAdapter:
    """Return a structured logger for *name*."""
    return _StructuredAdapter(logging.getLogger(name), {})
