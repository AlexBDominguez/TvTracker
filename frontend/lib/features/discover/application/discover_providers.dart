import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/models/series.dart';
import 'package:frontend/data/repositories/series_repository.dart';

final popularSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final seriesRepository = ref.watch(seriesRepositoryProvider);
  return seriesRepository.getPopularSeries();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Series>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return [];
  }
  final seriesRepository = ref.watch(seriesRepositoryProvider);
  return seriesRepository.searchSeries(query);
});