from __future__ import annotations

from abc import ABC, abstractmethod

import httpx

from app.models.raw_item import RawItem


class SourceAdapter(ABC):
    source_name: str

    def __init__(self, *, client: httpx.Client | None = None) -> None:
        self._client = client

    @abstractmethod
    def fetch_candidates(self, max_items: int | None = None) -> list[RawItem]:
        raise NotImplementedError

    @abstractmethod
    def fetch_detail(self, candidate: RawItem) -> RawItem:
        raise NotImplementedError

    def _request(self, url: str, **kwargs):
        if self._client is not None:
            return self._client.get(url, **kwargs)
        with httpx.Client() as client:
            return client.get(url, **kwargs)
