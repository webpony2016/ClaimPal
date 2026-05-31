from __future__ import annotations

from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Any
from uuid import UUID, uuid4

import pytest
from fastapi.testclient import TestClient

from app.routes.admin import get_settlement_service
from app.schemas import SettlementApprovalPayload
from app.services.settlements import SettlementService
from app.settings import Settings


AUTH_HEADERS = {"Authorization": "Bearer test-admin-token"}


def pending_item(item_id: UUID | None = None, brand_name: str = "Apple") -> dict[str, Any]:
    return {
        "id": item_id or uuid4(),
        "source_url": None,
        "raw_content": "details",
        "raw_content_type": "text",
        "brand_name": brand_name,
        "max_payout": Decimal("25.50"),
        "country": "US",
        "proof_required": False,
        "deadline": date(2026, 6, 1),
        "eligibility_text": "Eligible customers",
        "ai_payload": {},
        "scraper_payload": {},
        "created_at": datetime(2026, 1, 1, tzinfo=timezone.utc),
    }


class FakeApprovalService:
    def __init__(self) -> None:
        self.approve_result: tuple[dict[str, Any] | None, int, int | None] = (
            None,
            0,
            103,
        )
        self.reject_result: tuple[dict[str, Any] | None, int, bool] = (None, 0, True)
        self.approved_id: UUID | None = None
        self.approved_payload: SettlementApprovalPayload | None = None
        self.rejected_id: UUID | None = None

    def approve_pending(
        self,
        item_id: UUID,
        payload: SettlementApprovalPayload,
    ) -> tuple[dict[str, Any] | None, int, int | None]:
        self.approved_id = item_id
        self.approved_payload = payload
        return self.approve_result

    def reject_pending(self, item_id: UUID) -> tuple[dict[str, Any] | None, int, bool]:
        self.rejected_id = item_id
        return self.reject_result


@pytest.fixture()
def approval_service(client: TestClient) -> FakeApprovalService:
    service = FakeApprovalService()
    client.app.dependency_overrides[get_settlement_service] = lambda: service
    return service


def test_approve_publishes_and_returns_next_null_count_and_data_version(
    client: TestClient,
    approval_service: FakeApprovalService,
) -> None:
    item_id = uuid4()
    approval_service.approve_result = (None, 0, 103)

    response = client.post(
        f"/api/admin/approve/{item_id}",
        headers=AUTH_HEADERS,
        json={"brand_name": "Apple", "country": "US"},
    )

    assert response.status_code == 200
    assert response.json() == {"item": None, "count": 0, "data_version": 103}


def test_approve_uses_uuid_id_and_final_form_values(
    client: TestClient,
    approval_service: FakeApprovalService,
) -> None:
    item_id = uuid4()
    next_item = pending_item(brand_name="Next")
    approval_service.approve_result = (next_item, 1, 103)

    response = client.post(
        f"/api/admin/approve/{item_id}",
        headers=AUTH_HEADERS,
        json={
            "brand_name": "Apple Inc.",
            "max_payout": "99.99",
            "country": "CA",
            "proof_required": True,
            "deadline": "2026-08-15",
            "eligibility_text": "Canadian claimants only",
        },
    )

    assert response.status_code == 200
    assert approval_service.approved_id == item_id
    assert approval_service.approved_payload is not None
    assert approval_service.approved_payload.brand_name == "Apple Inc."
    assert approval_service.approved_payload.max_payout == Decimal("99.99")
    assert approval_service.approved_payload.country == "CA"
    assert approval_service.approved_payload.proof_required is True
    assert approval_service.approved_payload.deadline == date(2026, 8, 15)
    assert approval_service.approved_payload.eligibility_text == "Canadian claimants only"
    assert response.json()["count"] == 1
    assert response.json()["item"]["brand_name"] == "Next"
    assert response.json()["data_version"] == 103


def test_approve_missing_id_returns_404(
    client: TestClient,
    approval_service: FakeApprovalService,
) -> None:
    approval_service.approve_result = (None, 2, None)

    response = client.post(
        f"/api/admin/approve/{uuid4()}",
        headers=AUTH_HEADERS,
        json={"brand_name": "Missing", "country": "US"},
    )

    assert response.status_code == 404
    assert response.json() == {"detail": "Pending settlement not found"}


def test_reject_deletes_pending_and_returns_next_null_and_count(
    client: TestClient,
    approval_service: FakeApprovalService,
) -> None:
    item_id = uuid4()
    approval_service.reject_result = (None, 0, True)

    response = client.post(f"/api/admin/reject/{item_id}", headers=AUTH_HEADERS)

    assert response.status_code == 200
    assert approval_service.rejected_id == item_id
    assert response.json() == {"item": None, "count": 0}


def test_reject_missing_id_returns_404(
    client: TestClient,
    approval_service: FakeApprovalService,
) -> None:
    approval_service.reject_result = (None, 2, False)

    response = client.post(f"/api/admin/reject/{uuid4()}", headers=AUTH_HEADERS)

    assert response.status_code == 404
    assert response.json() == {"detail": "Pending settlement not found"}


@pytest.mark.parametrize(
    "payload",
    [
        {"brand_name": "Apple", "max_payout": "-0.01", "country": "US"},
        {"brand_name": "Apple", "country": "GB"},
    ],
)
def test_approval_validation_rejects_invalid_payload(
    client: TestClient,
    approval_service: FakeApprovalService,
    payload: dict[str, Any],
) -> None:
    response = client.post(
        f"/api/admin/approve/{uuid4()}",
        headers=AUTH_HEADERS,
        json=payload,
    )

    assert response.status_code == 422


