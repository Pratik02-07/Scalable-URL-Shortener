import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.services.url_service import (
    create_short_url,
    generate_short_code,
    get_url_by_code,
    increment_click_count,
)


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()


def test_generate_short_code_length():
    code = generate_short_code(6)
    assert len(code) == 6
    assert code.isalnum()


def test_create_and_retrieve_short_url(db_session):
    url_obj = create_short_url(db_session, "https://google.com")
    assert url_obj.short_code is not None
    assert url_obj.original_url == "https://google.com"

    fetched = get_url_by_code(db_session, url_obj.short_code)
    assert fetched is not None
    assert fetched.original_url == "https://google.com"


def test_increment_click_count(db_session):
    url_obj = create_short_url(db_session, "https://python.org")
    increment_click_count(db_session, url_obj.short_code)
    db_session.refresh(url_obj)
    assert url_obj.click_count == 1
