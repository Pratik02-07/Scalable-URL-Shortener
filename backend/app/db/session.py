from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import get_settings

settings = get_settings()

# SQLite needs two special settings:
#   check_same_thread=False  — SQLite objects may be used across threads (FastAPI threadpool)
#   pool_pre_ping is irrelevant for SQLite but harmless to keep for PostgreSQL parity
_is_sqlite = settings.DATABASE_URL.startswith("sqlite")

_connect_args = {"check_same_thread": False} if _is_sqlite else {}

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=_connect_args,
    pool_pre_ping=not _is_sqlite,  # pre-ping is for PostgreSQL; skip for SQLite
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
