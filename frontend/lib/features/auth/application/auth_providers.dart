import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/models/user.dart';
import 'package:frontend/data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;

  AuthState({required this.status, this.user});
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState(status: AuthStatus.unknown)) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _authRepository.getToken();
    if (token != null) {
      try {
        final user = await _authRepository.getMe();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } catch (e) {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final user = await _authRepository.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final user = await _authRepository.register(username, email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}