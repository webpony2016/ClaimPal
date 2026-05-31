import pytest

from app.settings import get_settings

SCRAPER_ENV_VARS = (
    "ADMIN_API_BASE_URL",
    "ADMIN_BEARER_TOKEN",
    "LLM_API_KEY",
    "SCRAPER_STATE_DB_URL",
    "REQUEST_TIMEOUT_SECONDS",
    "MAX_RETRIES",
    "USER_AGENT",
)


@pytest.fixture(autouse=True)
def clear_scraper_settings(monkeypatch: pytest.MonkeyPatch):
    for key in SCRAPER_ENV_VARS:
        monkeypatch.delenv(key, raising=False)

    get_settings.cache_clear()
    yield
    get_settings.cache_clear()
