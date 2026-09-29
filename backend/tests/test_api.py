"""
Integration tests for the FastAPI endpoints.

Uses httpx.TestClient (sync) with an in-memory SQLite database and Redis
mocked out so no external services are needed.
"""

from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.db.session import get_db
from app.main import app

# ── In-memory SQLite for tests ───────────────────────────────────────────────
TEST_DB_URL = "sqlite:///:memory:"

engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


# ── Mock Redis so tests don't need a running Redis instance ──────────────────
@pytest.fixture(autouse=True)
def mock_redis():
    mock_client = MagicMock()
    mock_client.get.return_value = None  # always cache MISS → fall through to DB
    mock_client.set.return_value = True
    mock_client.delete.return_value = 1
    with patch("app.services.cache_service._redis_client", mock_client):
        yield mock_client


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


# ── Shorten endpoint ─────────────────────────────────────────────────────────


def test_shorten_returns_201(client):
    resp = client.post("/api/v1/shorten", json={"url": "https://example.com"})
    assert resp.status_code == 201
    data = resp.json()
    assert "short_code" in data
    assert "short_url" in data
    assert (
        data["original_url"] == "https://example.com/"
    )  # Pydantic normalises trailing slash


def test_shorten_custom_alias(client):
    resp = client.post(
        "/api/v1/shorten",
        json={"url": "https://python.org", "custom_alias": "py"},
    )
    assert resp.status_code == 201
    assert resp.json()["short_code"] == "py"


def test_shorten_duplicate_alias_returns_409(client):
    client.post("/api/v1/shorten", json={"url": "https://a.com", "custom_alias": "dup"})
    resp = client.post(
        "/api/v1/shorten", json={"url": "https://b.com", "custom_alias": "dup"}
    )
    assert resp.status_code == 409


def test_shorten_invalid_url_returns_422(client):
    resp = client.post("/api/v1/shorten", json={"url": "not-a-url"})
    assert resp.status_code == 422


# ── Redirect endpoint ────────────────────────────────────────────────────────


def test_redirect_follows_to_original_url(client):
    shorten_resp = client.post(
        "/api/v1/shorten", json={"url": "https://fastapi.tiangolo.com"}
    )
    short_code = shorten_resp.json()["short_code"]

    # TestClient does NOT follow redirects by default — check 302 + Location header
    resp = client.get(f"/{short_code}", follow_redirects=False)
    assert resp.status_code == 302
    assert "fastapi.tiangolo.com" in resp.headers["location"]


def test_redirect_unknown_code_returns_404(client):
    resp = client.get("/nonexistent999", follow_redirects=False)
    assert resp.status_code == 404


# ── Stats endpoint ───────────────────────────────────────────────────────────


def test_stats_returns_click_count(client):
    shorten_resp = client.post(
        "/api/v1/shorten", json={"url": "https://stats-test.com"}
    )
    short_code = shorten_resp.json()["short_code"]

    # Simulate 2 clicks
    client.get(f"/{short_code}", follow_redirects=False)
    client.get(f"/{short_code}", follow_redirects=False)

    stats_resp = client.get(f"/api/v1/stats/{short_code}")
    assert stats_resp.status_code == 200
    assert stats_resp.json()["click_count"] == 2


# ── Health / readiness ───────────────────────────────────────────────────────


def test_health_endpoint(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_ready_endpoint(client):
    resp = client.get("/ready")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ready"
