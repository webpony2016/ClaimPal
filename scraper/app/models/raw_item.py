from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class RawItem(BaseModel):
    source: str = Field(min_length=1)
    source_url: str = Field(min_length=1)
    title: str = Field(min_length=1)
    published_at: datetime | None = None
    list_url: str | None = None
    raw_html: str | None = None
    raw_text: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)

    def best_raw_content(self) -> str | None:
        return self.raw_text or self.raw_html