class FakeCursor:
    def __init__(self, row: dict[str, Any] | None = None, rowcount: int = 0) -> None:
        self.row = row
        self.rowcount = rowcount

    def fetchone(self) -> dict[str, Any] | None:
        return self.row


class FakeConnection:
    def __init__(self, results: list[FakeCursor]) -> None:
        self.results = results
        self.calls: list[tuple[str, dict[str, Any] | None]] = []
        self.committed = False

    def execute(
        self,
        query: str,
        params: dict[str, Any] | None = None,
    ) -> FakeCursor:
        self.calls.append((query, params))
        return self.results.pop(0)

    def commit(self) -> None:
        self.committed = True


class FakeOpenConnection:
    def __init__(self, connection: FakeConnection) -> None:
        self.connection = connection

    def __enter__(self) -> FakeConnection:
        return self.connection

    def __exit__(self, *args: object) -> None:
        return None


def service() -> SettlementService:
    return SettlementService(
        Settings(admin_bearer_token="token", database_url="postgresql://db")
    )


def test_service_approve_locks_inserts_updates_meta_deletes_and_returns_version(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    item_id = uuid4()
    next_item = pending_item(brand_name="Next")
    connection = FakeConnection(
        [
            FakeCursor(pending_item(item_id)),
            FakeCursor({"version_id": 103}),
            FakeCursor(),
            FakeCursor(rowcount=1),
            FakeCursor(next_item),
            FakeCursor({"count": 1}),
        ]
    )
    monkeypatch.setattr(
        "app.services.settlements.open_connection",
        lambda settings: FakeOpenConnection(connection),
    )

    next_pending, count, data_version = service().approve_pending(
        item_id,
        SettlementApprovalPayload(
            brand_name="Apple Inc.",
            max_payout=Decimal("25.50"),
            country="US",
            proof_required=True,
            deadline=date(2026, 8, 15),
            eligibility_text="Eligible customers",
        ),
    )

    assert next_pending == next_item
    assert count == 1
    assert data_version == 103
    assert connection.committed is True
    lock_query, lock_params = connection.calls[0]
    assert "FOR UPDATE" in lock_query.upper()
    assert "public.pending_settlements" in lock_query
    assert lock_params == {"id": item_id}
    insert_query, insert_params = connection.calls[1]
    assert "INSERT INTO public.settlements" in insert_query
    assert "version_id" in insert_query
    assert insert_params is not None
    assert insert_params["brand_name"] == "Apple Inc."
    assert insert_params["max_payout"] == Decimal("25.50")
    assert insert_params["country"] == "US"
    assert insert_params["proof_required"] is True
    assert insert_params["eligibility_text"] == "Eligible customers"
    update_query, update_params = connection.calls[2]
    assert "UPDATE public.global_meta" in update_query
    assert "SET value = to_jsonb(%(data_version)s::bigint)" in update_query
    assert "WHERE key = 'data_version'" in update_query
    assert update_params == {"data_version": 103}
    delete_query, delete_params = connection.calls[3]
    assert "DELETE FROM public.pending_settlements" in delete_query
    assert delete_params == {"id": item_id}


def test_service_approval_converts_date_to_utc_end_of_day(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    item_id = uuid4()
    connection = FakeConnection(
        [
            FakeCursor(pending_item(item_id)),
            FakeCursor({"version_id": 103}),
            FakeCursor(),
            FakeCursor(rowcount=1),
            FakeCursor(None),
            FakeCursor({"count": 0}),
        ]
    )
    monkeypatch.setattr(
        "app.services.settlements.open_connection",
        lambda settings: FakeOpenConnection(connection),
    )

    service().approve_pending(
        item_id,
        SettlementApprovalPayload(
            brand_name="Apple",
            country="US",
            deadline=date(2026, 8, 15),
        ),
    )

    insert_params = connection.calls[1][1]
    assert insert_params is not None
    assert insert_params["deadline"] == datetime(
        2026,
        8,
        15,
        23,
        59,
        59,
        999999,
        tzinfo=timezone.utc,
    )


def test_service_approve_missing_pending_does_not_insert_delete_or_return_version(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    item_id = uuid4()
    connection = FakeConnection([FakeCursor(None), FakeCursor({"count": 2})])
    monkeypatch.setattr(
        "app.services.settlements.open_connection",
        lambda settings: FakeOpenConnection(connection),
    )

    next_pending, count, data_version = service().approve_pending(
        item_id,
        SettlementApprovalPayload(brand_name="Missing", country="US"),
    )

    assert next_pending is None
    assert count == 2
    assert data_version is None
    assert connection.committed is True
    assert len(connection.calls) == 2
    assert all("INSERT INTO public.settlements" not in call[0] for call in connection.calls)
    assert all("DELETE FROM public.pending_settlements" not in call[0] for call in connection.calls)


def test_service_reject_missing_returns_deleted_false(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    item_id = uuid4()
    connection = FakeConnection([FakeCursor(rowcount=0), FakeCursor({"count": 2})])
    monkeypatch.setattr(
        "app.services.settlements.open_connection",
        lambda settings: FakeOpenConnection(connection),
    )

    next_pending, count, deleted = service().reject_pending(item_id)

    assert next_pending is None
    assert count == 2
    assert deleted is False
    assert connection.committed is True
    delete_query, delete_params = connection.calls[0]
    assert "DELETE FROM public.pending_settlements" in delete_query
    assert delete_params == {"id": item_id}
