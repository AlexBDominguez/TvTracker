import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/data/models/series.dart';

class LibraryRepository {
  final Dio _dio;

  LibraryRepository(this._dio);

  Future<List<Series>> getMySeries() async {
    try {
      final response = await _dio.get('/library/my-series');
      final results = response.data as List;
      return results.map((e) => Series.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LibraryRepository(dio);
});