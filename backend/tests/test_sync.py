import asyncio
from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient

from app.core.token_crypto import encrypt_token
from app.models.trakt_credentials import TraktCredentials
from app.services import trakt_client


def test_watchlist_requires_auth(client: TestClient) -> None:
    response = client.get("/api/v1/sync/watchlist")
    assert response.status_code == 401


def test_watchlist_without_trakt_connected(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    response = client.get("/api/v1/sync/watchlist", headers=auth_headers)
    assert response.status_code == 400
    assert response.json()["error"] == "Trakt account not connected"


def test_history_validation_error(client: TestClient, auth_headers: dict[str, str]) -> None:
    response = client.post(
        "/api/v1/sync/history",
        json={"media_type": "episode", "tmdb_id": 1396},
        headers=auth_headers,
    )
    assert response.status_code == 422


def _connect_fake_trakt_account(client: TestClient, user_id: int) -> None:
    async def _insert() -> None:
        async with client.session_factory() as session:  # type: ignore[attr-defined]
            session.add(
                TraktCredentials(
                    user_id=user_id,
                    access_token=encrypt_token("fake-access"),
                    refresh_token=encrypt_token("fake-refresh"),
                    expires_at=datetime.now(timezone.utc) + timedelta(days=1),
                )
            )
            await session.commit()

    asyncio.run(_insert())


def test_add_and_remove_history(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    me = client.get("/api/v1/auth/me", headers=auth_headers).json()
    _connect_fake_trakt_account(client, me["id"])

    async def fake_add_to_history(access_token: str, payload: dict) -> dict:
        return {"added": {"episodes": 1}}

    async def fake_remove_from_history(access_token: str, payload: dict) -> dict:
        return {"deleted": {"episodes": 1}}

    monkeypatch.setattr(trakt_client, "add_to_history", fake_add_to_history)
    monkeypatch.setattr(trakt_client, "remove_from_history", fake_remove_from_history)

    response = client.post(
        "/api/v1/sync/history",
        json={
            "media_type": "episode",
            "tmdb_id": 1396,
            "season_number": 1,
            "episode_number": 1,
        },
        headers=auth_headers,
    )
    assert response.status_code == 201
    assert response.json()["status"] == "added"

    response = client.request(
        "DELETE",
        "/api/v1/sync/history",
        json={
            "media_type": "episode",
            "tmdb_id": 1396,
            "season_number": 1,
            "episode_number": 1,
        },
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["status"] == "removed"


def test_watchlist_success(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    me = client.get("/api/v1/auth/me", headers=auth_headers).json()
    _connect_fake_trakt_account(client, me["id"])

    async def fake_get_watchlist(access_token: str) -> list[dict]:
        return [
            {
                "listed_at": "2014-09-01T09:10:11.000Z",
                "type": "show",
                "show": {"title": "Breaking Bad", "ids": {"tmdb": 1396}},
            }
        ]

    monkeypatch.setattr(trakt_client, "get_watchlist", fake_get_watchlist)

    response = client.get("/api/v1/sync/watchlist", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body == [
        {
            "media_type": "show",
            "tmdb_id": 1396,
            "title": "Breaking Bad",
            "listed_at": "2014-09-01T09:10:11.000Z",
        }
    ]
