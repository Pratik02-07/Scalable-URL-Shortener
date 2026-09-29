import os

# Enforce in-memory SQLite and mock Redis before any app modules load
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["REDIS_URL"] = "redis://localhost:6379/0"
os.environ["APP_ENV"] = "development"
os.environ["DEBUG"] = "true"
