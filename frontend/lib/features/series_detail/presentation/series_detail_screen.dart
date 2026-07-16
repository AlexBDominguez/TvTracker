import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/features/series_detail/application/series_detail_providers.dart';
import 'package:frontend/features/series_detail/presentation/widgets/detail_info_row.dart';
import 'package:frontend/features/series_detail/presentation/widgets/episode_list_tile.dart';
import 'package:frontend/shared/widgets/error_display.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final int seriesId;

  const SeriesDetailScreen({super.key, required this.seriesId});

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedSeason = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final seriesDetail = ref.watch(seriesDetailProvider(widget.seriesId));

    return Scaffold(
      body: seriesDetail.when(
        data: (series) {
          final episodes = ref.watch(seasonEpisodesProvider(SeasonEpisodes(seriesId: widget.seriesId, seasonNumber: _selectedSeason)));
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 300.0,
                  pinned: true,
                  title: Text(series.name),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: 'https://image.tmdb.org/t/p/w780${series.backdropPath}',
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.5),
                          colorBlendMode: BlendMode.darken,
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Hero(
                            tag: 'series-poster-${series.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: 'https://image.tmdb.org/t/p/w500${series.posterPath}',
                                width: 100,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(series.overview, style: textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        const Chip(
                          label: Text('Siguiendo ✓'),
                          backgroundColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Episodios'),
                        Tab(text: 'Detalles'),
                      ],
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Episodes Tab
                ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: DropdownButton<int>(
                        value: _selectedSeason,
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedSeason = newValue!;
                          });
                        },
                        items: List.generate(series.numberOfSeasons, (index) => index + 1)
                            .map<DropdownMenuItem<int>>((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('Temporada $value'),
                          );
                        }).toList(),
                      ),
                    ),
                    episodes.when(
                      data: (episodeList) => ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: episodeList.length,
                        itemBuilder: (context, index) => EpisodeListTile(episode: episodeList[index]),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => ErrorDisplay(
                        message: 'No se pudieron cargar los episodios.',
                        onRetry: () => ref.invalidate(seasonEpisodesProvider),
                      ),
                    ),
                  ],
                ),
                // Details Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DetailInfoRow(label: 'Puntuación', value: '${series.voteAverage}/10'),
                      DetailInfoRow(label: 'Temporadas', value: '${series.numberOfSeasons}'),
                      // Add more details here
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorDisplay(
          message: 'No se pudo cargar la información de la serie.',
          onRetry: () => ref.invalidate(seriesDetailProvider(widget.seriesId)),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}