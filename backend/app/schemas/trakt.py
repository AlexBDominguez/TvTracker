from datetime import datetime

from pydantic import BaseModel


class TraktConnectResponse(BaseModel):
    authorize_url: str


class TraktStatus(BaseModel):
    connected: bool
    expires_at: datetime | None = None
