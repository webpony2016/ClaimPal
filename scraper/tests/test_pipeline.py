from datetime import datetime, timezone
from pathlib import Path

import httpx

from app.clients.admin_api import RetryablePublishError
from app.models.raw_item import RawItem
from app.pipelines.ingest import IngestionPipeline
from app.services.dedupe import DedupeService
from app.services.state_store import StateStore
from app.services.structurer import Structurer
from app.sources.courtlistener import CourtListenerSourceAdapter


FIXTURES_DIR = Path(__file__).parent / "fixtures"


def sqlite_url(tmp_path) -> str:
	return f"sqlite:///{tmp_path / 'pipeline_state.db'}"


class FakeSourceAdapter:
	source_name = "fake"

	def __init__(self, items):
		self.items = items

	def fetch_candidates(self, max_items=None):
		return self.items[:max_items] if max_items is not None else self.items

	def fetch_detail(self, candidate):
		return candidate


class FakePublisher:
	def __init__(self, *, should_fail: bool = False):
		self.should_fail = should_fail

	def publish(self, payload):
		if self.should_fail:
			raise RetryablePublishError("temporary publish failure")
		return {"count": 1, "item": {"id": "pending-123"}}


def build_pipeline(tmp_path, publisher=None) -> IngestionPipeline:
	state_store = StateStore(sqlite_url(tmp_path))
	return IngestionPipeline(
		state_store=state_store,
		dedupe_service=DedupeService(state_store),
		structurer=Structurer(),
		publisher=publisher,
	)


def build_raw_item(*, source_url: str = "https://example.com/apple", raw_text: str | None = None, raw_html: str | None = None) -> RawItem:
	return RawItem(
		source="courtlistener",
		source_url=source_url,
		title="Apple Settlement Notice",
		published_at=datetime(2026, 5, 30, tzinfo=timezone.utc),
		list_url="https://example.com/feed",
		raw_text=raw_text,
		raw_html=raw_html,
		metadata={},
	)


def test_courtlistener_fetch_candidates_parses_fixture_feed() -> None:
	feed_xml = (FIXTURES_DIR / "courtlistener" / "feed.xml").read_text(encoding="utf-8")
	adapter = CourtListenerSourceAdapter(
		feed_url="https://example.com/feed.xml",
		client=httpx.Client(transport=httpx.MockTransport(lambda request: httpx.Response(200, text=feed_xml))),
	)

	candidates = adapter.fetch_candidates()

	assert len(candidates) == 1
	assert candidates[0].title == "Apple Settlement Notice"
	assert candidates[0].raw_html is not None


def test_courtlistener_fetch_detail_falls_back_to_http() -> None:
	detail_html = (FIXTURES_DIR / "courtlistener" / "detail.html").read_text(encoding="utf-8")
	adapter = CourtListenerSourceAdapter(
		client=httpx.Client(transport=httpx.MockTransport(lambda request: httpx.Response(200, text=detail_html)))
	)
	candidate = build_raw_item(raw_text=None, raw_html=None)

	detailed = adapter.fetch_detail(candidate)

	assert detailed.raw_html == detail_html
	assert detailed.metadata["detail_fetched"] is True


def test_pipeline_success_path(tmp_path) -> None:
	pipeline = build_pipeline(tmp_path, publisher=FakePublisher())
	adapter = FakeSourceAdapter([
		build_raw_item(raw_text="United States customers may be eligible. Claim deadline: August 14, 2026. Up to $35.00."),
	])

	summary = pipeline.run(adapter)

	assert summary.publish_successes == 1
	assert summary.publish_failures == 0
	assert summary.item_results[0].status == "published"


def test_pipeline_duplicate_skip_path(tmp_path) -> None:
	pipeline = build_pipeline(tmp_path, publisher=FakePublisher())
	item = build_raw_item(raw_text="United States customers may be eligible. Up to $35.00.")
	adapter = FakeSourceAdapter([item])

	first_summary = pipeline.run(adapter)
	second_summary = pipeline.run(adapter)

	assert first_summary.publish_successes == 1
	assert second_summary.skipped_duplicates == 1


def test_pipeline_admin_api_failure_path(tmp_path) -> None:
	pipeline = build_pipeline(tmp_path, publisher=FakePublisher(should_fail=True))
	adapter = FakeSourceAdapter([
		build_raw_item(raw_text="United States customers may be eligible. Up to $35.00."),
	])

	summary = pipeline.run(adapter)

	assert summary.publish_failures == 1
	assert summary.item_results[0].status == "publish_failed"


def test_pipeline_parse_failure_path(tmp_path) -> None:
	pipeline = build_pipeline(tmp_path, publisher=FakePublisher())
	adapter = FakeSourceAdapter([
		build_raw_item(raw_text=None, raw_html=None),
	])

	summary = pipeline.run(adapter)

	assert summary.parse_failures == 1
	assert summary.item_results[0].status == "parse_failed"


def test_pipeline_dry_run_path(tmp_path) -> None:
	pipeline = build_pipeline(tmp_path, publisher=None)
	adapter = FakeSourceAdapter([
		build_raw_item(raw_text="United States customers may be eligible. Up to $35.00."),
	])

	summary = pipeline.run(adapter, dry_run=True)

	assert summary.dry_run_items == 1
	assert summary.publish_successes == 0
	assert summary.item_results[0].status == "dry_run"
