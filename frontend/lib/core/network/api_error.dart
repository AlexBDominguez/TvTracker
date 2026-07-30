import 'package:dio/dio.dart';

/// Extracts a user-facing message from an error thrown by [Dio].
///
/// The backend's global exception handlers always respond with
/// `{"error": "...", "code": ...}` (see `app/core/exceptions.py`), so we
/// prefer that field before falling back to generic, connectivity-aware copy.
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servidor. Comprueba tu conexión e inténtalo de nuevo.';
      default:
        return 'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
    }
  }

  return 'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
}
