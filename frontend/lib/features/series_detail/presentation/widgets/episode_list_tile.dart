import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/data/models/episode.dart';
import 'package:frontend/features/tracking/application/tracking_providers.dart';
import 'package:intl/intl.dart';

class EpisodeListTile extends ConsumerWidget {
  final Episode episode;

  const EpisodeListTile({super.key, required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isWatched = ref.watch(watchedEpisodesProvider).contains(episode.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: 'https://image.tmdb.org/t/p/w300${episode.stillPath}',
              width: 100,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${episode.episodeNumber}. ${episode.name}',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                if (episode.airDate != null)
                  Text(
                    DateFormat.yMMMd().format(episode.airDate!),
                    style: textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              isWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
              color: isWatched ? AppColors.success : AppColors.textSecondary,
            ),
            onPressed: () {
              ref.read(watchedEpisodesProvider.notifier).toggleWatched(context, episode);
            },
          ),
        ],
      ),
    );
  }
}