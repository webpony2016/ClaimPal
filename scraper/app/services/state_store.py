from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator

from app.utils.hashing import canonicalize_url


@dataclass(slots=True)
class StateRecord:
    source_url: str
    canonical_url: str
    content_hash: str
    status: str
    first_seen_at: str
    last_seen_at: str
    admin_pending_id: str | None
    error_message: str | None


class StateStore:
    def __init__(self, database_url: str) -> None:
        self.database_url = database_url
        self.database_path = _resolve_sqlite_path(database_url)
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        self.initialize()

    def initialize(self) -> None:
        with self.connection() as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS scraper_items (
                    source_url TEXT NOT NULL,
                    canonical_url TEXT PRIMARY KEY,
                    content_hash TEXT NOT NULL,
                    status TEXT NOT NULL,
                    first_seen_at TEXT NOT NULL,
                    last_seen_at TEXT NOT NULL,
                    admin_pending_id TEXT,
                    error_message TEXT
                )
                """
            )
            conn.execute(
                "CREATE INDEX IF NOT EXISTS scraper_items_content_hash_idx ON scraper_items (content_hash)"
            )
            conn.commit()

    @contextmanager
    def connection(self) -> Iterator[sqlite3.Connection]:
        conn = sqlite3.connect(self.database_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        finally:
            conn.close()

    def get_by_url(self, source_url: str) -> StateRecord | None:
        canonical_url = canonicalize_url(source_url)
        with self.connection() as conn:
            row = conn.execute(
                "SELECT * FROM scraper_items WHERE canonical_url = ?",
                (canonical_url,),
            ).fetchone()
        return _row_to_record(row)

    def get_by_content_hash(self, content_hash: str) -> StateRecord | None:
        with self.connection() as conn:
            row = conn.execute(
                "SELECT * FROM scraper_items WHERE content_hash = ? ORDER BY last_seen_at DESC LIMIT 1",
                (content_hash,),
            ).fetchone()
        return _row_to_record(row)

    def upsert_item(
        self,
        *,
        source_url: str,
        content_hash: str,
        status: str,
        admin_pending_id: str | None = None,
        error_message: str | None = None,
    ) -> StateRecord:
        canonical_url = canonicalize_url(source_url)
        timestamp = datetime.now(timezone.utc).isoformat()

        with self.connection() as conn:
            existing = conn.execute(
                "SELECT first_seen_at FROM scraper_items WHERE canonical_url = ?",
                (canonical_url,),
            ).fetchone()
            first_seen_at = existing["first_seen_at"] if existing else timestamp
            conn.execute(
                """
                INSERT INTO scraper_items (
                    source_url,
                    canonical_url,
                    content_hash,
                    status,
                    first_seen_at,
                    last_seen_at,
                    admin_pending_id,
                    error_message
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(canonical_url) DO UPDATE SET
                    source_url = excluded.source_url,
                    content_hash = excluded.content_hash,
                    status = excluded.status,
                    last_seen_at = excluded.last_seen_at,
                    admin_pending_id = excluded.admin_pending_id,
                    error_message = excluded.error_message
                """,
                (
                    source_url,
                    canonical_url,
                    content_hash,
                    status,
                    first_seen_at,
                    timestamp,
                    admin_pending_id,
                    error_message,
                ),
            )
            conn.commit()
            row = conn.execute(
                "SELECT * FROM scraper_items WHERE canonical_url = ?",
                (canonical_url,),
            ).fetchone()

        record = _row_to_record(row)
        if record is None:
            raise RuntimeError("Failed to persist scraper state")
        return record

    def list_records(self) -> list[StateRecord]:
        with self.connection() as conn:
            rows = conn.execute("SELECT * FROM scraper_items ORDER BY canonical_url ASC").fetchall()
        return [record for row in rows if (record := _row_to_record(row)) is not None]


def _resolve_sqlite_path(database_url: str) -> Path:
    prefix = "sqlite:///"
    if not database_url.startswith(prefix):
        raise ValueError("Only sqlite:/// URLs are supported in the first implementation")

    relative_path = database_url.removeprefix(prefix)
    return Path(relative_path).resolve()


def _row_to_record(row: sqlite3.Row | None) -> StateRecord | None:
    if row is None:
        return None
    return StateRecord(
        source_url=row["source_url"],
        canonical_url=row["canonical_url"],
        content_hash=row["content_hash"],
        status=row["status"],
        first_seen_at=row["first_seen_at"],
        last_seen_at=row["last_seen_at"],
        admin_pending_id=row["admin_pending_id"],
        error_message=row["error_message"],
    )
