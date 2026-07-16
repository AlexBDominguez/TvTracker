import httpx
from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.content import SearchResponse, SearchResultItem, Season, ShowDetail
from app.services import tmdb_client
from app.services.cache import cache_get, cache_set

router = APIRouter(tags=["content"])


@router.get("/search", response_model=SearchResponse)
async def search(query: str, current_user: User = Depends(get_current_user)) -> SearchResponse:
    cache_key = f"search:{query.lower()}"
    cached = await cache_get(cache_key)
    if cached is not None:
        return cached

    try:
        data = await tmdb_client.search(query)
    except httpx.HTTPError:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY, detail="TMDB no disponible"
        )

    results = [
        SearchResultItem(
            tmdb_id=item["id"],
            media_type=item["media_type"],
            title=item.get("title") or item.get("name", ""),
            overview=item.get("overview"),
            poster_url=tmdb_client.image_url(item.get("poster_path")),
            release_date=item.get("release_date") or item.get("first_air_date"),
        )
        for item in data.get("results", [])
        if item.get("media_type") in ("movie", "tv")
    ]
    response = SearchResponse(query=query, results=results)
    await cache_set(cache_key, response)
    return response


@router.get("/shows/{tmdb_id}", response_model=ShowDetail)
async def get_show(tmdb_id: int, current_user: User = Depends(get_current_user)) -> ShowDetail:
    cache_key = f"show:{tmdb_id}"
    cached = await cache_get(cache_key)
    if cached is not None:
        return cached

    try:
        data = await tmdb_client.get_tv_details(tmdb_id)
    except httpx.HTTPStatusError as exc:
        if exc.response.status_code == 404:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Show not found"
            )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY, detail="TMDB no disponible"
        )
    except httpx.HTTPError:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY, detail="TMDB no disponible"
        )

    show = ShowDetail(
        tmdb_id=data["id"],
        name=data.get("name", ""),
        overview=data.get("overview"),
        poster_url=tmdb_client.image_url(data.get("poster_path")),
        backdrop_url=tmdb_client.image_url(data.get("backdrop_path")),
        first_air_date=data.get("first_air_date"),
        seasons=[
            Season(
                id=s["id"],
                season_number=s["season_number"],
                name=s.get("name", ""),
                episode_count=s.get("episode_count", 0),
            )
            for s in data.get("seasons", [])
        ],
    )
    await cache_set(cache_key, show)
    return show
