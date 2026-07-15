import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'core/api/api_client.dart';

final sl = GetIt.instance; // sl stands for Service Locator

void setupLocator() {
  // Register third-party packages
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

  // Register our ApiClient as a singleton.
  // It depends on the two packages above, which GetIt will provide automatically.
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(dio: sl(), secureStorage: sl()),
  );
}