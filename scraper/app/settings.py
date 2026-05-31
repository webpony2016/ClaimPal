from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

DEFAULT_SCRAPER_STATE_DB_URL = "sqlite:///scraper_state.db"
DEFAULT_REQUEST_TIMEOUT_SECONDS = 20
DEFAULT_MAX_RETRIES = 3
DEFAULT_USER_AGENT = "ClaimPalScraper/0.1"


class Settings(BaseSettings):
    admin_api_base_url: str = Field(alias="ADMIN_API_BASE_URL")
    admin_bearer_token: str = Field(alias="ADMIN_BEARER_TOKEN")
    llm_api_key: str | None = Field(default=None, alias="LLM_API_KEY")
    scraper_state_db_url: str = Field(
        default=DEFAULT_SCRAPER_STATE_DB_URL,
        alias="SCRAPER_STATE_DB_URL",
    )
    request_timeout_seconds: int = Field(
        default=DEFAULT_REQUEST_TIMEOUT_SECONDS,
        alias="REQUEST_TIMEOUT_SECONDS",
        ge=1,
    )
    max_retries: int = Field(default=DEFAULT_MAX_RETRIES, alias="MAX_RETRIES", ge=0)
    user_agent: str = Field(default=DEFAULT_USER_AGENT, alias="USER_AGENT")

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
