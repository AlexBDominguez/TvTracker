import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.dependencies import get_current_user
from app.models.series_tracking import SeriesTracking
from app.models.user import User
from app.schemas.content import SearchResponse, SearchResultItem, Season, ShowDetail
from app.schemas.series import EpisodeOut, SeriesOut
from app.services import tmdb_client
from app.services.cache import cache_get, cache_set
from app.services.series_mapper import (
    episode_out_from_tmdb_episode,
    series_out_from_search_item,
    series_out_from_tv_details,
)

router = APIRouter(tags=["content"])
content_router = APIRouter(prefix="/content", tags=["content"])


async def _local_status(user: User, tmdb_id: int, db: AsyncSession) -> str | None:
    tracking = await db.scalar(
        select(SeriesTracking).where(
            SeriesTracking.user_id == user.id, SeriesTracking.tmdb_id == tmdb_id
        )
    )
    return tracking.status if tracking else None


@router.get("/search", response_model=SearchResponse)
async def search(query: str, current_user: User = Depends(get_current_user)) -> SearchResponse:
    cache_key = f"search:{query.lower()}"
    cached = await cache_get(cache_key)
    if cached is not None:
        return cached

    data = await tmdb_client.search(query)

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
        raise

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


@content_router.get("/search", response_model=list[SeriesOut])
async def content_search(
    query: str, current_user: User = Depends(get_current_user)
) -> list[SeriesOut]:
    cache_key = f"content-search:{query.lower()}"
    cached = await cache_get(cache_key)
    if cached is not None:
        return cached

    data = await tmdb_client.search(query)
    results = [
        series_out_from_search_item(item)
        for item in data.get("results", [])
        if item.get("media_type") == "tv"
    ]
    await cache_set(cache_key, results)
    return results


@content_router.get("/popular/series", response_model=list[SeriesOut])
async def content_popular_series(current_user: User = Depends(get_current_user)) -> list[SeriesOut]:
    cache_key = "content-popular-series"
    cached = await cache_get(cache_key)
    if cached is not None:
        return cached

    data = await tmdb_client.get_popular_tv()
    results = [series_out_from_search_item(item) for item in data.get("results", [])]
    await cache_set(cache_key, results)
    return results


@content_router.get("/series/{tmdb_id}", response_model=SeriesOut)
async def content_series_detail(
    tmdb_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SeriesOut:
    cache_key = f"tv-details-raw:{tmdb_id}"
    data = await cache_get(cache_key)

    if data is None:
        try:
            data = await tmdb_client.get_tv_details(tmdb_id)
        except httpx.HTTPStatusError as exc:
            if exc.response.status_code == 404:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND, detail="Show not found"
                )
            raise
        await cache_set(cache_key, data)

    series = series_out_from_tv_details(data)
    series.status = await _local_status(current_user, tmdb_id, db)
    return series


@content_router.get("/series/{tmdb_id}/season/{season_number}", response_model=list[EpisodeOut])
async def content_series_season(
    tmdb_id: int, season_number: int, current_user: User = Depends(get_current_user)
) -> list[EpisodeOut]:
    cache_key = f"season:{tmdb_id}:{season_number}"
    cached = await cache_get(cache_key)
    if cached is not None:
        return cached

    try:
        data = await tmdb_client.get_season_details(tmdb_id, season_number)
    except httpx.HTTPStatusError as exc:
        if exc.response.status_code == 404:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Season not found"
            )
        raise

    episodes = [
        episode_out_from_tmdb_episode(e, series_id=tmdb_id, season_number=season_number)
        for e in data.get("episodes", [])
    ]
    await cache_set(cache_key, episodes)
    return episodes
