import pytest
from unittest.mock import patch, MagicMock
import redis
from app.services.cache_service import (
    cache_url,
    get_cached_url,
    invalidate_cache,
    get_redis,
)

def test_get_redis_singleton():
    with patch("app.services.cache_service._redis_client", None), \
         patch("redis.from_url") as mock_from_url:
        client1 = get_redis()
        client2 = get_redis()
        assert client1 == client2
        mock_from_url.assert_called_once()

def test_cache_url_success():
    mock_client = MagicMock()
    with patch("app.services.cache_service._redis_client", mock_client):
        cache_url("code123", "https://example.com/target", ttl=3600)
        mock_client.set.assert_called_once_with("code123", "https://example.com/target", ex=3600)

def test_cache_url_handles_redis_error():
    mock_client = MagicMock()
    mock_client.set.side_effect = redis.RedisError("Connection failed")
    with patch("app.services.cache_service._redis_client", mock_client):
        cache_url("code123", "https://example.com/target")

def test_get_cached_url_hit():
    mock_client = MagicMock()
    mock_client.get.return_value = "https://example.com/hit"
    with patch("app.services.cache_service._redis_client", mock_client):
        result = get_cached_url("code123")
        assert result == "https://example.com/hit"
        mock_client.get.assert_called_once_with("code123")

def test_get_cached_url_miss():
    mock_client = MagicMock()
    mock_client.get.return_value = None
    with patch("app.services.cache_service._redis_client", mock_client):
        result = get_cached_url("missing123")
        assert result is None

def test_get_cached_url_handles_redis_error():
    mock_client = MagicMock()
    mock_client.get.side_effect = redis.RedisError("Redis timeout")
    with patch("app.services.cache_service._redis_client", mock_client):
        result = get_cached_url("code123")
        assert result is None

def test_invalidate_cache_success():
    mock_client = MagicMock()
    with patch("app.services.cache_service._redis_client", mock_client):
        invalidate_cache("code123")
        mock_client.delete.assert_called_once_with("code123")

def test_invalidate_cache_handles_redis_error():
    mock_client = MagicMock()
    mock_client.delete.side_effect = redis.RedisError("Redis failure")
    with patch("app.services.cache_service._redis_client", mock_client):
        invalidate_cache("code123")
