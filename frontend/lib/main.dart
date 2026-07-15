import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/locator.dart';

void main() {
  // Ensure that Flutter bindings are initialized before any async operations.
  WidgetsFlutterBinding.ensureInitialized();

  // Set up the service locator for dependency injection.
  setupLocator();

  // Run the app within a ProviderScope for Riverpod state management.
  runApp(
    const ProviderScope(child: App()),
  );
}