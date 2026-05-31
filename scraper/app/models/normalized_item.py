from datetime import datetime, timezone
from typing import Any, Literal

from pydantic import BaseModel, Field


class NormalizedItem(BaseModel):
    source: str = Field(min_length=1)
    source_url: str = Field(min_length=1)
    title: str = Field(min_length=1)
    raw_content: str = Field(min_length=1)
    raw_content_type: Literal["text", "html", "markdown"] = "text"
    published_at: datetime | None = None
    scraped_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    country_hint: Literal["US", "CA"] | None = None
    fingerprint: str = Field(min_length=1)
    metadata: dict[str, Any] = Field(default_factory=dict)
