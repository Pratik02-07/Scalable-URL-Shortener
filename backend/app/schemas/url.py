from pydantic import BaseModel, HttpUrl, Field, ConfigDict
from datetime import datetime
from typing import Optional

class URLCreate(BaseModel):
    url: HttpUrl
    custom_alias: Optional[str] = Field(None, max_length=50)

class URLResponse(BaseModel):
    short_code: str
    short_url: str
    original_url: str
    click_count: int
    created_at: datetime
    is_active: bool

    model_config = ConfigDict(from_attributes=True)

class URLStatsResponse(BaseModel):
    short_code: str
    original_url: str
    click_count: int
    created_at: datetime
    is_active: bool
