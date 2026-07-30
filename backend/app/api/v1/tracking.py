import datetime as dt

import httpx
from fastapi import APIRouter, Depends
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.dependencies import get_current_user
from app.models.series_tracking import SeriesStatus, SeriesTracking
from app.models.user import User
from app.models.watched_episode import WatchedEpisode
from app.schemas.series import EpisodeOut
from app.schemas.tracking import EpisodeRef, SyncActionResponse
from app.services import tmdb_client
from app.services.cache import cache_get, cache_set

router = APIRouter(prefix="/tracking", tags=["tracking"])


async def _watched_keys_for_user(
    db: AsyncSession, user_id: int
) -> dict[int, set[tuple[int, int]]]:
    """tmdb show id -> set of (season_number, episode_number) already watched."""
    rows = (
        await db.execute(
            select(
                WatchedEpisode.series_tmdb_id,
                WatchedEpisode.season_number,
                WatchedEpisode.episode_number,
            ).where(WatchedEpisode.user_id == user_id)
        )
    ).all()

    watched: dict[int, set[tuple[int, int]]] = {}
    for series_tmdb_id, season_number, episode_number in rows:
        watched.setdefault(series_tmdb_id, set()).add((season_number, episode_number))
    return watched


async def _cached_tv_details(tmdb_id: int) -> dict | None:
    cache_key = f"tv-details-raw:{tmdb_id}"
    data = await cache_get(cache_key)
    if data is None:
        try:
            data = await tmdb_client.get_tv_details(tmdb_id)
        except httpx.HTTPStatusError:
            return None
        await cache_set(cache_key, data)
    return data


async def _cached_season(tmdb_id: int, season_number: int) -> dict | None:
    cache_key = f"season:{tmdb_id}:{season_number}"
    data = await cache_get(cache_key)
    if data is None:
        try:
            data = await tmdb_client.get_season_details(tmdb_id, season_number)
        except httpx.HTTPStatusError:
            return None
        await cache_set(cache_key, data)
    return data


async def _episode_out_from_tmdb(
    series_tmdb_id: int, season_number: int, episode_number: int
) -> EpisodeOut | None:
    season_data = await _cached_season(series_tmdb_id, season_number)
    if season_data is None:
        return None

    for episode in season_data.get("episodes", []):
        if episode.get("episode_number") != episode_number:
            continue
        air_date_str = episode.get("air_date")
        return EpisodeOut(
            id=episode["id"],
            name=episode.get("name", ""),
            season_number=season_number,
            episode_number=episode_number,
            still_path=episode.get("still_path"),
            overview=episode.get("overview") or "",
            air_date=dt.date.fromisoformat(air_date_str) if air_date_str else None,
            series_id=series_tmdb_id,
        )
    return None


@router.post("/watch", response_model=SyncActionResponse, status_code=201)
async def mark_watched(
    payload: EpisodeRef,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SyncActionResponse:
    existing = await db.scalar(
        select(WatchedEpisode).where(
            WatchedEpisode.user_id == current_user.id,
            WatchedEpisode.series_tmdb_id == payload.series_id,
            WatchedEpisode.season_number == payload.season_number,
            WatchedEpisode.episode_number == payload.episode_number,
        )
    )
    if existing is None:
        db.add(
            WatchedEpisode(
                user_id=current_user.id,
                series_tmdb_id=payload.series_id,
                season_number=payload.season_number,
                episode_number=payload.episode_number,
                episode_tmdb_id=payload.episode_id,
            )
        )
        await db.commit()
    return SyncActionResponse(status="added")


@router.post("/unwatch", response_model=SyncActionResponse)
async def unmark_watched(
    payload: EpisodeRef,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SyncActionResponse:
    await db.execute(
        delete(WatchedEpisode).where(
            WatchedEpisode.user_id == current_user.id,
            WatchedEpisode.series_tmdb_id == payload.series_id,
            WatchedEpisode.season_number == payload.season_number,
            WatchedEpisode.episode_number == payload.episode_number,
        )
    )
    await db.commit()
    return SyncActionResponse(status="removed")


@router.get("/last-watched", response_model=EpisodeOut | None)
async def last_watched(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> EpisodeOut | None:
    entry = await db.scalar(
        select(WatchedEpisode)
        .where(WatchedEpisode.user_id == current_user.id)
        .order_by(WatchedEpisode.watched_at.desc())
        .limit(1)
    )
    if entry is None:
        return None

    return await _episode_out_from_tmdb(
        entry.series_tmdb_id, entry.season_number, entry.episode_number
    )


@router.get("/pending", response_model=list[EpisodeOut])
async def pending_episodes(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[EpisodeOut]:
    watched_by_show = await _watched_keys_for_user(db, current_user.id)

    trackings = (
        await db.scalars(
            select(SeriesTracking).where(
                SeriesTracking.user_id == current_user.id,
                SeriesTracking.status == SeriesStatus.WATCHING,
            )
        )
    ).all()

    today = dt.date.today()
    pending: list[EpisodeOut] = []

    for tracking in trackings:
        show_data = await _cached_tv_details(tracking.tmdb_id)
        if show_data is None:
            continue
        watched_episodes = watched_by_show.get(tracking.tmdb_id, set())

        for season in show_data.get("seasons", []):
            season_number = season.get("season_number", 0)
            if season_number == 0:
                continue  # specials

            season_data = await _cached_season(tracking.tmdb_id, season_number)
            if season_data is None:
                continue

            for episode in season_data.get("episodes", []):
                air_date_str = episode.get("air_date")
                if not air_date_str:
                    continue
                air_date = dt.date.fromisoformat(air_date_str)
                if air_date > today:
                    continue
                key = (season_number, episode.get("episode_number", 0))
                if key in watched_episodes:
                    continue
                pending.append(
                    EpisodeOut(
                        id=episode["id"],
                        name=episode.get("name", ""),
                        season_number=season_number,
                        episode_number=episode.get("episode_number", 0),
                        still_path=episode.get("still_path"),
                        overview=episode.get("overview") or "",
                        air_date=air_date,
                        series_id=tracking.tmdb_id,
                    )
                )

    pending.sort(key=lambda ep: ep.air_date or today)
    return pending
