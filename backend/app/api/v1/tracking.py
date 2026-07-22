import datetime as dt

import httpx
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.dependencies import get_current_user, get_trakt_credentials
from app.models.series_tracking import SeriesStatus, SeriesTracking
from app.models.trakt_credentials import TraktCredentials
from app.models.user import User
from app.schemas.series import EpisodeOut
from app.schemas.sync import SyncActionResponse
from app.schemas.tracking import EpisodeRef
from app.services import tmdb_client, trakt_client
from app.services.cache import cache_get, cache_set

router = APIRouter(prefix="/tracking", tags=["tracking"])


def _watched_keys_from_trakt(watched_shows: list[dict]) -> dict[int, set[tuple[int, int]]]:
    """tmdb show id -> set of (season_number, episode_number) already watched."""
    watched: dict[int, set[tuple[int, int]]] = {}
    for entry in watched_shows:
        tmdb_id = entry.get("show", {}).get("ids", {}).get("tmdb")
        if tmdb_id is None:
            continue
        episodes = {
            (season["number"], episode["number"])
            for season in entry.get("seasons", [])
            for episode in season.get("episodes", [])
        }
        watched[tmdb_id] = episodes
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


@router.post("/watch", response_model=SyncActionResponse, status_code=201)
async def mark_watched(
    payload: EpisodeRef,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SyncActionResponse:
    credentials = await get_trakt_credentials(current_user, db)
    access_token = await trakt_client.get_valid_access_token(credentials, db)
    history_payload = trakt_client.build_episode_history_payload(payload.episode_id)
    await trakt_client.add_to_history(access_token, history_payload)
    return SyncActionResponse(status="added")


@router.post("/unwatch", response_model=SyncActionResponse)
async def unmark_watched(
    payload: EpisodeRef,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SyncActionResponse:
    credentials = await get_trakt_credentials(current_user, db)
    access_token = await trakt_client.get_valid_access_token(credentials, db)
    history_payload = trakt_client.build_episode_history_payload(payload.episode_id)
    await trakt_client.remove_from_history(access_token, history_payload)
    return SyncActionResponse(status="removed")


@router.get("/last-watched", response_model=EpisodeOut | None)
async def last_watched(
    credentials: TraktCredentials = Depends(get_trakt_credentials),
    db: AsyncSession = Depends(get_db),
) -> EpisodeOut | None:
    access_token = await trakt_client.get_valid_access_token(credentials, db)
    history = await trakt_client.get_history(access_token, media_type="episodes", limit=1)
    if not history:
        return None

    entry = history[0]
    episode = entry.get("episode", {})
    show = entry.get("show", {})
    episode_tmdb_id = episode.get("ids", {}).get("tmdb")
    if episode_tmdb_id is None:
        return None

    return EpisodeOut(
        id=episode_tmdb_id,
        name=episode.get("title") or "",
        season_number=episode.get("season", 0),
        episode_number=episode.get("number", 0),
        still_path=None,
        overview="",
        air_date=None,
        series_id=show.get("ids", {}).get("tmdb"),
    )


@router.get("/pending", response_model=list[EpisodeOut])
async def pending_episodes(
    current_user: User = Depends(get_current_user),
    credentials: TraktCredentials = Depends(get_trakt_credentials),
    db: AsyncSession = Depends(get_db),
) -> list[EpisodeOut]:
    access_token = await trakt_client.get_valid_access_token(credentials, db)
    watched_shows = await trakt_client.get_watched_shows(access_token)
    watched_by_show = _watched_keys_from_trakt(watched_shows)

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
