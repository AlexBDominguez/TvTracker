import httpx

from app.core.config import get_settings

settings = get_settings()

TMDB_IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500"


def image_url(path: str | None) -> str | None:
    return f"{TMDB_IMAGE_BASE_URL}{path}" if path else None


async def search(query: str) -> dict:
    async with httpx.AsyncClient(base_url=settings.TMDB_BASE_URL, timeout=10) as client:
        response = await client.get(
            "/search/multi",
            params={
                "api_key": settings.TMDB_API_KEY,
                "query": query,
                "include_adult": "false",
            },
        )
        response.raise_for_status()
        return response.json()


async def get_tv_details(tmdb_id: int) -> dict:
    async with httpx.AsyncClient(base_url=settings.TMDB_BASE_URL, timeout=10) as client:
        response = await client.get(
            f"/tv/{tmdb_id}",
            params={"api_key": settings.TMDB_API_KEY},
        )
        response.raise_for_status()
        return response.json()
