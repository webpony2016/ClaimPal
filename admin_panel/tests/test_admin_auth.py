from fastapi.testclient import TestClient

from app.main import create_app
from app.routes.admin import get_settlement_service


class EmptyPendingService:
    def get_next_pending(self) -> tuple[None, int]:
        return None, 0


def test_admin_api_requires_bearer_token(client: TestClient) -> None:
    response = client.get("/api/admin/pending")

    assert response.status_code == 401
    assert response.json() == {"detail": "Missing admin bearer token"}


def test_admin_api_rejects_invalid_bearer_token(client: TestClient) -> None:
    response = client.get(
        "/api/admin/pending",
        headers={"Authorization": "Bearer wrong-token"},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Invalid admin bearer token"}


def test_admin_api_accepts_valid_bearer_token(client: TestClient) -> None:
    client.app.dependency_overrides[get_settlement_service] = EmptyPendingService

    response = client.get(
        "/api/admin/pending",
        headers={"Authorization": "Bearer test-admin-token"},
    )

    assert response.status_code == 200
    assert response.json() == {"count": 0, "item": None}


def test_admin_api_rejects_non_bearer_authorization(client: TestClient) -> None:
    response = client.get(
        "/api/admin/pending",
        headers={"Authorization": "Basic test-admin-token"},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Missing admin bearer token"}


def test_admin_api_rejects_bearer_token_with_trailing_space(client: TestClient) -> None:
    response = client.get(
        "/api/admin/pending",
        headers={"Authorization": "Bearer test-admin-token "},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Invalid admin bearer token"}


def test_create_app_uses_paths_relative_to_package(monkeypatch: object) -> None:
    monkeypatch.chdir("C:/tmp")
    app = create_app()

    with TestClient(app) as test_client:
        response = test_client.get("/")

    assert response.status_code == 200
    assert "ClaimPal Operations Review" in response.text
