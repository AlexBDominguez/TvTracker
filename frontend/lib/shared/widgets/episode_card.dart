import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/data/models/episode.dart';
import 'package:frontend/features/tracking/application/tracking_providers.dart';
import 'package:intl/intl.dart';

class EpisodeCard extends ConsumerWidget {
  final Episode episode;

  const EpisodeCard({super.key, required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isWatched = ref.watch(watchedEpisodesProvider).contains(episode.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: 'https://image.tmdb.org/t/p/w300${episode.stillPath}',
              width: 120,
              height: 80,
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
                  style: textTheme.headlineMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (episode.airDate != null)
                  Text(
                    'T${episode.seasonNumber} · E${episode.episodeNumber} · ${DateFormat.yMMMd().format(episode.airDate!)}',
                    style: textTheme.bodyMedium,
                  ),
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  value: 0.2, // Placeholder
                  backgroundColor: AppColors.backgroundSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
              ref.read(watchedEpisodesProvider.notifier).toggleWatched(episode.id);
            },
          ),
        ],
      ),
    );
  }
}