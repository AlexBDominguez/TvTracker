from pydantic import BaseModel


class SearchResultItem(BaseModel):
    tmdb_id: int
    media_type: str
    title: str
    overview: str | None = None
    poster_url: str | None = None
    release_date: str | None = None


class SearchResponse(BaseModel):
    query: str
    results: list[SearchResultItem]


class Season(BaseModel):
    id: int
    season_number: int
    name: str
    episode_count: int


class ShowDetail(BaseModel):
    tmdb_id: int
    name: str
    overview: str | None = None
    poster_url: str | None = None
    backdrop_url: str | None = None
    first_air_date: str | None = None
    seasons: list[Season]
