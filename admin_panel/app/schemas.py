from datetime import date, datetime
from decimal import Decimal
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, HttpUrl, field_validator


NON_NULL_UPDATE_FIELDS = (
    "raw_content",
    "raw_content_type",
    "brand_name",
    "country",
    "proof_required",
    "ai_payload",
    "scraper_payload",
)


class PendingSettlementCreate(BaseModel):
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


class PendingSettlementUpdate(BaseModel):
    source_url: HttpUrl | None = None
    raw_content: str | None = Field(default=None, min_length=1)
    raw_content_type: Literal["text", "html", "markdown"] | None = None
    brand_name: str | None = Field(default=None, min_length=1)
    max_payout: Decimal | None = Field(default=None, ge=0)
    country: Literal["US", "CA"] | None = None
    proof_required: bool | None = None
    deadline: date | None = None
    eligibility_text: str | None = None
    ai_payload: dict[str, Any] | None = None
    scraper_payload: dict[str, Any] | None = None

    @field_validator(*NON_NULL_UPDATE_FIELDS, mode="before")
    @classmethod
    def reject_explicit_null_for_non_nullable_fields(cls, value: Any) -> Any:
        if value is None:
            raise ValueError("Field cannot be null")

        return value


class PendingSettlementRead(BaseModel):
    id: UUID
    source_url: HttpUrl | None
    raw_content: str
    raw_content_type: Literal["text", "html", "markdown"]
    brand_name: str
    max_payout: Decimal | None
    country: Literal["US", "CA"]
    proof_required: bool
    deadline: date | None
    eligibility_text: str | None
    ai_payload: dict[str, Any]
    scraper_payload: dict[str, Any]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PendingItemResponse(BaseModel):
    item: PendingSettlementRead | None
    count: int


class SettlementApprovalPayload(BaseModel):
    brand_name: str = Field(min_length=1)
    max_payout: Decimal | None = Field(default=None, ge=0)
    country: Literal["US", "CA"]
    proof_required: bool = False
    deadline: date | None = None
    eligibility_text: str | None = None


class ApprovalResponse(PendingItemResponse):
    data_version: int
