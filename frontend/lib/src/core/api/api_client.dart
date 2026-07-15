import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  // Note: For Android emulators, 'localhost' is '10.0.2.2'.
  // For web and iOS simulators, 'localhost' works directly.
  // We use a check on the platform to set the correct base URL.
  static final String _baseUrl =
      defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:8000/api/v1' : 'http://localhost:8000/api/v1';

  ApiClient({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
  })  : _dio = dio,
        _secureStorage = secureStorage {
    _dio.options.baseUrl = _baseUrl;
    _dio.interceptors.add(_createAuthInterceptor());
  }

  // Public getter to access the configured Dio instance for making requests.
  Dio get dio => _dio;

  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Retrieve the token from secure storage.
        final token = await _secureStorage.read(key: 'access_token');
        if (token != null) {
          // Add the 'Authorization: Bearer <token>' header to the request.
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options); // Continue with the request.
      },
    );
  }
}