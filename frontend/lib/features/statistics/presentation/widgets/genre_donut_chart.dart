import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/colors.dart';

class GenreDonutChart extends StatelessWidget {
  const GenreDonutChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              color: AppColors.primary,
              value: 40,
              title: '40%',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            PieChartSectionData(
              color: AppColors.secondary,
              value: 30,
              title: '30%',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            PieChartSectionData(
              color: AppColors.accent,
              value: 15,
              title: '15%',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            PieChartSectionData(
              color: AppColors.warning,
              value: 15,
              title: '15%',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          sectionsSpace: 4,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}