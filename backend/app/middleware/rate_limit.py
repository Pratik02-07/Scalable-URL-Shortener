import logging
from fastapi import Request, HTTPException, status
from app.core.config import get_settings
from app.services.cache_service import get_redis
import redis

logger = logging.getLogger(__name__)
settings = get_settings()

def get_client_ip(request: Request) -> str:
    """Extract client IP handling proxy / ALB X-Forwarded-For header."""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return "127.0.0.1"

def rate_limit(
    max_requests: int | None = None,
    window_seconds: int | None = None,
):
    """
    FastAPI dependency factory enforcing a sliding/fixed window rate limit per client IP.
    Fails open gracefully if Redis is temporarily unreachable.
    """
    limit = max_requests or settings.RATE_LIMIT_REQUESTS
    window = window_seconds or settings.RATE_LIMIT_WINDOW_SECONDS

    def dependency(request: Request):
        client_ip = get_client_ip(request)
        rate_key = f"ratelimit:{request.url.path}:{client_ip}"

        try:
            r = get_redis()
            current = r.get(rate_key)
            if current and int(current) >= limit:
                logger.warning(
                    "Rate limit exceeded for IP %s on %s (current: %s, limit: %s)",
                    client_ip,
                    request.url.path,
                    current,
                    limit,
                )
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=f"Rate limit exceeded. Maximum {limit} requests per {window} seconds.",
                    headers={"Retry-After": str(window)},
                )

            pipe = r.pipeline()
            pipe.incr(rate_key)
            if not current:
                pipe.expire(rate_key, window)
            pipe.execute()

        except HTTPException:
            raise
        except redis.RedisError as exc:
            # Treat Redis rate-limiting as non-critical: log and allow request
            logger.warning("Rate limit check failed due to Redis error: %s", exc)
        except Exception as exc:
            logger.warning("Unexpected error during rate limit check: %s", exc)

    return dependency
