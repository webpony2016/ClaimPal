from __future__ import annotations

from datetime import datetime
from typing import Any

import feedparser

from app.models.raw_item import RawItem
from app.sources.base import SourceAdapter

DEFAULT_COURTLISTENER_FEED_URL = "https://www.courtlistener.com/?type=rss"


class CourtListenerSourceAdapter(SourceAdapter):
    source_name = "courtlistener"

    def __init__(
        self,
        *,
        feed_url: str = DEFAULT_COURTLISTENER_FEED_URL,
        client=None,
    ) -> None:
        super().__init__(client=client)
        self.feed_url = feed_url

    def fetch_candidates(self, max_items: int | None = None) -> list[RawItem]:
        response = self._request(self.feed_url)
        response.raise_for_status()
        parsed = feedparser.parse(response.text)
        entries = parsed.entries[:max_items] if max_items is not None else parsed.entries

        items: list[RawItem] = []
        for entry in entries:
            link = getattr(entry, "link", None)
            title = getattr(entry, "title", None)
            if not link or not title or not str(link).startswith(("http://", "https://")):
                continue
            items.append(
                RawItem(
                    source=self.source_name,
                    source_url=link,
                    title=title,
                    published_at=_parse_feed_date(getattr(entry, "published", None)),
                    list_url=self.feed_url,
                    raw_html=getattr(entry, "summary", None),
                    metadata={
                        "entry_id": getattr(entry, "id", None),
                        "feed_url": self.feed_url,
                    },
                )
            )
        return items

    def fetch_detail(self, candidate: RawItem) -> RawItem:
        if candidate.raw_html or candidate.raw_text:
            return candidate

        response = self._request(candidate.source_url)
        response.raise_for_status()
        return candidate.model_copy(
            update={
                "raw_html": response.text,
                "metadata": {
                    **candidate.metadata,
                    "detail_fetched": True,
                    "http_status": response.status_code,
                },
            }
        )


def _parse_feed_date(value: str | None) -> datetime | None:
    if value is None:
        return None

    from dateutil import parser as date_parser

    try:
        return date_parser.parse(value)
    except (ValueError, TypeError, OverflowError):
        return None
