import 'package:flutter/material.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/features/statistics/presentation/widgets/genre_donut_chart.dart';
import 'package:frontend/features/statistics/presentation/widgets/metric_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas', style: textTheme.displayMedium),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Series'),
            Tab(text: 'Episodios'),
            Tab(text: 'Tiempo'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Resumen Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    MetricCard(icon: Icons.movie, label: 'Series vistas', value: '12'),
                    MetricCard(icon: Icons.video_library, label: 'Episodios vistos', value: '150'),
                    MetricCard(icon: Icons.watch_later, label: 'Tiempo visto', value: '3d 12h'),
                    MetricCard(icon: Icons.calendar_today, label: 'Racha actual', value: '🔥 12 días'),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Géneros más vistos', style: textTheme.displaySmall),
                const SizedBox(height: 16),
                const GenreDonutChart(),
              ],
            ),
          ),
          const Center(child: Text('Series')),
          const Center(child: Text('Episodios')),
          const Center(child: Text('Tiempo')),
        ],
      ),
    );
  }
}