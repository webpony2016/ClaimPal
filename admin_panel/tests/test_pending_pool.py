from __future__ import annotations

from datetime import datetime, timezone
from types import ModuleType
from typing import Any
from uuid import UUID, uuid4

import pytest
from fastapi.testclient import TestClient

from app.routes.admin import get_settlement_service
from app.schemas import PendingSettlementCreate, PendingSettlementUpdate
from app.services.settlements import SettlementService
from app.settings import Settings


AUTH_HEADERS = {"Authorization": "Bearer test-admin-token"}


class FakeSettlementService:
    def __init__(self) -> None:
        self.items: dict[UUID, dict[str, Any]] = {}
        self.next_created_day = 1

    def create_pending(self, payload: PendingSettlementCreate) -> tuple[dict[str, Any], int]:
        item_id = uuid4()
        item = self._item_from_payload(payload.model_dump(), item_id, self.next_created_day)
        self.items[item_id] = item
        self.next_created_day += 1
        return item, len(self.items)

    def get_next_pending(self) -> tuple[dict[str, Any] | None, int]:
        if not self.items:
            return None, 0

        oldest = min(self.items.values(), key=lambda item: item["created_at"])
        return oldest, len(self.items)

    def get_pending(self, pending_id: UUID) -> dict[str, Any] | None:
        return self.items.get(pending_id)

    def update_pending(
        self,
        pending_id: UUID,
        payload: PendingSettlementUpdate,
    ) -> tuple[dict[str, Any] | None, int]:
        item = self.items.get(pending_id)
        if item is None:
            return None, len(self.items)

        item.update(payload.model_dump(exclude_unset=True))
        return item, len(self.items)

    @staticmethod
    def _item_from_payload(
        payload: dict[str, Any],
        item_id: UUID,
        created_day: int,
    ) -> dict[str, Any]:
        return {
            "id": item_id,
            "source_url": payload.get("source_url"),
            "raw_content": payload["raw_content"],
            "raw_content_type": payload.get("raw_content_type", "text"),
            "brand_name": payload["brand_name"],
            "max_payout": payload.get("max_payout"),
            "country": payload["country"],
            "proof_required": payload.get("proof_required", False),
            "deadline": payload.get("deadline"),
            "eligibility_text": payload.get("eligibility_text"),
            "ai_payload": payload.get("ai_payload", {}),
            "scraper_payload": payload.get("scraper_payload", {}),
            "created_at": datetime(2026, 1, created_day, tzinfo=timezone.utc),
        }


@pytest.fixture()
def fake_service(client: TestClient) -> FakeSettlementService:
    service = FakeSettlementService()
    client.app.dependency_overrides[get_settlement_service] = lambda: service
    return service


