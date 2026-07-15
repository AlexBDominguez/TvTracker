import 'package:flutter/material.dart';

import 'app_theme.dart';

import 'features/main/presentation/screens/main_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TvTracker',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}