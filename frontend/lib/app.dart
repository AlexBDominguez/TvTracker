import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class TvTrackerApp extends ConsumerWidget {
  const TvTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TvTracker',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}