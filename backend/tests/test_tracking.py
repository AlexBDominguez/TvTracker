import asyncio
from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient

from app.core.token_crypto import encrypt_token
from app.models.series_tracking import SeriesStatus, SeriesTracking
from app.models.trakt_credentials import TraktCredentials
from app.services import tmdb_client, trakt_client


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


def _add_tracking(client: TestClient, user_id: int, tmdb_id: int, status: SeriesStatus) -> None:
    async def _insert() -> None:
        async with client.session_factory() as session:  # type: ignore[attr-defined]
            session.add(SeriesTracking(user_id=user_id, tmdb_id=tmdb_id, status=status))
            await session.commit()

    asyncio.run(_insert())


def test_watch_requires_auth(client: TestClient) -> None:
    response = client.post("/api/v1/tracking/watch", json={"episode_id": 1})
    assert response.status_code == 401


def test_watch_body_validation_before_trakt_check(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    # No Trakt account connected, but the payload is also invalid - the 422
    # from the bad body should win, not the 400 from the missing connection.
    response = client.post("/api/v1/tracking/watch", json={}, headers=auth_headers)
    assert response.status_code == 422


def test_watch_and_unwatch(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    me = client.get("/api/v1/users/me", headers=auth_headers).json()
    _connect_fake_trakt_account(client, me["id"])

    captured = {}

    async def fake_add_to_history(access_token: str, payload: dict) -> dict:
        captured["add"] = payload
        return {"added": {"episodes": 1}}

    async def fake_remove_from_history(access_token: str, payload: dict) -> dict:
        captured["remove"] = payload
        return {"deleted": {"episodes": 1}}

    monkeypatch.setattr(trakt_client, "add_to_history", fake_add_to_history)
    monkeypatch.setattr(trakt_client, "remove_from_history", fake_remove_from_history)

    response = client.post(
        "/api/v1/tracking/watch", json={"episode_id": 62085}, headers=auth_headers
    )
    assert response.status_code == 201
    assert captured["add"] == {"episodes": [{"ids": {"tmdb": 62085}}]}

    response = client.post(
        "/api/v1/tracking/unwatch", json={"episode_id": 62085}, headers=auth_headers
    )
    assert response.status_code == 200
    assert captured["remove"] == {"episodes": [{"ids": {"tmdb": 62085}}]}


def test_last_watched_returns_null_when_no_history(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    me = client.get("/api/v1/users/me", headers=auth_headers).json()
    _connect_fake_trakt_account(client, me["id"])

    async def fake_get_history(access_token: str, media_type: str = "episodes", limit: int = 1):
        return []

    monkeypatch.setattr(trakt_client, "get_history", fake_get_history)

    response = client.get("/api/v1/tracking/last-watched", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() is None


def test_last_watched_maps_trakt_history(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    me = client.get("/api/v1/users/me", headers=auth_headers).json()
    _connect_fake_trakt_account(client, me["id"])

    async def fake_get_history(access_token: str, media_type: str = "episodes", limit: int = 1):
        return [
            {
                "episode": {
                    "season": 1,
                    "number": 1,
                    "title": "Pilot",
                    "ids": {"tmdb": 62085},
                },
                "show": {"ids": {"tmdb": 1396}},
            }
        ]

    monkeypatch.setattr(trakt_client, "get_history", fake_get_history)

    response = client.get("/api/v1/tracking/last-watched", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == 62085
    assert body["seasonNumber"] == 1
    assert body["episodeNumber"] == 1
    assert body["seriesId"] == 1396


def test_pending_episodes_filters_aired_and_unwatched(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    me = client.get("/api/v1/users/me", headers=auth_headers).json()
    _connect_fake_trakt_account(client, me["id"])
    _add_tracking(client, me["id"], 1396, SeriesStatus.WATCHING)

    async def fake_get_watched_shows(access_token: str) -> list[dict]:
        return [
            {
                "show": {"ids": {"tmdb": 1396}},
                "seasons": [{"number": 1, "episodes": [{"number": 1}]}],
            }
        ]

    async def fake_get_tv_details(tmdb_id: int) -> dict:
        return {"id": tmdb_id, "seasons": [{"season_number": 1}]}

    async def fake_get_season_details(tmdb_id: int, season_number: int) -> dict:
        return {
            "episodes": [
                {
                    "id": 1,
                    "name": "Pilot",
                    "episode_number": 1,
                    "air_date": "2008-01-20",
                },
                {
                    "id": 2,
                    "name": "Cat's in the Bag...",
                    "episode_number": 2,
                    "air_date": "2008-01-27",
                },
                {
                    "id": 3,
                    "name": "Unaired",
                    "episode_number": 3,
                    "air_date": "2099-01-01",
                },
            ]
        }

    monkeypatch.setattr(trakt_client, "get_watched_shows", fake_get_watched_shows)
    monkeypatch.setattr(tmdb_client, "get_tv_details", fake_get_tv_details)
    monkeypatch.setattr(tmdb_client, "get_season_details", fake_get_season_details)

    response = client.get("/api/v1/tracking/pending", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    # Episode 1 already watched, episode 3 hasn't aired yet - only episode 2 is pending.
    assert len(body) == 1
    assert body[0]["episodeNumber"] == 2
    assert body[0]["seriesId"] == 1396
