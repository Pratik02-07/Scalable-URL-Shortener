import os
import pytest

# Set test environment variables before any app module imports
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["REDIS_URL"] = "redis://localhost:6379/0"
os.environ["APP_ENV"] = "test"
os.environ["DEBUG"] = "true"
os.environ["RATE_LIMIT_REQUESTS"] = "1000"
