import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:frontend/features/library/application/library_providers.dart';

class FilterBottomSheet extends ConsumerWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(seriesStatusFilterProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filtrar por estado', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          ...SeriesStatusFilter.values.map((filter) {
            return RadioListTile<SeriesStatusFilter>(
              title: Text(filter.name),
              value: filter,
              groupValue: currentFilter,
              onChanged: (value) {
                ref.read(seriesStatusFilterProvider.notifier).state = value!;
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}