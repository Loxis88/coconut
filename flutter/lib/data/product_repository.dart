import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/product.dart';
import 'api_client.dart';

class ProductRepository {
  ProductRepository(this._api);

  static const _historyKey = 'scan_history';
  static const _datesKey = 'scan_dates';

  final ApiClient _api;
  final _historyController = StreamController<List<Product>>.broadcast();
  SharedPreferences? _prefs;
  List<Product> _history = const [];

  Stream<List<Product>> get historyStream => _historyController.stream;
  List<Product> get history => _history;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _history = _loadHistory();
    _emit();
  }

  Future<Product> searchByBarcode(String barcode, String? token) async {
    if (barcode.trim().isEmpty) throw ApiException('Barcode is empty');
    if (token == null) throw ApiException('Authentication required');

    final product = await _api.getProduct(token, barcode.trim());
    final next = _history.where((item) => item.id != product.id).toList();
    _history = [product, ...next];
    await _saveHistory();
    await _trackScanDate();

    try {
      await _api.saveHistory(token, barcode.trim(), product);
    } catch (_) {
      // Local history remains the source of immediate UI feedback.
    }

    return product;
  }

  Future<void> syncHistory(String token) async {
    try {
      final serverHistory = await _api.getHistory(token);
      final mapped = <Product>[];
      for (final item in serverHistory) {
        final matches = _history.where((product) => product.title == item.title);
        final local = matches.isEmpty ? null : matches.first;
        if (local != null) {
          mapped.add(local);
          continue;
        }
        try {
          mapped.add(await _api.getProduct(token, item.barcode));
        } catch (_) {
          mapped.add(
            Product(
              id: item.id.hashCode,
              title: item.title,
              totalRating: item.score / 20.0,
              description: '',
              categoryName: '',
              manufacturer: '',
              price: '',
              thumbnail: null,
              criteriaRatings: const [],
              worth: const [],
              info: const [],
              recommendations: const [],
              nutrients: null,
              composition: null,
              hasQualityMark: false,
              hasBadQualityMark: false,
            ),
          );
        }
      }
      if (mapped.isNotEmpty) {
        _history = mapped;
        await _saveHistory();
      }
    } catch (_) {
      _emit();
    }
  }

  Future<void> deleteFromHistory(Product product) async {
    _history = _history.where((item) => item.id != product.id).toList();
    await _saveHistory();
  }

  Future<void> clearHistory(String? token) async {
    _history = const [];
    await _prefs?.remove(_historyKey);
    _emit();
    if (token != null) {
      try {
        await _api.clearHistory(token);
      } catch (_) {}
    }
  }

  int dailyAverage() {
    if (_history.isEmpty) return 0;
    return _history.map((item) => item.score).reduce((a, b) => a + b) ~/ _history.length;
  }

  int streak() {
    final raw = _prefs?.getString(_datesKey) ?? '[]';
    final dates = (jsonDecode(raw) as List)
        .map((item) => DateTime.tryParse(item as String))
        .whereType<DateTime>()
        .map((item) => DateTime(item.year, item.month, item.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (dates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (dates.first != today && dates.first != yesterday) return 0;

    var count = 1;
    for (var i = 0; i < dates.length - 1; i++) {
      if (dates[i].subtract(const Duration(days: 1)) == dates[i + 1]) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  List<Product> _loadHistory() {
    final raw = _prefs?.getString(_historyKey) ?? '[]';
    return (jsonDecode(raw) as List)
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveHistory() async {
    await _prefs?.setString(_historyKey, jsonEncode(_history.map((item) => item.toJson()).toList()));
    _emit();
  }

  Future<void> _trackScanDate() async {
    final raw = _prefs?.getString(_datesKey) ?? '[]';
    final dates = (jsonDecode(raw) as List).cast<String>().toSet();
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    dates.add(today);
    await _prefs?.setString(_datesKey, jsonEncode(dates.toList()));
  }

  void _emit() => _historyController.add(List.unmodifiable(_history));
}
