from __future__ import annotations

from typing import Any

import httpx

from app.models.pending_payload import PendingPayload
from app.settings import Settings


class PublishError(RuntimeError):
    """Base publish error."""


class NonRetryablePublishError(PublishError):
    """Errors that should not be retried."""


class RetryablePublishError(PublishError):
    """Errors that can be retried safely."""


class AdminAPIClient:
    def __init__(
        self,
        settings: Settings,
        *,
        client: httpx.Client | None = None,
    ) -> None:
        self.settings = settings
        self._client = client

    def publish_pending(self, payload: PendingPayload) -> dict[str, Any]:
        try:
            response = self._request("POST", "/api/admin/scraped-pool", json=payload.to_api_payload())
        except httpx.HTTPError as exc:
            raise RetryablePublishError(f"Admin API request failed: {exc}") from exc

        if response.status_code == 201:
            return response.json()
        if response.status_code == 401:
            raise NonRetryablePublishError("Admin API rejected the bearer token")
        if response.status_code == 422:
            raise NonRetryablePublishError(
                f"Admin API validation failed: {response.text}"
            )
        if 500 <= response.status_code <= 599:
            raise RetryablePublishError(
                f"Admin API server error {response.status_code}: {response.text}"
            )

        raise NonRetryablePublishError(
            f"Unexpected admin API response {response.status_code}: {response.text}"
        )

    def _request(self, method: str, path: str, **kwargs: Any) -> httpx.Response:
        headers = kwargs.pop("headers", {})
        headers.update(
            {
                "Authorization": f"Bearer {self.settings.admin_bearer_token}",
                "Content-Type": "application/json",
                "User-Agent": self.settings.user_agent,
            }
        )
        base_url = self.settings.admin_api_base_url.rstrip("/")
        url = f"{base_url}{path}"

        if self._client is not None:
            return self._client.request(method, url, headers=headers, timeout=self.settings.request_timeout_seconds, **kwargs)

        with httpx.Client() as client:
            return client.request(method, url, headers=headers, timeout=self.settings.request_timeout_seconds, **kwargs)
