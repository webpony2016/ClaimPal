import httpx
import pytest

from app.clients.admin_api import (
	AdminAPIClient,
	NonRetryablePublishError,
	RetryablePublishError,
)
from app.models.pending_payload import PendingPayload
from app.settings import Settings


def build_settings() -> Settings:
	return Settings(
		ADMIN_API_BASE_URL="http://127.0.0.1:8008",
		ADMIN_BEARER_TOKEN="test-admin-token",
		LLM_API_KEY="replace-with-llm-key",
		SCRAPER_STATE_DB_URL="sqlite:///test.db",
		REQUEST_TIMEOUT_SECONDS=5,
		MAX_RETRIES=1,
		USER_AGENT="ClaimPalScraper/0.1",
		_env_file=None,
	)


def build_payload() -> PendingPayload:
	return PendingPayload(
		source_url="https://example.com/apple",
		raw_content="Apple settlement details",
		brand_name="Apple",
		country="US",
	)


def test_admin_api_client_publishes_successfully() -> None:
	def handler(request: httpx.Request) -> httpx.Response:
		assert request.headers["Authorization"] == "Bearer test-admin-token"
		assert request.url.path == "/api/admin/scraped-pool"
		return httpx.Response(201, json={"count": 1, "item": {"id": "abc-123"}})

	client = httpx.Client(transport=httpx.MockTransport(handler))
	api_client = AdminAPIClient(build_settings(), client=client)

	response = api_client.publish_pending(build_payload())

	assert response["count"] == 1
	assert response["item"]["id"] == "abc-123"


def test_admin_api_client_raises_non_retryable_for_unauthorized() -> None:
	client = httpx.Client(
		transport=httpx.MockTransport(lambda request: httpx.Response(401, text="nope"))
	)
	api_client = AdminAPIClient(build_settings(), client=client)

	with pytest.raises(NonRetryablePublishError):
		api_client.publish_pending(build_payload())


def test_admin_api_client_raises_non_retryable_for_validation_failure() -> None:
	client = httpx.Client(
		transport=httpx.MockTransport(lambda request: httpx.Response(422, text="invalid payload"))
	)
	api_client = AdminAPIClient(build_settings(), client=client)

	with pytest.raises(NonRetryablePublishError) as exc_info:
		api_client.publish_pending(build_payload())

	assert "invalid payload" in str(exc_info.value)


def test_admin_api_client_raises_retryable_for_server_error() -> None:
	client = httpx.Client(
		transport=httpx.MockTransport(lambda request: httpx.Response(500, text="server boom"))
	)
	api_client = AdminAPIClient(build_settings(), client=client)

	with pytest.raises(RetryablePublishError):
		api_client.publish_pending(build_payload())
