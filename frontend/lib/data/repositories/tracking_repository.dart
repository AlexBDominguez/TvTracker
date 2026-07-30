import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/data/models/episode.dart';

class TrackingRepository {
  final Dio _dio;

  TrackingRepository(this._dio);

  Future<void> markAsWatched(Episode episode) async {
    try {
      await _dio.post('/tracking/watch', data: _episodeRef(episode));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFromWatched(Episode episode) async {
    try {
      await _dio.post('/tracking/unwatch', data: _episodeRef(episode));
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _episodeRef(Episode episode) => {
    'episode_id': episode.id,
    'series_id': episode.seriesId,
    'season_number': episode.seasonNumber,
    'episode_number': episode.episodeNumber,
  };

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