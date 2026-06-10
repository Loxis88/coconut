import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';
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



  Future<AuthUser?> fetchCurrentUser() async {
    final token = await accessToken();
    if (token == null) return null;
    final user = await _api.getMe(token);
    await _saveUser(user);
    return user;
  }

  Future<AuthUser> updateNickname(String nickname) async {
    final token = await accessToken();
    if (token == null) throw ApiException('Not logged in');
    await _api.updateNickname(token, nickname);
    final current = await cachedUser();
    final updated = (current ?? const AuthUser(id: '', email: '')).copyWith(nickname: nickname);
    await _saveUser(updated);
    return updated;
  }

  Future<void> deleteAccount() async {
    final token = await accessToken();
    if (token == null) throw ApiException('Not logged in');
    await _api.deleteAccount(token);
    await logout();
  }

  Future<void> logout() async {
    await _storage.deleteAll();
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
