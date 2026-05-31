from __future__ import annotations

from typing import Any

from tenacity import Retrying, retry_if_exception_type, stop_after_attempt, wait_exponential

from app.clients.admin_api import AdminAPIClient, RetryablePublishError
from app.models.pending_payload import PendingPayload
from app.settings import Settings


class Publisher:
    def __init__(self, client: AdminAPIClient, settings: Settings) -> None:
        self.client = client
        self.settings = settings

    def publish(self, payload: PendingPayload) -> dict[str, Any]:
        attempts = max(self.settings.max_retries, 0) + 1
        retryer = Retrying(
            retry=retry_if_exception_type(RetryablePublishError),
            stop=stop_after_attempt(attempts),
            wait=wait_exponential(multiplier=0.1, min=0.1, max=1),
            reraise=True,
        )

        for attempt in retryer:
            with attempt:
                return self.client.publish_pending(payload)

        raise RuntimeError("Publisher retry loop exited unexpectedly")
