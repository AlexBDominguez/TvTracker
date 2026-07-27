import httpx
import pytest
from fastapi.testclient import TestClient

from app.services import tmdb_client


def test_content_search_requires_auth(client: TestClient) -> None:
    response = client.get("/api/v1/content/search", params={"query": "test"})
    assert response.status_code == 401


def test_content_search_filters_to_tv_and_uses_camel_case(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    async def fake_search(query: str) -> dict:
        return {
            "results": [
                {
                    "id": 1396,
                    "media_type": "tv",
                    "name": "Breaking Bad",
                    "overview": "...",
                    "poster_path": "/poster.jpg",
                    "backdrop_path": "/backdrop.jpg",
                    "vote_average": 8.9,
                },
                {"id": 42, "media_type": "movie", "title": "A Movie"},
            ]
        }

    monkeypatch.setattr(tmdb_client, "search", fake_search)

    response = client.get(
        "/api/v1/content/search", params={"query": "breaking bad"}, headers=auth_headers
    )
    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0] == {
        "id": 1396,
        "name": "Breaking Bad",
        "posterPath": "/poster.jpg",
        "backdropPath": "/backdrop.jpg",
        "overview": "...",
        "voteAverage": 8.9,
        "numberOfSeasons": 0,
        "status": None,
    }


def test_content_popular_series(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    async def fake_get_popular_tv() -> dict:
        return {
            "results": [
                {
                    "id": 1396,
                    "name": "Breaking Bad",
                    "overview": "...",
                    "poster_path": "/poster.jpg",
                    "backdrop_path": None,
                    "vote_average": 8.9,
                }
            ]
        }

    monkeypatch.setattr(tmdb_client, "get_popular_tv", fake_get_popular_tv)

    response = client.get("/api/v1/content/popular/series", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0]["id"] == 1396
    assert body[0]["numberOfSeasons"] == 0


def test_content_series_detail_not_found(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    async def fake_get_tv_details(tmdb_id: int) -> dict:
        request = httpx.Request("GET", "https://api.themoviedb.org/3/tv/999999999")
        response = httpx.Response(404, request=request)
        raise httpx.HTTPStatusError("not found", request=request, response=response)

    monkeypatch.setattr(tmdb_client, "get_tv_details", fake_get_tv_details)

    response = client.get("/api/v1/content/series/999999999", headers=auth_headers)
    assert response.status_code == 404


def test_content_series_detail_success(
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
            "seasons": [{"season_number": 1}],
        }

    monkeypatch.setattr(tmdb_client, "get_tv_details", fake_get_tv_details)

    response = client.get("/api/v1/content/series/1396", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body["numberOfSeasons"] == 5
    assert body["status"] is None


def test_content_series_season(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    async def fake_get_season_details(tmdb_id: int, season_number: int) -> dict:
        return {
            "episodes": [
                {
                    "id": 62085,
                    "name": "Pilot",
                    "season_number": season_number,
                    "episode_number": 1,
                    "still_path": "/still.jpg",
                    "overview": "...",
                    "air_date": "2008-01-20",
                }
            ]
        }

    monkeypatch.setattr(tmdb_client, "get_season_details", fake_get_season_details)

    response = client.get("/api/v1/content/series/1396/season/1", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body == [
        {
            "id": 62085,
            "name": "Pilot",
            "seasonNumber": 1,
            "episodeNumber": 1,
            "stillPath": "/still.jpg",
            "overview": "...",
            "airDate": "2008-01-20",
            "seriesId": 1396,
        }
    ]
