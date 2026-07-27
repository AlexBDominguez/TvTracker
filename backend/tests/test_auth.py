from fastapi.testclient import TestClient


def test_register_and_login(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/register",
        json={"username": "alice", "email": "alice@example.com", "password": "supersecret1"},
    )
    assert response.status_code == 201
    assert response.json()["username"] == "alice"

    response = client.post(
        "/api/v1/auth/login", json={"username": "alice", "password": "supersecret1"}
    )
    assert response.status_code == 200
    assert "access_token" in response.json()


def test_register_duplicate_username(client: TestClient) -> None:
    payload = {"username": "bob", "email": "bob@example.com", "password": "supersecret1"}
    client.post("/api/v1/auth/register", json=payload)
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 409
    assert response.json() == {"error": "Username or email already registered", "code": 409}


def test_login_wrong_password(client: TestClient) -> None:
    client.post(
        "/api/v1/auth/register",
        json={"username": "carol", "email": "carol@example.com", "password": "supersecret1"},
    )
    response = client.post("/api/v1/auth/login", json={"username": "carol", "password": "wrong"})
    assert response.status_code == 401
    assert response.json()["error"] == "Incorrect username or password"


def test_me_requires_auth(client: TestClient) -> None:
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401


def test_me_with_token(client: TestClient, auth_headers: dict[str, str]) -> None:
    response = client.get("/api/v1/auth/me", headers=auth_headers)
    assert response.status_code == 200
    assert "username" in response.json()
