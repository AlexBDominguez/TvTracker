from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Integer, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class WatchedEpisode(Base):
    """A single episode a user has marked as watched, keyed by TMDB identity."""

    __tablename__ = "watched_episode"
    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "series_tmdb_id",
            "season_number",
            "episode_number",
            name="uq_watched_episode_user_episode",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    series_tmdb_id: Mapped[int] = mapped_column(Integer, nullable=False)
    season_number: Mapped[int] = mapped_column(Integer, nullable=False)
    episode_number: Mapped[int] = mapped_column(Integer, nullable=False)
    episode_tmdb_id: Mapped[int] = mapped_column(Integer, nullable=False)
    watched_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped["User"] = relationship()
