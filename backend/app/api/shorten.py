import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.schemas.url import URLCreate, URLResponse
from app.services import cache_service, url_service

logger = logging.getLogger(__name__)
settings = get_settings()

router = APIRouter(prefix="/api/v1", tags=["shorten"])


@router.post(
    "/shorten", response_model=URLResponse, status_code=status.HTTP_201_CREATED
)
def shorten_url(payload: URLCreate, db: Session = Depends(get_db)) -> URLResponse:
    """
    Create a short URL from *payload.url*.

    An optional *custom_alias* can be provided.  If the alias is already taken
    a **409 Conflict** is returned.
    """
    original_url = str(payload.url)
    custom_alias = payload.custom_alias

    # Validate custom alias uniqueness
    if custom_alias:
        existing = url_service.get_url_by_code(db, custom_alias)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Alias '{custom_alias}' is already in use.",
            )

    url_obj = url_service.create_short_url(db, original_url, custom_alias=custom_alias)

    # Pre-warm the cache for the new URL
    cache_service.cache_url(url_obj.short_code, url_obj.original_url)

    short_url = f"{settings.BASE_URL}/{url_obj.short_code}"

    return URLResponse(
        short_code=url_obj.short_code,
        short_url=short_url,
        original_url=url_obj.original_url,
        click_count=url_obj.click_count,
        created_at=url_obj.created_at,
        is_active=url_obj.is_active,
    )
