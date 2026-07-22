from datetime import date

from app.models.series_tracking import SeriesStatus
from app.schemas.base import CamelModel


class SeriesOut(CamelModel):
    id: int
    name: str
    poster_path: str | None = None
    backdrop_path: str | None = None
    overview: str
    vote_average: float
    number_of_seasons: int
    status: SeriesStatus | None = None


class EpisodeOut(CamelModel):
    id: int
    name: str
    season_number: int
    episode_number: int
    still_path: str | None = None
    overview: str
    air_date: date | None = None
    series_id: int | None = None


class SeriesStatusUpdate(CamelModel):
    status: SeriesStatus
