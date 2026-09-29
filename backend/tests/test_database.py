import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.models.url import URL

TEST_DATABASE_URL = "sqlite:///:memory:"


@pytest.fixture
def db_session():
    engine = create_engine(TEST_DATABASE_URL)
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    yield session
    session.close()


def test_create_url_model(db_session):
    url_obj = URL(short_code="aB91xK", original_url="https://example.com/long-url")
    db_session.add(url_obj)
    db_session.commit()
    db_session.refresh(url_obj)

    assert url_obj.id is not None
    assert url_obj.short_code == "aB91xK"
    assert url_obj.original_url == "https://example.com/long-url"
    assert url_obj.click_count == 0
    assert url_obj.is_active is True
