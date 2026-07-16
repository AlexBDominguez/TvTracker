import 'package:flutter/material.dart';
import 'package:frontend/core/theme/colors.dart';

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            value,
            style: textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}