from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.dependencies import get_current_user, get_trakt_credentials
from app.models.trakt_credentials import TraktCredentials
from app.models.user import User
from app.schemas.sync import HistoryItem, SyncActionResponse, WatchlistItem
from app.services import trakt_client

router = APIRouter(prefix="/sync", tags=["sync"])


@router.get("/watchlist", response_model=list[WatchlistItem])
async def get_watchlist(
    credentials: TraktCredentials = Depends(get_trakt_credentials),
    db: AsyncSession = Depends(get_db),
) -> list[WatchlistItem]:
    access_token = await trakt_client.get_valid_access_token(credentials, db)
    raw_items = await trakt_client.get_watchlist(access_token)

    return [
        WatchlistItem(**trakt_client.watchlist_item_from_trakt(item)) for item in raw_items
    ]


@router.post("/history", response_model=SyncActionResponse, status_code=status.HTTP_201_CREATED)
async def add_history(
    item: HistoryItem,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SyncActionResponse:
    # Trakt-connection check happens after body validation on purpose, so an
    # invalid payload still surfaces as 422 rather than being shadowed by 400.
    credentials = await get_trakt_credentials(current_user, db)
    payload = trakt_client.build_history_payload(
        item.media_type, item.tmdb_id, item.season_number, item.episode_number
    )
    access_token = await trakt_client.get_valid_access_token(credentials, db)
    await trakt_client.add_to_history(access_token, payload)

    return SyncActionResponse(status="added")


@router.delete("/history", response_model=SyncActionResponse)
async def remove_history(
    item: HistoryItem,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SyncActionResponse:
    credentials = await get_trakt_credentials(current_user, db)
    payload = trakt_client.build_history_payload(
        item.media_type, item.tmdb_id, item.season_number, item.episode_number
    )
    access_token = await trakt_client.get_valid_access_token(credentials, db)
    await trakt_client.remove_from_history(access_token, payload)

    return SyncActionResponse(status="removed")