def test_scraped_pool_creates_item(
    client: TestClient,
    fake_service: FakeSettlementService,
) -> None:
    response = client.post(
        "/api/admin/scraped-pool",
        headers=AUTH_HEADERS,
        json={
            "source_url": "https://example.com/apple-settlement",
            "raw_content": "<p>Apple settlement details</p>",
            "raw_content_type": "html",
            "brand_name": "Apple",
            "max_payout": "25.50",
            "country": "US",
            "proof_required": True,
            "ai_payload": {"confidence": 0.97},
            "scraper_payload": {"selector": "article"},
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["count"] == 1
    assert body["item"]["brand_name"] == "Apple"
    assert body["item"]["source_url"] == "https://example.com/apple-settlement"
    created_id = UUID(body["item"]["id"])
    assert fake_service.items[created_id]["brand_name"] == "Apple"


def test_pending_returns_count_and_oldest_item(
    client: TestClient,
    fake_service: FakeSettlementService,
) -> None:
    newer, _ = fake_service.create_pending(
        PendingSettlementCreate(raw_content="new", brand_name="New", country="US")
    )
    oldest, _ = fake_service.create_pending(
        PendingSettlementCreate(raw_content="old", brand_name="Old", country="CA")
    )
    newer["created_at"] = datetime(2026, 1, 3, tzinfo=timezone.utc)
    oldest["created_at"] = datetime(2026, 1, 2, tzinfo=timezone.utc)

    response = client.get("/api/admin/pending", headers=AUTH_HEADERS)

    assert response.status_code == 200
    assert response.json()["count"] == 2
    assert response.json()["item"]["brand_name"] == "Old"


def test_get_pending_by_id_returns_item(
    client: TestClient,
    fake_service: FakeSettlementService,
) -> None:
    item, _ = fake_service.create_pending(
        PendingSettlementCreate(raw_content="details", brand_name="Apple", country="US")
    )

    response = client.get(f"/api/admin/pending/{item['id']}", headers=AUTH_HEADERS)

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == str(item["id"])
    assert body["brand_name"] == "Apple"


def test_get_pending_by_id_returns_404_for_missing_id(
    client: TestClient,
    fake_service: FakeSettlementService,
) -> None:
    response = client.get(f"/api/admin/pending/{uuid4()}", headers=AUTH_HEADERS)

    assert response.status_code == 404
    assert response.json() == {"detail": "Pending settlement not found"}


def test_patch_pending_updates_reviewer_fields(
    client: TestClient,
    fake_service: FakeSettlementService,
) -> None:
    item, _ = fake_service.create_pending(
        PendingSettlementCreate(raw_content="details", brand_name="Apple", country="US")
    )

    response = client.patch(
        f"/api/admin/pending/{item['id']}",
        headers=AUTH_HEADERS,
        json={
            "brand_name": "Apple Inc.",
            "max_payout": "99.99",
            "country": "CA",
            "eligibility_text": "Canadian claimants only",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["count"] == 1
    assert body["item"]["brand_name"] == "Apple Inc."
    assert body["item"]["max_payout"] == "99.99"
    assert body["item"]["country"] == "CA"
    assert body["item"]["eligibility_text"] == "Canadian claimants only"


def test_patch_pending_returns_404_for_missing_id(
    client: TestClient,
    fake_service: FakeSettlementService,
) -> None:
    response = client.patch(
        f"/api/admin/pending/{uuid4()}",
        headers=AUTH_HEADERS,
        json={"brand_name": "Missing"},
    )

    assert response.status_code == 404
    assert response.json() == {"detail": "Pending settlement not found"}


@pytest.mark.parametrize(
    ("payload", "missing_or_invalid_field"),
    [
        ({"brand_name": "Apple", "country": "US"}, "raw_content"),
        ({"raw_content": "details", "brand_name": "Apple", "country": "GB"}, "country"),
    ],
)
def test_scraped_pool_rejects_invalid_payload(
    client: TestClient,
    fake_service: FakeSettlementService,
    payload: dict[str, Any],
    missing_or_invalid_field: str,
) -> None:
    response = client.post(
        "/api/admin/scraped-pool",
        headers=AUTH_HEADERS,
        json=payload,
    )

    assert response.status_code == 422
    assert any(
        error["loc"][-1] == missing_or_invalid_field
        for error in response.json()["detail"]
    )


def test_scraped_pool_rejects_negative_max_payout(
    client: TestClient,
    fake_service: FakeSettlementService,
) -> None:
    response = client.post(
        "/api/admin/scraped-pool",
        headers=AUTH_HEADERS,
        json={
            "raw_content": "details",
            "brand_name": "Apple",
            "max_payout": "-0.01",
            "country": "US",
        },
    )

    assert response.status_code == 422
    assert any(error["loc"][-1] == "max_payout" for error in response.json()["detail"])


def test_patch_pending_rejects_negative_max_payout(
    client: TestClient,
    fake_service: FakeSettlementService,
) -> None:
    item, _ = fake_service.create_pending(
        PendingSettlementCreate(raw_content="details", brand_name="Apple", country="US")
    )

    response = client.patch(
        f"/api/admin/pending/{item['id']}",
        headers=AUTH_HEADERS,
        json={"max_payout": "-0.01"},
    )

    assert response.status_code == 422
    assert any(error["loc"][-1] == "max_payout" for error in response.json()["detail"])


def test_patch_pending_rejects_explicit_null_for_non_nullable_field(
    client: TestClient,
    fake_service: FakeSettlementService,
) -> None:
    item, _ = fake_service.create_pending(
        PendingSettlementCreate(raw_content="details", brand_name="Apple", country="US")
    )

    response = client.patch(
        f"/api/admin/pending/{item['id']}",
        headers=AUTH_HEADERS,
        json={"brand_name": None},
    )

    assert response.status_code == 422
    assert any(error["loc"][-1] == "brand_name" for error in response.json()["detail"])


def test_patch_pending_accepts_explicit_null_for_nullable_field(
    client: TestClient,
    fake_service: FakeSettlementService,
) -> None:
    item, _ = fake_service.create_pending(
        PendingSettlementCreate(raw_content="details", brand_name="Apple", country="US")
    )

    response = client.patch(
        f"/api/admin/pending/{item['id']}",
        headers=AUTH_HEADERS,
        json={"eligibility_text": None},
    )

    assert response.status_code == 200
    assert response.json()["item"]["eligibility_text"] is None


class FakeJsonb:
    def __init__(self, value: Any) -> None:
        self.value = value


class FakeCursor:
    def __init__(self, row: dict[str, Any]) -> None:
        self.row = row

    def fetchone(self) -> dict[str, Any]:
        return self.row


class FakeConnection:
    def __init__(self, rows: list[dict[str, Any]]) -> None:
        self.rows = rows
        self.calls: list[tuple[str, dict[str, Any] | None]] = []
        self.committed = False

    def execute(
        self,
        query: str,
        params: dict[str, Any] | None = None,
    ) -> FakeCursor:
        self.calls.append((query, params))
        return FakeCursor(self.rows.pop(0))

    def commit(self) -> None:
        self.committed = True


class FakeOpenConnection:
    def __init__(self, connection: FakeConnection) -> None:
        self.connection = connection

    def __enter__(self) -> FakeConnection:
        return self.connection

    def __exit__(self, *args: object) -> None:
        return None


@pytest.fixture()
def fake_jsonb_modules(monkeypatch: pytest.MonkeyPatch) -> None:
    psycopg_module = ModuleType("psycopg")
    types_module = ModuleType("psycopg.types")
    json_module = ModuleType("psycopg.types.json")
    json_module.Jsonb = FakeJsonb  # type: ignore[attr-defined]

    monkeypatch.setitem(__import__("sys").modules, "psycopg", psycopg_module)
    monkeypatch.setitem(__import__("sys").modules, "psycopg.types", types_module)
    monkeypatch.setitem(__import__("sys").modules, "psycopg.types.json", json_module)


def service_item(item_id: UUID) -> dict[str, Any]:
    return {
        "id": item_id,
        "source_url": None,
        "raw_content": "details",
        "raw_content_type": "text",
        "brand_name": "Apple",
        "max_payout": None,
        "country": "US",
        "proof_required": False,
        "deadline": None,
        "eligibility_text": None,
        "ai_payload": {},
        "scraper_payload": {},
        "created_at": datetime(2026, 1, 1, tzinfo=timezone.utc),
    }


def test_service_update_uses_uuid_id_allowlisted_params_and_jsonb(
    monkeypatch: pytest.MonkeyPatch,
    fake_jsonb_modules: None,
) -> None:
    item_id = uuid4()
    connection = FakeConnection([service_item(item_id), {"count": 1}])
    monkeypatch.setattr(
        "app.services.settlements.open_connection",
        lambda settings: FakeOpenConnection(connection),
    )
    service = SettlementService(
        Settings(admin_bearer_token="token", database_url="postgresql://db")
    )

    item, count = service.update_pending(
        item_id,
        PendingSettlementUpdate(
            brand_name="Apple Inc.",
            ai_payload={"confidence": 0.9},
            scraper_payload={"selector": "article"},
        ),
    )

    update_query, update_params = connection.calls[0]
    assert item == service_item(item_id)
    assert count == 1
    assert connection.committed is True
    assert '"brand_name" = %(brand_name)s' in update_query
    assert '"ai_payload" = %(ai_payload)s' in update_query
    assert "reviewed_at" not in update_query
    assert set(update_params or {}) == {"id", "brand_name", "ai_payload", "scraper_payload"}
    assert update_params is not None
    assert update_params["id"] == item_id
    assert isinstance(update_params["ai_payload"], FakeJsonb)
    assert update_params["ai_payload"].value == {"confidence": 0.9}


def test_service_empty_update_delegates_to_get_pending(
    monkeypatch: pytest.MonkeyPatch,
    fake_jsonb_modules: None,
) -> None:
    item_id = uuid4()
    service = SettlementService(
        Settings(admin_bearer_token="token", database_url="postgresql://db")
    )
    called_with: list[UUID] = []

    def fake_get_pending(pending_id: UUID) -> dict[str, Any]:
        called_with.append(pending_id)
        return service_item(pending_id)

    connection = FakeConnection([{"count": 1}])
    monkeypatch.setattr(service, "get_pending", fake_get_pending)
    monkeypatch.setattr(
        "app.services.settlements.open_connection",
        lambda settings: FakeOpenConnection(connection),
    )

    item, count = service.update_pending(item_id, PendingSettlementUpdate())

    assert called_with == [item_id]
    assert item == service_item(item_id)
    assert count == 1
