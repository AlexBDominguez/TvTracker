import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/data/models/series.dart';
import 'package:go_router/go_router.dart';

class SeriesCard extends StatelessWidget {
  final Series series;

  const SeriesCard({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        GoRouter.of(context).go('/library/${series.id}');
      },
      child: Card(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'series-poster-${series.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: CachedNetworkImage(
                      imageUrl: 'https://image.tmdb.org/t/p/w500${series.posterPath}',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.name,
                        style: textTheme.headlineMedium?.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${series.numberOfSeasons} Temporadas',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        value: 0.5, // Placeholder
                        backgroundColor: AppColors.backgroundSecondary,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show bottom sheet with actions
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}