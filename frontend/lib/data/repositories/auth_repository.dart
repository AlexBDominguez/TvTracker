import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/data/models/user.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final token = response.data['access_token'];
      await _storage.write(key: 'auth_token', value: token);
      return await getMe();
    } catch (e) {
      await _storage.delete(key: 'auth_token');
      rethrow;
    }
  }

  Future<User> register(String name, String email, String password) async {
    try {
      await _dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      return await login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  const storage = FlutterSecureStorage();
  return AuthRepository(dio, storage);
});