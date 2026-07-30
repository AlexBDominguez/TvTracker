import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/features/auth/application/auth_providers.dart';
import 'package:frontend/features/home/application/home_providers.dart';
import 'package:frontend/features/home/presentation/widgets/continue_watching_card.dart';
import 'package:frontend/shared/widgets/episode_card.dart';
import 'package:frontend/shared/widgets/episode_card_shimmer.dart';
import 'package:frontend/shared/widgets/error_display.dart';
import 'package:frontend/shared/widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authStateProvider);
    final homeState = ref.watch(homeProvider);
    final continueWatching = ref.watch(continueWatchingProvider);

    return Scaffold(
      body: homeState.when(
        data: (state) => CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              pinned: false,
              expandedHeight: 120.0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.all(16),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${authState.user?.name ?? ''} 👋',
                      style: textTheme.displayMedium,
                    ),
                    Text(
                      'Tienes ${state.today.length + state.thisWeek.length + state.older.length} episodios pendientes',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {},
                ),
              ],
            ),
            continueWatching.when(
              data: (info) {
                if (info == null) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: ContinueWatchingCard(info: info),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            if (state.today.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(title: 'Hoy', count: state.today.length),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: EpisodeCard(episode: state.today[index], status: EpisodeCardStatus.today),
                      );
                    },
                    childCount: state.today.length,
                  ),
                ),
              ),
            ],
            if (state.thisWeek.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(title: 'Esta semana', count: state.thisWeek.length),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: EpisodeCard(episode: state.thisWeek[index]),
                      );
                    },
                    childCount: state.thisWeek.length,
                  ),
                ),
              ),
            ],
            if (state.older.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(title: 'Pendientes antiguos', count: state.older.length),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: EpisodeCard(episode: state.older[index], status: EpisodeCardStatus.late),
                      );
                    },
                    childCount: state.older.length,
                  ),
                ),
              ),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorDisplay(
          message: 'No se pudieron cargar los episodios pendientes.',
          onRetry: () => ref.invalidate(homeProvider),
        ),
      ),
    );
  }
}