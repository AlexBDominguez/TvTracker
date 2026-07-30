import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/data/models/episode.dart';
import 'package:frontend/data/models/series.dart';

class SeriesRepository {
  final Dio _dio;

  SeriesRepository(this._dio);

  Future<List<Series>> getPopularSeries() async {
    try {
      final response = await _dio.get('/content/popular/series');
      final results = response.data as List;
      return results.map((e) => Series.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Series> getSeriesDetails(int seriesId) async {
    try {
      final response = await _dio.get('/content/series/$seriesId');
      return Series.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Episode>> getSeriesEpisodes(int seriesId, int seasonNumber) async {
    try {
      final response = await _dio.get('/content/series/$seriesId/season/$seasonNumber');
      final results = response.data as List;
      return results.map((e) => Episode.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Series>> searchSeries(String query) async {
    try {
      final response = await _dio.get('/content/search', queryParameters: {'query': query});
      final results = response.data as List;
      return results.map((e) => Series.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SeriesRepository(dio);
});