from datetime import date
from decimal import Decimal
from typing import Any, Literal

from pydantic import BaseModel, Field, HttpUrl


class PendingPayload(BaseModel):
    source_url: HttpUrl | None = None
    raw_content: str = Field(min_length=1)
    raw_content_type: Literal["text", "html", "markdown"] = "text"
    brand_name: str = Field(min_length=1)
    max_payout: Decimal | None = Field(default=None, ge=0)
    country: Literal["US", "CA"]
    proof_required: bool = False
    deadline: date | None = None
    eligibility_text: str | None = None
    ai_payload: dict[str, Any] = Field(default_factory=dict)
    scraper_payload: dict[str, Any] = Field(default_factory=dict)

    def to_api_payload(self) -> dict[str, Any]:
        return self.model_dump(mode="json")
