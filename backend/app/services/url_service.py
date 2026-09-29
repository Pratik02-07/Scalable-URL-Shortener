import logging
import random
import string

from sqlalchemy.orm import Session

from app.models.url import URL

logger = logging.getLogger(__name__)

ALPHABET = string.ascii_letters + string.digits  # a-z, A-Z, 0-9


def generate_short_code(length: int = 6) -> str:
    """Generate a random alphanumeric short code of the given length."""
    return "".join(random.choices(ALPHABET, k=length))


def create_short_url(
    db: Session,
    original_url: str,
    custom_alias: str | None = None,
    code_length: int = 6,
) -> URL:
    """
    Persist a new short URL.

    If *custom_alias* is provided it is used as the short code (caller is
    responsible for checking uniqueness first).  Otherwise a random code is
    generated, retrying up to 5 times on collision.
    """
    if custom_alias:
        short_code = custom_alias
    else:
        for _ in range(5):
            candidate = generate_short_code(code_length)
            if not db.query(URL).filter(URL.short_code == candidate).first():
                short_code = candidate
                break
        else:
            # Extremely unlikely – widen the code space by one character
            short_code = generate_short_code(code_length + 2)

    url_obj = URL(short_code=short_code, original_url=original_url)
    db.add(url_obj)
    db.commit()
    db.refresh(url_obj)
    logger.info("URL created: short_code=%s original_url=%s", short_code, original_url)
    return url_obj


def get_url_by_code(db: Session, short_code: str) -> URL | None:
    """Return the active URL record for *short_code*, or None if not found."""
    return (
        db.query(URL)
        .filter(URL.short_code == short_code, URL.is_active == True)  # noqa: E712
        .first()
    )


def increment_click_count(db: Session, short_code: str) -> None:
    """Atomically increment the click counter for the given short code."""
    db.query(URL).filter(URL.short_code == short_code).update(
        {URL.click_count: URL.click_count + 1}
    )
    db.commit()
    logger.info("Click recorded: short_code=%s", short_code)
