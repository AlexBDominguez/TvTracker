from fastapi.testclient import TestClient


def test_me_requires_auth(client: TestClient) -> None:
    response = client.get("/api/v1/users/me")
    assert response.status_code == 401


def test_me_returns_camel_case_user(client: TestClient, auth_headers: dict[str, str]) -> None:
    response = client.get("/api/v1/users/me", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert set(body.keys()) == {"id", "email", "name"}
    assert body["name"]
