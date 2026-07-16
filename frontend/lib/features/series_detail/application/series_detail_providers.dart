import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/models/episode.dart';
import 'package:frontend/data/models/series.dart';
import 'package:frontend/data/repositories/series_repository.dart';

final seriesDetailProvider = FutureProvider.family<Series, int>((ref, seriesId) async {
  final seriesRepository = ref.watch(seriesRepositoryProvider);
  return seriesRepository.getSeriesDetails(seriesId);
});

class SeasonEpisodes {
  final int seriesId;
  final int seasonNumber;

  SeasonEpisodes({required this.seriesId, required this.seasonNumber});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonEpisodes &&
          runtimeType == other.runtimeType &&
          seriesId == other.seriesId &&
          seasonNumber == other.seasonNumber;

  @override
  int get hashCode => seriesId.hashCode ^ seasonNumber.hashCode;
}

final seasonEpisodesProvider = FutureProvider.family<List<Episode>, SeasonEpisodes>((ref, season) async {
  final seriesRepository = ref.watch(seriesRepositoryProvider);
  return seriesRepository.getSeriesEpisodes(season.seriesId, season.seasonNumber);
});