import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../domain/auth_user.dart';
import '../domain/product.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _baseHeaders => const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
      };

  Map<String, String> _authHeaders(String token) => {
        ..._baseHeaders,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };



  Future<AuthUser> getMe(String token) async {
    final response = await _get('/api/me', headers: _authHeaders(token));
    return AuthUser.fromJson(response);
  }

  Future<void> updateNickname(String token, String nickname) async {
    await _patch('/api/me/nickname', headers: _authHeaders(token), body: {'nickname': nickname});
  }

  Future<void> deleteAccount(String token) async {
    await _delete('/api/me', headers: _authHeaders(token));
  }

  Future<Product> getProduct(String token, String barcode) async {
    final response = await _get('/api/products/$barcode', headers: _authHeaders(token));
    return _mapBackendProduct(response);
  }

  Future<List<HistoryItem>> getHistory(String token) async {
    final response = await _get('/api/history/', headers: _authHeaders(token));
    return (response as List)
        .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHistory(String token, String barcode, Product product) async {
    await _post(
      '/api/history/',
      headers: _authHeaders(token),
      body: {
        'barcode': barcode,
        'title': product.title,
        'score': product.score,
      },
    );
  }

  Future<void> clearHistory(String token) async {
    await _delete('/api/history/', headers: _authHeaders(token));
  }

  Future<dynamic> _get(String path, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$coconutBackendBaseUrl$path');
    final response = await _client.get(uri, headers: headers ?? _baseHeaders);
    return _decode(response);
  }

  Future<dynamic> _post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$coconutBackendBaseUrl$path');
    final response = await _client.post(
      uri,
      headers: headers ?? {..._baseHeaders, 'Content-Type': 'application/json'},
      body: jsonEncode(body ?? const {}),
    );
    return _decode(response);
  }

  Future<dynamic> _patch(
    String path, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$coconutBackendBaseUrl$path');
    final response = await _client.patch(uri, headers: headers, body: jsonEncode(body));
    return _decode(response);
  }

  Future<dynamic> _delete(String path, {required Map<String, String> headers}) async {
    final uri = Uri.parse('$coconutBackendBaseUrl$path');
    final response = await _client.delete(uri, headers: headers);
    if (response.body.isEmpty && response.statusCode >= 200 && response.statusCode < 300) {
      return null;
    }
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('HTTP ${response.statusCode}: ${response.body}');
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Product _mapBackendProduct(Map<String, dynamic> dto) {
    final nutrition = dto['nutrition_facts'] as Map<String, dynamic>?;
    final risks = (dto['health_risks'] as List? ?? [])
        .map((item) => (item as Map<String, dynamic>)['fact'] as String? ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
    final category = dto['category'] as Map<String, dynamic>?;

    return Product(
      id: (dto['id'] as num?)?.toInt() ?? 0,
      title: dto['name'] as String? ?? 'Unknown',
      totalRating: (dto['total_rating'] as num?)?.toDouble() ?? 0,
      description: '',
      categoryName: category?['title'] as String? ?? 'Unknown',
      manufacturer: dto['brand'] as String? ?? 'Unknown',
      price: '',
      thumbnail: dto['image_link'] as String?,
      criteriaRatings: const [],
      worth: risks,
      info: const [],
      recommendations: const [],
      nutrients: nutrition == null
          ? null
          : Nutrients(
              proteins: nutrition['protein_g']?.toString(),
              fats: nutrition['fat_g']?.toString(),
              carbohydrates: nutrition['carbs_g']?.toString(),
              calories: nutrition['calories_kcal']?.toString(),
              fiber: nutrition['fiber_g']?.toString(),
            ),
      composition: dto['ingredients'] as String?,
      hasQualityMark: false,
      hasBadQualityMark: risks.isNotEmpty,
    );
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.barcode,
    required this.title,
    required this.score,
  });

  final String id;
  final String barcode;
  final String title;
  final int score;

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        id: json['id'] as String? ?? '',
        barcode: json['barcode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
      );
}
