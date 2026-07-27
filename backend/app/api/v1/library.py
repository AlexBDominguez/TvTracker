import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.dependencies import get_current_user
from app.models.series_tracking import SeriesStatus, SeriesTracking
from app.models.user import User
from app.schemas.series import SeriesOut, SeriesStatusUpdate
from app.services import tmdb_client
from app.services.cache import cache_get, cache_set
from app.services.series_mapper import series_out_from_tv_details

router = APIRouter(prefix="/library", tags=["library"])


@router.get("/my-series", response_model=list[SeriesOut])
async def get_my_series(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[SeriesOut]:
    trackings = (
        await db.scalars(
            select(SeriesTracking).where(SeriesTracking.user_id == current_user.id)
        )
    ).all()

    results = []
    for tracking in trackings:
        cache_key = f"tv-details-raw:{tracking.tmdb_id}"
        data = await cache_get(cache_key)
        if data is None:
            try:
                data = await tmdb_client.get_tv_details(tracking.tmdb_id)
            except httpx.HTTPStatusError:
                continue
            await cache_set(cache_key, data)

        series = series_out_from_tv_details(data)
        series.status = tracking.status
        results.append(series)

    return results


@router.put("/series/{tmdb_id}/status", response_model=SeriesOut)
async def set_series_status(
    tmdb_id: int,
    payload: SeriesStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SeriesOut:
    tracking = await db.scalar(
        select(SeriesTracking).where(
            SeriesTracking.user_id == current_user.id, SeriesTracking.tmdb_id == tmdb_id
        )
    )
    if tracking is None:
        tracking = SeriesTracking(
            user_id=current_user.id, tmdb_id=tmdb_id, status=payload.status
        )
        db.add(tracking)
    else:
        tracking.status = payload.status
    await db.commit()

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
    series.status = SeriesStatus(tracking.status)
    return series
