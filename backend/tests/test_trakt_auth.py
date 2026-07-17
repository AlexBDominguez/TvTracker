from fastapi.testclient import TestClient


def test_connect_requires_auth(client: TestClient) -> None:
    response = client.get("/api/v1/auth/trakt/connect")
    assert response.status_code == 401


def test_connect_returns_authorize_url(client: TestClient, auth_headers: dict[str, str]) -> None:
    response = client.get("/api/v1/auth/trakt/connect", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["authorize_url"].startswith("https://trakt.tv/oauth/authorize")


def test_callback_invalid_state(client: TestClient) -> None:
    response = client.get(
        "/api/v1/auth/trakt/callback", params={"code": "whatever", "state": "garbage"}
    )
    assert response.status_code == 400


def test_status_not_connected(client: TestClient, auth_headers: dict[str, str]) -> None:
    response = client.get("/api/v1/auth/trakt/status", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == {"connected": False, "expires_at": None}
