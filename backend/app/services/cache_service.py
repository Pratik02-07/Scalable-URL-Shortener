from typing import Optional
import redis
from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)

settings = get_settings()

_redis_client: Optional[redis.Redis] = None

# Default TTL for cached URLs: 24 hours
DEFAULT_TTL_SECONDS = 86_400


def get_redis() -> redis.Redis:
    """Return a lazily-created, module-level Redis client."""
    global _redis_client
    if _redis_client is None:
        _redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)
    return _redis_client


def cache_url(short_code: str, original_url: str, ttl: int = DEFAULT_TTL_SECONDS) -> None:
    """Store *original_url* in Redis keyed by *short_code*."""
    try:
        get_redis().set(short_code, original_url, ex=ttl)
        logger.info("Cache SET", event="cache_set", short_code=short_code)
    except redis.RedisError as exc:
        # Treat Redis as a non-critical dependency — log and continue
        logger.warning("Cache SET failed", event="cache_error", short_code=short_code, error=str(exc))


def get_cached_url(short_code: str) -> Optional[str]:
    """
    Return the cached original URL for *short_code*, or None on miss / error.

    Logs whether the result was a cache HIT or MISS.
    """
    try:
        value = get_redis().get(short_code)
        if value:
            logger.info("Cache HIT", event="cache_hit", short_code=short_code)
        else:
            logger.info("Cache MISS", event="cache_miss", short_code=short_code)
        return value
    except redis.RedisError as exc:
        logger.warning("Cache GET failed", event="cache_error", short_code=short_code, error=str(exc))
        return None


def invalidate_cache(short_code: str) -> None:
    """Remove the cached entry for *short_code* (e.g. on deactivation)."""
    try:
        get_redis().delete(short_code)
        logger.info("Cache DEL", event="cache_del", short_code=short_code)
    except redis.RedisError as exc:
        logger.warning("Cache DEL failed", event="cache_error", short_code=short_code, error=str(exc))
