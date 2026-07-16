import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/models/episode.dart';
import 'package:frontend/data/models/series.dart';
import 'package:frontend/data/repositories/series_repository.dart';
import 'package:frontend/data/repositories/tracking_repository.dart';

class HomeState {
  final List<Episode> today;
  final List<Episode> thisWeek;
  final List<Episode> older;

  HomeState({required this.today, required this.thisWeek, required this.older});
}

final homeProvider = FutureProvider<HomeState>((ref) async {
  final trackingRepository = ref.watch(trackingRepositoryProvider);
  final pendingEpisodes = await trackingRepository.getPendingEpisodes();

  final now = DateTime.now();
  final today = <Episode>[];
  final thisWeek = <Episode>[];
  final older = <Episode>[];

  for (final episode in pendingEpisodes) {
    if (episode.airDate == null) {
      older.add(episode);
      continue;
    }
    final difference = now.difference(episode.airDate!);
    if (difference.inDays == 0) {
      today.add(episode);
    } else if (difference.inDays <= 7) {
      thisWeek.add(episode);
    } else {
      older.add(episode);
    }
  }

  return HomeState(today: today, thisWeek: thisWeek, older: older);
});

class ContinueWatchingInfo {
  final Series series;
  final Episode episode;

  ContinueWatchingInfo({required this.series, required this.episode});
}

final continueWatchingProvider = FutureProvider<ContinueWatchingInfo?>((ref) async {
  final trackingRepository = ref.watch(trackingRepositoryProvider);
  final seriesRepository = ref.watch(seriesRepositoryProvider);

  final lastWatched = await trackingRepository.getLastWatchedEpisode();
  if (lastWatched == null || lastWatched.seriesId == null) {
    return null;
  }

  final series = await seriesRepository.getSeriesDetails(lastWatched.seriesId!);

  return ContinueWatchingInfo(series: series, episode: lastWatched);
});