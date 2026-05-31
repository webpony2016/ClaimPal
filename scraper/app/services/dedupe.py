from dataclasses import dataclass

from app.services.state_store import StateRecord, StateStore

RETRYABLE_FAILURE_STATUSES = {"failed", "publish_failed_retryable", "fetch_failed", "parse_failed"}


@dataclass(slots=True)
class DedupeDecision:
    kind: str
    record: StateRecord | None = None


class DedupeService:
    def __init__(self, state_store: StateStore) -> None:
        self.state_store = state_store

    def classify(self, *, source_url: str, content_hash: str) -> DedupeDecision:
        url_record = self.state_store.get_by_url(source_url)
        if url_record is not None:
            if url_record.status in RETRYABLE_FAILURE_STATUSES:
                return DedupeDecision(kind="retryable_failed_item", record=url_record)
            return DedupeDecision(kind="duplicate_url", record=url_record)

        hash_record = self.state_store.get_by_content_hash(content_hash)
        if hash_record is not None:
            if hash_record.status in RETRYABLE_FAILURE_STATUSES:
                return DedupeDecision(kind="retryable_failed_item", record=hash_record)
            return DedupeDecision(kind="duplicate_content", record=hash_record)

        return DedupeDecision(kind="new")
