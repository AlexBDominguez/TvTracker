import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/data/models/episode.dart';
import 'package:frontend/features/tracking/application/tracking_providers.dart';
import 'package:intl/intl.dart';

enum EpisodeCardStatus { normal, today, newEpisode, late }

class EpisodeCard extends ConsumerWidget {
  final Episode episode;
  final EpisodeCardStatus status;

  const EpisodeCard({
    super.key,
    required this.episode,
    this.status = EpisodeCardStatus.normal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isWatched = ref.watch(watchedEpisodesProvider).contains(episode.id);

    Color statusColor;
    String? statusLabel;

    switch (status) {
      case EpisodeCardStatus.today:
        statusColor = AppColors.primary;
        statusLabel = 'HOY';
        break;
      case EpisodeCardStatus.newEpisode:
        statusColor = AppColors.secondary;
        statusLabel = 'NEW';
        break;
      case EpisodeCardStatus.late:
        statusColor = AppColors.warning;
        statusLabel = 'ATRASADO';
        break;
      default:
        statusColor = Colors.transparent;
        statusLabel = null;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: 'https://image.tmdb.org/t/p/w300${episode.stillPath}',
              width: 100,
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
                if (statusLabel != null)
                  Text(
                    statusLabel,
                    style: textTheme.labelLarge?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                Text(
                  '${episode.episodeNumber}. ${episode.name}',
                  style: textTheme.headlineMedium?.copyWith(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (episode.airDate != null)
                  Text(
                    'T${episode.seasonNumber} · E${episode.episodeNumber} · ${DateFormat.yMMMd().format(episode.airDate!)}',
                    style: textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              isWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
              color: isWatched ? AppColors.success : AppColors.textSecondary,
              size: 28,
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