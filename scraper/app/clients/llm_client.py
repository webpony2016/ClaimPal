from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from decimal import Decimal
from typing import Protocol

from app.models.normalized_item import NormalizedItem
from app.models.pending_payload import PendingPayload


@dataclass(slots=True)
class LLMExtractionResult:
    model: str = "rule-assisted-llm"
    confidence: float = 0.0
    brand_name: str | None = None
    max_payout: Decimal | None = None
    country: str | None = None
    proof_required: bool | None = None
    deadline: date | None = None
    eligibility_text: str | None = None
    warnings: list[str] = field(default_factory=list)
    evidence: list[str] = field(default_factory=list)


class LLMClient(Protocol):
    def extract(self, item: NormalizedItem, rule_payload: PendingPayload) -> LLMExtractionResult | None:
        ...


class DisabledLLMClient:
    def extract(self, item: NormalizedItem, rule_payload: PendingPayload) -> LLMExtractionResult | None:
        return None
