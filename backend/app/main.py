import logging
import logging.config
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.logging import configure_logging, get_logger
from app.middleware.timing import RequestTimingMiddleware
from app.db.base import Base
from app.db.session import engine
from app.api import shorten, redirect

settings = get_settings()

# ---------------------------------------------------------------------------
# Logging Configuration
# ---------------------------------------------------------------------------
configure_logging(json_logs=settings.LOG_JSON, level="INFO")
logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Lifespan (replaces deprecated on_event)
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):  # type: ignore[type-arg]
    # Startup: ensure tables exist (idempotent in dev; migrations handle prod)
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables verified / created.")
    yield
    # Shutdown: nothing to clean up at the moment
    logger.info("Application shutting down.")


# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------
app = FastAPI(
    title=settings.APP_NAME,
    description="A scalable URL-shortening service built with FastAPI.",
    version="1.0.0",
    lifespan=lifespan,
)

# Request Timing Middleware (latency tracking & response header X-Response-Time-Ms)
app.add_middleware(RequestTimingMiddleware)

# CORS — allow the Next.js frontend and any local dev origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten in production via env var
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Health / readiness endpoints (used by ECS / ALB health checks)
# IMPORTANT: registered BEFORE the /{short_code} wildcard router so they
# are not accidentally captured by the redirect route.
# ---------------------------------------------------------------------------
@app.get("/", tags=["ops"])
def root() -> dict:
    """Root endpoint — returns basic API status and documentation link."""
    return {
        "name": settings.APP_NAME,
        "status": "online",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health", tags=["ops"])
def health() -> dict:
    """Liveness probe — always returns 200 if the process is running."""
    return {"status": "ok"}


@app.get("/ready", tags=["ops"])
def ready() -> dict:
    """
    Readiness probe — verifies the database is reachable.

    ALB marks the task unhealthy if this returns a non-2xx status.
    """
    from sqlalchemy import text
    from app.db.session import SessionLocal

    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1"))
        return {"status": "ready"}
    except Exception as exc:  # noqa: BLE001
        logger.error("Readiness check failed: %s", exc)
        from fastapi import Response

        return Response(content='{"status":"unavailable"}', status_code=503)


# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------
app.include_router(shorten.router)
app.include_router(redirect.router)
