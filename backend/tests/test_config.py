from app.core.config import get_settings


def test_settings_load():
    settings = get_settings()
    assert settings.APP_NAME == "Scalable URL Shortener"
    assert settings.DATABASE_URL is not None
    assert settings.REDIS_URL is not None
    assert settings.BASE_URL == "http://localhost:8000"
