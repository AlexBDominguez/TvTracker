import enum
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class SeriesStatus(str, enum.Enum):
    WATCHING = "watching"
    PLAN_TO_WATCH = "planToWatch"
    COMPLETED = "completed"
    PAUSED = "paused"
    DROPPED = "dropped"


class SeriesTracking(Base):
    """Per-user status for a show, keyed by TMDB id.

    Trakt only knows watchlist/watched-history, not the paused/dropped
    distinction the frontend's library screen needs, so that piece of state
    lives locally instead of being derived from Trakt.
    """

    __tablename__ = "series_tracking"
    __table_args__ = (UniqueConstraint("user_id", "tmdb_id", name="uq_series_tracking_user_show"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    tmdb_id: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[SeriesStatus] = mapped_column(
        Enum(SeriesStatus, native_enum=False, length=20), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship()
