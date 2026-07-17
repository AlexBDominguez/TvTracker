import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/features/discover/application/discover_providers.dart';
import 'package:frontend/shared/widgets/error_display.dart';
import 'package:frontend/shared/widgets/horizontal_carousel.dart';
import 'package:frontend/shared/widgets/series_card.dart';
import 'package:frontend/shared/widgets/series_card_shimmer.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final popularSeries = ref.watch(popularSeriesProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Descubrir', style: textTheme.displayMedium),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar series, actores, directores...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: searchQuery.isEmpty
                ? popularSeries.when(
                    data: (series) => ListView(
                      children: [
                        HorizontalCarousel(
                          title: 'Populares',
                          series: series,
                          onSeeAll: () {},
                        ),
                      ],
                    ),
                    loading: () => SizedBox(
                      height: 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 3,
                        itemBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: SeriesCardShimmer(),
                        ),
                      ),
                    ),
                    error: (err, stack) => ErrorDisplay(
                      message: 'No se pudieron cargar las series populares.',
                      onRetry: () => ref.invalidate(popularSeriesProvider),
                    ),
                  )
                : searchResults.when(
                    data: (series) => GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.6,
                      ),
                      itemCount: series.length,
                      itemBuilder: (context, index) {
                        return SeriesCard(series: series[index]);
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
                      message: 'No se pudieron encontrar resultados.',
                      onRetry: () => ref.invalidate(searchResultsProvider),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}