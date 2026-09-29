from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
from typing import List

class Settings(BaseSettings):
    APP_NAME: str = "Scalable URL Shortener"
    APP_ENV: str = "development"
    DEBUG: bool = False
    BASE_URL: str = "http://localhost:8000"
    
    DATABASE_URL: str = "sqlite:///./url_shortener_dev.db"
    REDIS_URL: str = "redis://localhost:6379/0"
    LOG_JSON: bool = False
    
    # Allowed CORS origins (restricted for security)
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ]
    
    # Rate limiting
    RATE_LIMIT_REQUESTS: int = 30
    RATE_LIMIT_WINDOW_SECONDS: int = 60
    
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

@lru_cache
def get_settings() -> Settings:
    return Settings()
