import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/features/auth/application/auth_providers.dart';
import 'package:frontend/features/profile/presentation/widgets/achievement_badge.dart';
import 'package:frontend/features/series_detail/presentation/widgets/detail_info_row.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi perfil', style: textTheme.displayMedium),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://placehold.co/100x100'),
            ),
            const SizedBox(height: 16),
            Text(authState.user?.name ?? 'Usuario', style: textTheme.displayMedium),
            const SizedBox(height: 8),
            const Chip(
              label: Text('Nivel 5'),
              backgroundColor: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text('Logros recientes', style: textTheme.displaySmall),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AchievementBadge(icon: Icons.local_fire_department, label: 'Maratonista'),
                AchievementBadge(icon: Icons.movie_filter, label: 'Cinéfilo'),
                AchievementBadge(icon: Icons.star, label: 'Coleccionista'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Actividad', style: textTheme.displaySmall),
            const SizedBox(height: 16),
            const DetailInfoRow(label: 'Episodios vistos', value: '150'),
            const DetailInfoRow(label: 'Series en progreso', value: '5'),
            const DetailInfoRow(label: 'Series completadas', value: '12'),
            const DetailInfoRow(label: 'Películas vistas', value: '20'),
          ],
        ),
      ),
    );
  }
}