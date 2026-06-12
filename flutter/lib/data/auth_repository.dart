import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_user.dart';
import 'api_client.dart';

class AuthRepository {
  AuthRepository(this._api, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  Future<AuthUser?> cachedUser() async {
    final raw = await _storage.read(key: 'user');
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<String?> accessToken() => _storage.read(key: 'access_token');

  Future<void> register(String email, String password) async {
    await _api.register(email, password);
  }

  Future<AuthUser> login(String email, String password) async {
    final response = await _api.login(email, password);
    await _saveAuth(response.accessToken, response.refreshToken, response.user);
    return response.user;
  }

  Future<void> resendVerification(String email) async {
    await _api.resendVerification(email);
  }

  Future<AuthUser?> fetchCurrentUser() async {
    final token = await accessToken();
    if (token == null) return null;
    try {
      return await withRefresh((t) async {
        final user = await _api.getMe(t);
        await _saveUser(user);
        return user;
      });
    } on ApiException {
      return null;
    }
  }

  Future<AuthUser> updateNickname(String nickname) async {
    return withRefresh((t) async {
      await _api.updateNickname(t, nickname);
      final current = await cachedUser();
      final updated = (current ?? const AuthUser(id: '', email: '')).copyWith(nickname: nickname);
      await _saveUser(updated);
      return updated;
    });
  }

  Future<void> deleteAccount() async {
    await withRefresh((t) async {
      await _api.deleteAccount(t);
      await logout();
    });
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<T> withRefresh<T>(Future<T> Function(String token) call) async {
    final token = await accessToken();
    if (token == null) throw ApiException('Not logged in');
    try {
      return await call(token);
    } on ApiException catch (e) {
      if (!e.isUnauthorized) rethrow;
      final refreshed = await _tryRefresh();
      if (!refreshed) {
        await logout();
        throw ApiException('Session expired, please log in again', statusCode: 401);
      }
      final newToken = await accessToken();
      return await call(newToken!);
    }
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;
    try {
      final response = await _api.refresh(refreshToken);
      await _storage.write(key: 'access_token', value: response.accessToken);
      await _storage.write(key: 'refresh_token', value: response.refreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveAuth(String accessToken, String refreshToken, AuthUser user) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _saveUser(user);
  }

  Future<void> _saveUser(AuthUser user) async {
    await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
  }
}
