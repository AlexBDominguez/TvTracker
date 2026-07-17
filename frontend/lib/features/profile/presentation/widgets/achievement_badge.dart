import 'package:flutter/material.dart';
import 'package:frontend/core/theme/colors.dart';

class AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.surface,
          child: Icon(icon, size: 30, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}