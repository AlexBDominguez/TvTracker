import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/features/library/application/library_providers.dart';
import 'package:frontend/features/library/presentation/widgets/filter_bottom_sheet.dart';
import 'package:frontend/shared/widgets/error_display.dart';
import 'package:frontend/shared/widgets/series_card.dart';
import 'package:frontend/shared/widgets/series_card_shimmer.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final mySeries = ref.watch(mySeriesProvider);
    final filteredSeries = ref.watch(filteredMySeriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi biblioteca', style: textTheme.displayMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality can be added here
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const FilterBottomSheet(),
              );
            },
          ),
        ],
        backgroundColor: AppColors.background,
      ),
      body: mySeries.when(
        data: (_) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.6,
          ),
          itemCount: filteredSeries.length,
          itemBuilder: (context, index) {
            return SeriesCard(series: filteredSeries[index]);
          },
        ),
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.6,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => const SeriesCardShimmer(),
        ),
        error: (err, stack) => ErrorDisplay(
          message: 'No se pudo cargar tu biblioteca.',
          onRetry: () => ref.invalidate(mySeriesProvider),
        ),
      ),
    );
  }
}