from typing import Literal

from pydantic import BaseModel, model_validator


class HistoryItem(BaseModel):
    media_type: Literal["movie", "episode"]
    tmdb_id: int
    season_number: int | None = None
    episode_number: int | None = None

    @model_validator(mode="after")
    def check_episode_fields(self) -> "HistoryItem":
        if self.media_type == "episode" and (
            self.season_number is None or self.episode_number is None
        ):
            raise ValueError(
                "season_number and episode_number are required when media_type is 'episode'"
            )
        return self


class SyncActionResponse(BaseModel):
    status: str


class WatchlistItem(BaseModel):
    media_type: str
    tmdb_id: int | None = None
    title: str
    listed_at: str
