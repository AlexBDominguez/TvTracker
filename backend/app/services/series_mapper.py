from app.schemas.series import EpisodeOut, SeriesOut


def series_out_from_search_item(item: dict) -> SeriesOut:
    return SeriesOut(
        id=item["id"],
        name=item.get("name") or item.get("title", ""),
        poster_path=item.get("poster_path"),
        backdrop_path=item.get("backdrop_path"),
        overview=item.get("overview") or "",
        vote_average=item.get("vote_average") or 0.0,
        # Not available on TMDB list endpoints (search/popular), only on the
        # full show detail. Left at 0 here rather than fetching every result's
        # detail (would defeat the point of a list endpoint).
        number_of_seasons=0,
    )


def series_out_from_tv_details(data: dict) -> SeriesOut:
    return SeriesOut(
        id=data["id"],
        name=data.get("name", ""),
        poster_path=data.get("poster_path"),
        backdrop_path=data.get("backdrop_path"),
        overview=data.get("overview") or "",
        vote_average=data.get("vote_average") or 0.0,
        number_of_seasons=data.get("number_of_seasons") or 0,
    )


def episode_out_from_tmdb_episode(episode: dict, series_id: int, season_number: int) -> EpisodeOut:
    return EpisodeOut(
        id=episode["id"],
        name=episode.get("name", ""),
        season_number=episode.get("season_number", season_number),
        episode_number=episode.get("episode_number", 0),
        still_path=episode.get("still_path"),
        overview=episode.get("overview") or "",
        air_date=episode.get("air_date") or None,
        series_id=series_id,
    )
