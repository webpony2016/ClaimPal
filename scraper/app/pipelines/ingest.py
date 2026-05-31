from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

from app.clients.admin_api import NonRetryablePublishError, RetryablePublishError
from app.extractors.html_to_text import extract_readable_content
from app.extractors.settlement_facts import extract_country_hint
from app.models.normalized_item import NormalizedItem
from app.models.pending_payload import PendingPayload
from app.models.raw_item import RawItem
from app.services.dedupe import DedupeService
from app.services.publisher import Publisher
from app.services.state_store import StateStore
from app.services.structurer import Structurer
from app.utils.hashing import compute_content_hash


@dataclass(slots=True)
class PipelineItemResult:
    source_url: str
    status: str
    message: str | None = None
    payload: dict[str, Any] | None = None


@dataclass(slots=True)
class PipelineRunSummary:
    source: str
    total_candidates: int = 0
    skipped_duplicates: int = 0
    publish_successes: int = 0
    publish_failures: int = 0
    parse_failures: int = 0
    dry_run_items: int = 0
    started_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    finished_at: datetime | None = None
    item_results: list[PipelineItemResult] = field(default_factory=list)

    @property
    def elapsed_seconds(self) -> float:
        end = self.finished_at or datetime.now(timezone.utc)
        return (end - self.started_at).total_seconds()


class IngestionPipeline:
    def __init__(
        self,
        *,
        state_store: StateStore,
        dedupe_service: DedupeService,
        structurer: Structurer,
        publisher: Publisher | None = None,
    ) -> None:
        self.state_store = state_store
        self.dedupe_service = dedupe_service
        self.structurer = structurer
        self.publisher = publisher

    def run(self, adapter: Any, *, max_items: int | None = None, dry_run: bool = False) -> PipelineRunSummary:
        summary = PipelineRunSummary(source=adapter.source_name)
        candidates = adapter.fetch_candidates(max_items=max_items)
        summary.total_candidates = len(candidates)

        for candidate in candidates:
            try:
                detail_item = adapter.fetch_detail(candidate)
                normalized = self._normalize_item(detail_item)
                decision = self.dedupe_service.classify(
                    source_url=normalized.source_url,
                    content_hash=normalized.fingerprint,
                )
                if decision.kind in {"duplicate_url", "duplicate_content"}:
                    summary.skipped_duplicates += 1
                    self.state_store.upsert_item(
                        source_url=normalized.source_url,
                        content_hash=normalized.fingerprint,
                        status=decision.kind,
                    )
                    summary.item_results.append(
                        PipelineItemResult(
                            source_url=normalized.source_url,
                            status=decision.kind,
                            message="Skipped duplicate candidate",
                        )
                    )
                    continue

                payload = self.structurer.build_payload(normalized)

                if dry_run:
                    summary.dry_run_items += 1
                    self.state_store.upsert_item(
                        source_url=normalized.source_url,
                        content_hash=normalized.fingerprint,
                        status="dry_run",
                    )
                    summary.item_results.append(
                        PipelineItemResult(
                            source_url=normalized.source_url,
                            status="dry_run",
                            payload=payload.to_api_payload(),
                        )
                    )
                    continue

                if self.publisher is None:
                    raise RuntimeError("Publisher is required when dry_run is False")

                publish_response = self.publisher.publish(payload)
                pending_id = None
                item = publish_response.get("item") if isinstance(publish_response, dict) else None
                if isinstance(item, dict):
                    pending_id = item.get("id")
                self.state_store.upsert_item(
                    source_url=normalized.source_url,
                    content_hash=normalized.fingerprint,
                    status="published",
                    admin_pending_id=pending_id,
                )
                summary.publish_successes += 1
                summary.item_results.append(
                    PipelineItemResult(
                        source_url=normalized.source_url,
                        status="published",
                        payload=payload.to_api_payload(),
                    )
                )
            except (NonRetryablePublishError, RetryablePublishError) as exc:
                summary.publish_failures += 1
                summary.item_results.append(
                    PipelineItemResult(
                        source_url=candidate.source_url,
                        status="publish_failed",
                        message=str(exc),
                    )
                )
                self.state_store.upsert_item(
                    source_url=candidate.source_url,
                    content_hash=compute_content_hash(candidate.source, candidate.title, candidate.best_raw_content() or candidate.title),
                    status="failed" if isinstance(exc, RetryablePublishError) else "failed_nonretryable",
                    error_message=str(exc),
                )
            except Exception as exc:
                summary.parse_failures += 1
                summary.item_results.append(
                    PipelineItemResult(
                        source_url=candidate.source_url,
                        status="parse_failed",
                        message=str(exc),
                    )
                )
                self.state_store.upsert_item(
                    source_url=candidate.source_url,
                    content_hash=compute_content_hash(candidate.source, candidate.title, candidate.best_raw_content() or candidate.title),
                    status="parse_failed",
                    error_message=str(exc),
                )

        summary.finished_at = datetime.now(timezone.utc)
        return summary

    def _normalize_item(self, item: RawItem) -> NormalizedItem:
        if item.raw_text:
            raw_content = item.raw_text.strip()
            raw_content_type = "text"
        elif item.raw_html:
            raw_content, raw_content_type = extract_readable_content(item.raw_html)
        else:
            raise ValueError("Raw item did not include raw_text or raw_html")

        if not raw_content.strip():
            raise ValueError("Extracted raw content was empty")

        fingerprint = compute_content_hash(item.source, item.title, raw_content)
        return NormalizedItem(
            source=item.source,
            source_url=item.source_url,
            title=item.title,
            raw_content=raw_content,
            raw_content_type=raw_content_type,
            published_at=item.published_at,
            country_hint=extract_country_hint(raw_content, source=item.source),
            fingerprint=fingerprint,
            metadata=item.metadata,
        )
