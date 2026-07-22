import asyncio

import pytest
from fastapi.testclient import TestClient

from app.models.series_tracking import SeriesStatus, SeriesTracking
from app.services import tmdb_client


def _add_tracking(client: TestClient, user_id: int, tmdb_id: int, status: SeriesStatus) -> None:
    async def _insert() -> None:
        async with client.session_factory() as session:  # type: ignore[attr-defined]
            session.add(SeriesTracking(user_id=user_id, tmdb_id=tmdb_id, status=status))
            await session.commit()

    asyncio.run(_insert())


def test_my_series_requires_auth(client: TestClient) -> None:
    response = client.get("/api/v1/library/my-series")
    assert response.status_code == 401


def test_my_series_empty_by_default(client: TestClient, auth_headers: dict[str, str]) -> None:
    response = client.get("/api/v1/library/my-series", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == []


def test_my_series_returns_tracked_shows(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    me = client.get("/api/v1/users/me", headers=auth_headers).json()
    _add_tracking(client, me["id"], 1396, SeriesStatus.WATCHING)

    async def fake_get_tv_details(tmdb_id: int) -> dict:
        return {
            "id": tmdb_id,
            "name": "Breaking Bad",
            "overview": "...",
            "poster_path": "/poster.jpg",
            "backdrop_path": "/backdrop.jpg",
            "vote_average": 8.9,
            "number_of_seasons": 5,
        }

    monkeypatch.setattr(tmdb_client, "get_tv_details", fake_get_tv_details)

    response = client.get("/api/v1/library/my-series", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0]["id"] == 1396
    assert body[0]["status"] == "watching"


def test_set_series_status_creates_tracking(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    async def fake_get_tv_details(tmdb_id: int) -> dict:
        return {
            "id": tmdb_id,
            "name": "Breaking Bad",
            "overview": "...",
            "poster_path": "/poster.jpg",
            "backdrop_path": "/backdrop.jpg",
            "vote_average": 8.9,
            "number_of_seasons": 5,
        }

    monkeypatch.setattr(tmdb_client, "get_tv_details", fake_get_tv_details)

    response = client.put(
        "/api/v1/library/series/1396/status",
        json={"status": "paused"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["status"] == "paused"

    # Setting it again updates the same row instead of duplicating it.
    response = client.put(
        "/api/v1/library/series/1396/status",
        json={"status": "dropped"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["status"] == "dropped"

    response = client.get("/api/v1/library/my-series", headers=auth_headers)
    assert len(response.json()) == 1
