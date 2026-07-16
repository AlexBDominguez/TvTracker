import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/repositories/tracking_repository.dart';

final watchedEpisodesProvider = StateNotifierProvider<WatchedEpisodesNotifier, Set<int>>((ref) {
  // In a real app, you'd fetch the initial watched episodes from the repository
  return WatchedEpisodesNotifier(ref.watch(trackingRepositoryProvider), {});
});

class WatchedEpisodesNotifier extends StateNotifier<Set<int>> {
  final TrackingRepository _trackingRepository;

  WatchedEpisodesNotifier(this._trackingRepository, Set<int> initialWatched) : super(initialWatched);

  Future<void> toggleWatched(int episodeId) async {
    final isWatched = state.contains(episodeId);
    if (isWatched) {
      state = state.difference({episodeId});
      try {
        await _trackingRepository.removeFromWatched(episodeId);
      } catch (e) {
        // If the request fails, revert the state
        state = state.union({episodeId});
        rethrow;
      }
    } else {
      state = state.union({episodeId});
      try {
        await _trackingRepository.markAsWatched(episodeId);
      } catch (e) {
        // If the request fails, revert the state
        state = state.difference({episodeId});
        rethrow;
      }
    }
  }
}