import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/models/series.dart';
import 'package:frontend/data/repositories/library_repository.dart';

enum SeriesStatusFilter { all, watching, completed, paused, dropped }

final seriesStatusFilterProvider = StateProvider<SeriesStatusFilter>((ref) => SeriesStatusFilter.all);

final mySeriesProvider = FutureProvider<List<Series>>((ref) async {
  final libraryRepository = ref.watch(libraryRepositoryProvider);
  return libraryRepository.getMySeries();
});

final filteredMySeriesProvider = Provider<List<Series>>((ref) {
  final filter = ref.watch(seriesStatusFilterProvider);
  final mySeries = ref.watch(mySeriesProvider);

  return mySeries.when(
    data: (series) {
      if (filter == SeriesStatusFilter.all) {
        return series;
      }
      return series.where((s) {
        switch (filter) {
          case SeriesStatusFilter.watching:
            return s.status == SeriesStatus.watching;
          case SeriesStatusFilter.completed:
            return s.status == SeriesStatus.completed;
          case SeriesStatusFilter.paused:
            return s.status == SeriesStatus.paused;
          case SeriesStatusFilter.dropped:
            return s.status == SeriesStatus.dropped;
          default:
            return true;
        }
      }).toList();
    },
    loading: () => [],
    error: (err, stack) => [],
  );
});