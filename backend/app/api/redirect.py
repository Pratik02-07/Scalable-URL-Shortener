import logging

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.url import URLStatsResponse
from app.services import cache_service, url_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["redirect"])


@router.get("/{short_code}", response_class=RedirectResponse)
def redirect_to_url(short_code: str, db: Session = Depends(get_db)) -> RedirectResponse:
    """
    Redirect the client to the original URL for *short_code*.

    Resolution order:
    1. Redis cache (HIT → redirect immediately)
    2. PostgreSQL  (MISS → cache the result → redirect)
    """
    # 1. Try cache first
    original_url = cache_service.get_cached_url(short_code)

    if original_url is None:
        # 2. Fall back to the database
        url_obj = url_service.get_url_by_code(db, short_code)
        if url_obj is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Short code '{short_code}' not found.",
            )
        original_url = url_obj.original_url
        # Populate cache for subsequent requests
        cache_service.cache_url(short_code, original_url)

    # Record the click asynchronously-ish (still synchronous here; can be
    # moved to a background task later without changing the interface)
    url_service.increment_click_count(db, short_code)
    logger.info("Redirect: short_code=%s → %s", short_code, original_url)

    return RedirectResponse(url=original_url, status_code=status.HTTP_302_FOUND)


@router.get("/api/v1/stats/{short_code}", response_model=URLStatsResponse)
def get_stats(short_code: str, db: Session = Depends(get_db)) -> URLStatsResponse:
    """Return click statistics for *short_code* without redirecting."""
    url_obj = url_service.get_url_by_code(db, short_code)
    if url_obj is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Short code '{short_code}' not found.",
        )
    return URLStatsResponse(
        short_code=url_obj.short_code,
        original_url=url_obj.original_url,
        click_count=url_obj.click_count,
        created_at=url_obj.created_at,
        is_active=url_obj.is_active,
    )
