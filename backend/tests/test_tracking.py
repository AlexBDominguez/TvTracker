import asyncio

import pytest
from fastapi.testclient import TestClient

from app.models.series_tracking import SeriesStatus, SeriesTracking
from app.models.watched_episode import WatchedEpisode
from app.services import tmdb_client

SHOW_TMDB_ID = 1396
EPISODE_PAYLOAD = {
    "episode_id": 62085,
    "series_id": SHOW_TMDB_ID,
    "season_number": 1,
    "episode_number": 1,
}


def _add_tracking(client: TestClient, user_id: int, tmdb_id: int, status: SeriesStatus) -> None:
    async def _insert() -> None:
        async with client.session_factory() as session:  # type: ignore[attr-defined]
            session.add(SeriesTracking(user_id=user_id, tmdb_id=tmdb_id, status=status))
            await session.commit()

    asyncio.run(_insert())


def _add_watched_episode(
    client: TestClient,
    user_id: int,
    series_tmdb_id: int,
    season_number: int,
    episode_number: int,
    episode_tmdb_id: int = 1,
) -> None:
    async def _insert() -> None:
        async with client.session_factory() as session:  # type: ignore[attr-defined]
            session.add(
                WatchedEpisode(
                    user_id=user_id,
                    series_tmdb_id=series_tmdb_id,
                    season_number=season_number,
                    episode_number=episode_number,
                    episode_tmdb_id=episode_tmdb_id,
                )
            )
            await session.commit()

    asyncio.run(_insert())


def test_watch_requires_auth(client: TestClient) -> None:
    response = client.post("/api/v1/tracking/watch", json=EPISODE_PAYLOAD)
    assert response.status_code == 401


def test_watch_body_validation(client: TestClient, auth_headers: dict[str, str]) -> None:
    response = client.post("/api/v1/tracking/watch", json={}, headers=auth_headers)
    assert response.status_code == 422


def test_watch_and_unwatch(client: TestClient, auth_headers: dict[str, str]) -> None:
    response = client.post(
        "/api/v1/tracking/watch", json=EPISODE_PAYLOAD, headers=auth_headers
    )
    assert response.status_code == 201
    assert response.json() == {"status": "added"}

    # Re-marking the same episode is idempotent, not a duplicate/error.
    response = client.post(
        "/api/v1/tracking/watch", json=EPISODE_PAYLOAD, headers=auth_headers
    )
    assert response.status_code == 201

    response = client.post(
        "/api/v1/tracking/unwatch", json=EPISODE_PAYLOAD, headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json() == {"status": "removed"}


def test_last_watched_returns_null_when_no_history(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    response = client.get("/api/v1/tracking/last-watched", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() is None


def test_last_watched_maps_watched_episode(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    me = client.get("/api/v1/users/me", headers=auth_headers).json()
    _add_watched_episode(client, me["id"], SHOW_TMDB_ID, 1, 1, episode_tmdb_id=62085)

    async def fake_get_season_details(tmdb_id: int, season_number: int) -> dict:
        return {
            "episodes": [
                {
                    "id": 62085,
                    "name": "Pilot",
                    "episode_number": 1,
                    "air_date": "2008-01-20",
                }
            ]
        }

    monkeypatch.setattr(tmdb_client, "get_season_details", fake_get_season_details)

    response = client.get("/api/v1/tracking/last-watched", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == 62085
    assert body["seasonNumber"] == 1
    assert body["episodeNumber"] == 1
    assert body["seriesId"] == SHOW_TMDB_ID


def test_pending_episodes_filters_aired_and_unwatched(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    me = client.get("/api/v1/users/me", headers=auth_headers).json()
    _add_tracking(client, me["id"], SHOW_TMDB_ID, SeriesStatus.WATCHING)
    _add_watched_episode(client, me["id"], SHOW_TMDB_ID, 1, 1)

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

    monkeypatch.setattr(tmdb_client, "get_tv_details", fake_get_tv_details)
    monkeypatch.setattr(tmdb_client, "get_season_details", fake_get_season_details)

    response = client.get("/api/v1/tracking/pending", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    # Episode 1 already watched, episode 3 hasn't aired yet - only episode 2 is pending.
    assert len(body) == 1
    assert body[0]["episodeNumber"] == 2
    assert body[0]["seriesId"] == SHOW_TMDB_ID
