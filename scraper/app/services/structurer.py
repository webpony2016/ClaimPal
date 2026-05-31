from __future__ import annotations

from decimal import Decimal
from typing import Any

from app.clients.llm_client import DisabledLLMClient, LLMClient, LLMExtractionResult
from app.extractors.settlement_facts import (
    extract_brand_name_from_title,
    extract_country_hint,
    extract_proof_required,
    summarize_eligibility,
)
from app.models.normalized_item import NormalizedItem
from app.models.pending_payload import PendingPayload
from app.utils.dates import find_deadline
from app.utils.money import find_max_payout

DEFAULT_PROMPT_VERSION = "rule-only-v1"


class Structurer:
    def __init__(
        self,
        *,
        llm_client: LLMClient | None = None,
        prompt_version: str = DEFAULT_PROMPT_VERSION,
    ) -> None:
        self.llm_client = llm_client or DisabledLLMClient()
        self.prompt_version = prompt_version

    def build_payload(self, item: NormalizedItem) -> PendingPayload:
        payload = self._build_rule_payload(item)
        llm_result = self.llm_client.extract(item, payload)
        if llm_result is None:
            return payload

        return self._merge_llm_result(payload, item, llm_result)

    def _build_rule_payload(self, item: NormalizedItem) -> PendingPayload:
        country = item.country_hint or extract_country_hint(item.raw_content, source=item.source)
        if country is None:
            country = "CA" if "canlii" in item.source.casefold() else "US"

        proof_required = extract_proof_required(item.raw_content)
        evidence: list[str] = []
        deadline = find_deadline(item.raw_content)
        if deadline is not None:
            evidence.append(f"deadline:{deadline.isoformat()}")

        max_payout = find_max_payout(item.raw_content)
        if max_payout is not None:
            evidence.append(f"max_payout:{max_payout}")

        if proof_required is not None:
            evidence.append(f"proof_required:{proof_required}")

        return PendingPayload(
            source_url=item.source_url,
            raw_content=item.raw_content,
            raw_content_type=item.raw_content_type,
            brand_name=extract_brand_name_from_title(item.title),
            max_payout=max_payout,
            country=country,
            proof_required=proof_required if proof_required is not None else False,
            deadline=deadline,
            eligibility_text=summarize_eligibility(item.raw_content),
            ai_payload={
                "model": "rule-based",
                "confidence": 0.0,
                "prompt_version": self.prompt_version,
                "warnings": [],
                "evidence": evidence,
            },
            scraper_payload={
                "source": item.source,
                "content_hash": item.fingerprint,
                "fetched_at": item.scraped_at.isoformat(),
                "title": item.title,
                "published_at": item.published_at.isoformat() if item.published_at else None,
                "raw_excerpt": item.raw_content[:280],
            },
        )

    def _merge_llm_result(
        self,
        base_payload: PendingPayload,
        item: NormalizedItem,
        llm_result: LLMExtractionResult,
    ) -> PendingPayload:
        merged = base_payload.model_dump()
        warnings = list(base_payload.ai_payload.get("warnings", []))
        evidence = list(base_payload.ai_payload.get("evidence", []))

        if llm_result.confidence >= 0.5:
            for field_name in (
                "brand_name",
                "max_payout",
                "country",
                "proof_required",
                "deadline",
                "eligibility_text",
            ):
                value = getattr(llm_result, field_name)
                if value is not None:
                    merged[field_name] = value
        else:
            warnings.append("Ignored LLM override because confidence was below threshold")

        try:
            payload = PendingPayload(**merged)
        except Exception:
            warnings.append("Ignored invalid LLM override after schema validation")
            payload = base_payload

        payload.ai_payload = {
            "model": llm_result.model,
            "confidence": llm_result.confidence,
            "prompt_version": self.prompt_version,
            "warnings": warnings + list(llm_result.warnings),
            "evidence": evidence + list(llm_result.evidence),
        }
        payload.scraper_payload = {
            **base_payload.scraper_payload,
            "llm_used": True,
        }
        return payload
