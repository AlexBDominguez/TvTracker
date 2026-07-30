import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/models/episode.dart';
import 'package:frontend/data/repositories/tracking_repository.dart';

final watchedEpisodesProvider = StateNotifierProvider<WatchedEpisodesNotifier, Set<int>>((ref) {
  // In a real app, you'd fetch the initial watched episodes from the repository
  return WatchedEpisodesNotifier(ref.watch(trackingRepositoryProvider), {});
});

class WatchedEpisodesNotifier extends StateNotifier<Set<int>> {
  final TrackingRepository _trackingRepository;

  WatchedEpisodesNotifier(this._trackingRepository, Set<int> initialWatched) : super(initialWatched);

  Future<void> toggleWatched(BuildContext context, Episode episode) async {
    final episodeId = episode.id;
    final isWatched = state.contains(episodeId);
    if (isWatched) {
      state = state.difference({episodeId});
      try {
        await _trackingRepository.removeFromWatched(episode);
      } catch (e) {
        state = state.union({episodeId});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al desmarcar el episodio.')),
        );
      }
    } else {
      state = state.union({episodeId});
      try {
        await _trackingRepository.markAsWatched(episode);
      } catch (e) {
        state = state.difference({episodeId});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al marcar el episodio.')),
        );
      }
    }
  }
}