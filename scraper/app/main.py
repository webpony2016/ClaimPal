import argparse
import json
from collections.abc import Sequence
from typing import Any

from app.clients.admin_api import AdminAPIClient
from app.pipelines.ingest import PipelineRunSummary, IngestionPipeline
from app.services.dedupe import DedupeService
from app.services.publisher import Publisher
from app.services.state_store import StateStore
from app.services.structurer import Structurer
from app.settings import Settings, get_settings
from app.sources import CourtListenerSourceAdapter, TopClassActionsSourceAdapter
from app.utils.logging import configure_logging

SOURCE_FACTORIES = {
    "courtlistener": CourtListenerSourceAdapter,
    "top_class_actions": TopClassActionsSourceAdapter,
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="ClaimPal scraper CLI")
    source_group = parser.add_mutually_exclusive_group()
    source_group.add_argument(
        "--source",
        choices=sorted(SOURCE_FACTORIES),
        help="Run a single configured source adapter.",
    )
    source_group.add_argument(
        "--all-sources",
        action="store_true",
        help="Run all configured source adapters.",
    )
    parser.add_argument(
        "--show-settings",
        action="store_true",
        help="Print the currently loaded scraper settings with secrets redacted.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Build payloads without calling the Admin API.",
    )
    parser.add_argument(
        "--max-items",
        type=int,
        default=None,
        help="Optional max number of items to fetch from a source.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose structured logging.",
    )
    return parser


def serialize_settings(settings: Settings) -> dict[str, Any]:
    token = settings.admin_bearer_token
    if len(token) > 8:
        redacted_token = f"{token[:4]}...{token[-4:]}"
    else:
        redacted_token = "***redacted***"

    llm_configured = bool(
        settings.llm_api_key and settings.llm_api_key != "replace-with-llm-key"
    )

    return {
        "admin_api_base_url": settings.admin_api_base_url,
        "admin_bearer_token": redacted_token,
        "llm_configured": llm_configured,
        "scraper_state_db_url": settings.scraper_state_db_url,
        "request_timeout_seconds": settings.request_timeout_seconds,
        "max_retries": settings.max_retries,
        "user_agent": settings.user_agent,
    }


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    settings = get_settings()

    if args.show_settings and not (args.source or args.all_sources or args.dry_run):
        print(
            json.dumps(
                {"mode": "show-settings", "settings": serialize_settings(settings)},
                ensure_ascii=False,
                indent=2,
            )
        )
        return 0

    if args.dry_run and not (args.source or args.all_sources):
        print(
            json.dumps(
                {"mode": "dry-run", "settings": serialize_settings(settings)},
                ensure_ascii=False,
                indent=2,
            )
        )
        return 0

    if not (args.source or args.all_sources):
        parser.print_help()
        return 0

    configure_logging(verbose=args.verbose)
    state_store = StateStore(settings.scraper_state_db_url)
    dedupe_service = DedupeService(state_store)
    structurer = Structurer()
    publisher = None if args.dry_run else Publisher(AdminAPIClient(settings), settings)
    pipeline = IngestionPipeline(
        state_store=state_store,
        dedupe_service=dedupe_service,
        structurer=structurer,
        publisher=publisher,
    )

    source_names = list(SOURCE_FACTORIES) if args.all_sources else [args.source]
    summaries = []
    for source_name in source_names:
        if source_name is None:
            continue
        adapter = SOURCE_FACTORIES[source_name]()
        summary = pipeline.run(adapter, max_items=args.max_items, dry_run=args.dry_run)
        summaries.append(summary_to_dict(summary))

    print(json.dumps({"mode": "dry-run" if args.dry_run else "publish", "summaries": summaries}, ensure_ascii=False, indent=2))
    return 0


def summary_to_dict(summary: PipelineRunSummary) -> dict[str, Any]:
    return {
        "source": summary.source,
        "total_candidates": summary.total_candidates,
        "skipped_duplicates": summary.skipped_duplicates,
        "publish_successes": summary.publish_successes,
        "publish_failures": summary.publish_failures,
        "parse_failures": summary.parse_failures,
        "dry_run_items": summary.dry_run_items,
        "started_at": summary.started_at.isoformat(),
        "finished_at": summary.finished_at.isoformat() if summary.finished_at else None,
        "elapsed_seconds": summary.elapsed_seconds,
        "item_results": [
            {
                "source_url": item.source_url,
                "status": item.status,
                "message": item.message,
                "payload": item.payload,
            }
            for item in summary.item_results
        ],
    }


if __name__ == "__main__":
    raise SystemExit(main())
