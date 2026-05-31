from app.services.dedupe import DedupeService
from app.services.state_store import StateStore
from app.utils.hashing import compute_content_hash


def sqlite_url(tmp_path) -> str:
	return f"sqlite:///{tmp_path / 'scraper_state.db'}"


def test_state_store_inserts_first_time_item(tmp_path) -> None:
	store = StateStore(sqlite_url(tmp_path))
	record = store.upsert_item(
		source_url="https://example.com/apple",
		content_hash="sha256:first",
		status="published",
	)

	assert record.source_url == "https://example.com/apple"
	assert record.status == "published"
	assert len(store.list_records()) == 1


def test_dedupe_detects_repeated_identical_url(tmp_path) -> None:
	store = StateStore(sqlite_url(tmp_path))
	store.upsert_item(
		source_url="https://example.com/apple",
		content_hash="sha256:first",
		status="published",
	)
	dedupe = DedupeService(store)

	decision = dedupe.classify(
		source_url="https://example.com/apple",
		content_hash="sha256:first",
	)

	assert decision.kind == "duplicate_url"


def test_dedupe_handles_tracking_parameter_changes(tmp_path) -> None:
	store = StateStore(sqlite_url(tmp_path))
	content_hash = compute_content_hash("source", "Apple", "Apple body")
	store.upsert_item(
		source_url="https://example.com/apple?utm_source=newsletter",
		content_hash=content_hash,
		status="published",
	)
	dedupe = DedupeService(store)

	decision = dedupe.classify(
		source_url="https://example.com/apple?utm_campaign=summer",
		content_hash=content_hash,
	)

	assert decision.kind == "duplicate_url"


def test_dedupe_detects_duplicate_content_hash(tmp_path) -> None:
	store = StateStore(sqlite_url(tmp_path))
	content_hash = compute_content_hash("source", "Apple", "Same body")
	store.upsert_item(
		source_url="https://example.com/apple-one",
		content_hash=content_hash,
		status="published",
	)
	dedupe = DedupeService(store)

	decision = dedupe.classify(
		source_url="https://example.com/apple-two",
		content_hash=content_hash,
	)

	assert decision.kind == "duplicate_content"


def test_retryable_failures_are_not_permanently_blocked(tmp_path) -> None:
	store = StateStore(sqlite_url(tmp_path))
	content_hash = compute_content_hash("source", "Apple", "Retry body")
	store.upsert_item(
		source_url="https://example.com/apple",
		content_hash=content_hash,
		status="failed",
		error_message="temporary outage",
	)
	dedupe = DedupeService(store)

	decision = dedupe.classify(
		source_url="https://example.com/apple",
		content_hash=content_hash,
	)

	assert decision.kind == "retryable_failed_item"
