from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    APP_NAME: str = "Scalable URL Shortener"
    APP_ENV: str = "development"
    DEBUG: bool = True
    BASE_URL: str = "http://localhost:8000"
    
    DATABASE_URL: str = "sqlite:///./url_shortener_dev.db"
    REDIS_URL: str = "redis://localhost:6379/0"
    LOG_JSON: bool = False
    
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

@lru_cache
def get_settings() -> Settings:
    return Settings()
