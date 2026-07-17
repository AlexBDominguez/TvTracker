import httpx
import pytest
from fastapi.testclient import TestClient

from app.services import tmdb_client


def test_search_requires_auth(client: TestClient) -> None:
    response = client.get("/api/v1/search", params={"query": "test"})
    assert response.status_code == 401


def test_search_success(
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
                    "first_air_date": "2008-01-20",
                },
                {"id": 1, "media_type": "person", "name": "Someone"},
            ]
        }

    monkeypatch.setattr(tmdb_client, "search", fake_search)

    response = client.get(
        "/api/v1/search", params={"query": "breaking bad"}, headers=auth_headers
    )
    assert response.status_code == 200
    body = response.json()
    assert len(body["results"]) == 1
    assert body["results"][0]["tmdb_id"] == 1396
    assert body["results"][0]["poster_url"] == "https://image.tmdb.org/t/p/w500/poster.jpg"


def test_show_not_found(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    async def fake_get_tv_details(tmdb_id: int) -> dict:
        request = httpx.Request("GET", "https://api.themoviedb.org/3/tv/999999999")
        response = httpx.Response(404, request=request)
        raise httpx.HTTPStatusError("not found", request=request, response=response)

    monkeypatch.setattr(tmdb_client, "get_tv_details", fake_get_tv_details)

    response = client.get("/api/v1/shows/999999999", headers=auth_headers)
    assert response.status_code == 404


def test_show_external_failure(
    client: TestClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
) -> None:
    async def fake_get_tv_details(tmdb_id: int) -> dict:
        raise httpx.ConnectError("boom")

    monkeypatch.setattr(tmdb_client, "get_tv_details", fake_get_tv_details)

    response = client.get("/api/v1/shows/1396", headers=auth_headers)
    assert response.status_code == 503
    assert response.json()["error"] == "Servicio externo no disponible"
