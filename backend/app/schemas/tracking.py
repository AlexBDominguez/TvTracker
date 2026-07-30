from pydantic import BaseModel


class EpisodeRef(BaseModel):
    # The frontend's TrackingRepository posts these keys as snake_case, unlike
    # everything else it sends/expects (which is camelCase) - matching what it
    # actually sends rather than what would be consistent.
    episode_id: int
    series_id: int
    season_number: int
    episode_number: int


class SyncActionResponse(BaseModel):
    status: str
