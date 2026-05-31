from datetime import date, datetime, timezone
from decimal import Decimal
from pathlib import Path

import pytest
from pydantic import ValidationError

from app.clients.llm_client import LLMExtractionResult
from app.extractors.html_to_text import extract_readable_content
from app.extractors.settlement_facts import extract_country_hint, extract_proof_required
from app.models.normalized_item import NormalizedItem
from app.models.pending_payload import PendingPayload
from app.services.structurer import Structurer
from app.utils.dates import find_deadline
from app.utils.money import find_max_payout


FIXTURES_DIR = Path(__file__).parent / "fixtures"


class StubLLMClient:
	def __init__(self, result: LLMExtractionResult | None) -> None:
		self.result = result

	def extract(self, item, rule_payload):
		return self.result


def build_item(raw_content: str, raw_content_type: str = "markdown") -> NormalizedItem:
	return NormalizedItem(
		source="courtlistener",
		source_url="https://example.com/apple",
		title="Apple Settlement Notice",
		raw_content=raw_content,
		raw_content_type=raw_content_type,
		published_at=datetime(2026, 5, 30, tzinfo=timezone.utc),
		scraped_at=datetime(2026, 5, 30, 10, 0, tzinfo=timezone.utc),
		country_hint=None,
		fingerprint="sha256:test",
		metadata={},
	)


def test_pending_payload_rejects_empty_raw_content() -> None:
	with pytest.raises(ValidationError):
		PendingPayload(raw_content="", brand_name="Apple", country="US")


def test_pending_payload_rejects_invalid_country() -> None:
	with pytest.raises(ValidationError):
		PendingPayload(raw_content="x", brand_name="Apple", country="MX")


def test_pending_payload_rejects_negative_max_payout() -> None:
	with pytest.raises(ValidationError):
		PendingPayload(raw_content="x", brand_name="Apple", country="US", max_payout=Decimal("-1"))


def test_pending_payload_rejects_unsupported_raw_content_type() -> None:
	with pytest.raises(ValidationError):
		PendingPayload(raw_content="x", brand_name="Apple", country="US", raw_content_type="pdf")


def test_html_extraction_fixture_preserves_structure() -> None:
	html = (FIXTURES_DIR / "sample_settlement.html").read_text(encoding="utf-8")

	content, content_type = extract_readable_content(html)

	assert content_type == "markdown"
	assert "# Apple Settlement" in content
	assert "- Eligible class members purchased covered Apple devices." in content


def test_rule_helpers_extract_dates_money_country_and_proof() -> None:
	text = (FIXTURES_DIR / "sample_settlement.html").read_text(encoding="utf-8")
	content, _ = extract_readable_content(text)

	assert find_deadline(content) == date(2026, 8, 14)
	assert find_max_payout(content) == Decimal("35.00")
	assert extract_country_hint(content, source="courtlistener") == "US"
	assert extract_proof_required(content) is False


def test_structurer_builds_rule_only_payload() -> None:
	html = (FIXTURES_DIR / "sample_settlement.html").read_text(encoding="utf-8")
	content, content_type = extract_readable_content(html)
	structurer = Structurer()

	payload = structurer.build_payload(build_item(content, content_type))

	assert payload.brand_name == "Apple"
	assert payload.country == "US"
	assert payload.max_payout == Decimal("35.00")
	assert payload.deadline == date(2026, 8, 14)
	assert payload.ai_payload["model"] == "rule-based"
	assert payload.scraper_payload["content_hash"] == "sha256:test"


def test_structurer_applies_valid_llm_override() -> None:
	structurer = Structurer(
		llm_client=StubLLMClient(
			LLMExtractionResult(
				model="test-llm",
				confidence=0.95,
				brand_name="Apple Inc.",
				eligibility_text="LLM summary",
				evidence=["brand:Apple Inc."],
			)
		)
	)

	payload = structurer.build_payload(build_item("United States customers may be eligible. Claim deadline: August 14, 2026. Up to $35.00."))

	assert payload.brand_name == "Apple Inc."
	assert payload.eligibility_text == "LLM summary"
	assert payload.ai_payload["model"] == "test-llm"
	assert "brand:Apple Inc." in payload.ai_payload["evidence"]


def test_structurer_ignores_invalid_llm_override() -> None:
	structurer = Structurer(
		llm_client=StubLLMClient(
			LLMExtractionResult(
				model="test-llm",
				confidence=0.95,
				country="MX",
				warnings=["country mismatch"],
			)
		)
	)

	payload = structurer.build_payload(build_item("United States customers may be eligible."))

	assert payload.country == "US"
	assert any("Ignored invalid LLM override" in warning for warning in payload.ai_payload["warnings"])
