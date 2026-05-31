"""Source adapters for ClaimPal scraper."""

from app.sources.courtlistener import CourtListenerSourceAdapter
from app.sources.top_class_actions import TopClassActionsSourceAdapter

__all__ = ["CourtListenerSourceAdapter", "TopClassActionsSourceAdapter"]
