import pytest
from pydantic import ValidationError

from app.settings import (
    DEFAULT_MAX_RETRIES,
    DEFAULT_REQUEST_TIMEOUT_SECONDS,
    DEFAULT_SCRAPER_STATE_DB_URL,
    DEFAULT_USER_AGENT,
    Settings,
)


def test_settings_requires_admin_api_base_url(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ADMIN_BEARER_TOKEN", "test-admin-token")

    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=None)

    assert "ADMIN_API_BASE_URL" in str(exc_info.value)



def test_settings_requires_admin_bearer_token(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ADMIN_API_BASE_URL", "http://127.0.0.1:8008")

    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=None)

    assert "ADMIN_BEARER_TOKEN" in str(exc_info.value)



def test_settings_uses_default_state_db_url(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ADMIN_API_BASE_URL", "http://127.0.0.1:8008")
    monkeypatch.setenv("ADMIN_BEARER_TOKEN", "test-admin-token")

    settings = Settings(_env_file=None)

    assert settings.scraper_state_db_url == DEFAULT_SCRAPER_STATE_DB_URL
    assert settings.request_timeout_seconds == DEFAULT_REQUEST_TIMEOUT_SECONDS
    assert settings.max_retries == DEFAULT_MAX_RETRIES
    assert settings.user_agent == DEFAULT_USER_AGENT



def test_settings_parses_timeout_and_retry_as_integers(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("ADMIN_API_BASE_URL", "http://127.0.0.1:8008")
    monkeypatch.setenv("ADMIN_BEARER_TOKEN", "test-admin-token")
    monkeypatch.setenv("REQUEST_TIMEOUT_SECONDS", "45")
    monkeypatch.setenv("MAX_RETRIES", "9")

    settings = Settings(_env_file=None)

    assert settings.request_timeout_seconds == 45
    assert isinstance(settings.request_timeout_seconds, int)
    assert settings.max_retries == 9
    assert isinstance(settings.max_retries, int)
