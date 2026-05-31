from app.models.raw_item import RawItem
from app.sources.base import SourceAdapter


class TopClassActionsSourceAdapter(SourceAdapter):
    source_name = "top_class_actions"

    def fetch_candidates(self, max_items: int | None = None) -> list[RawItem]:
        return []

    def fetch_detail(self, candidate: RawItem) -> RawItem:
        return candidate
