import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/data/models/episode.dart';

class TrackingRepository {
  final Dio _dio;

  TrackingRepository(this._dio);

  Future<void> markAsWatched(int episodeId) async {
    try {
      await _dio.post('/tracking/watch', data: {'episode_id': episodeId});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFromWatched(int episodeId) async {
    try {
      await _dio.post('/tracking/unwatch', data: {'episode_id': episodeId});
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Episode>> getPendingEpisodes() async {
    try {
      final response = await _dio.get('/tracking/pending');
      final results = response.data as List;
      return results.map((e) => Episode.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Episode?> getLastWatchedEpisode() async {
    try {
      final response = await _dio.get('/tracking/last-watched');
      if (response.data == null) {
        return null;
      }
      return Episode.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TrackingRepository(dio);
});