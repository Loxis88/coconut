import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'data/api_client.dart';
import 'data/auth_repository.dart';
import 'data/product_repository.dart';
import 'domain/auth_user.dart';
import 'domain/product.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/search_screen.dart';
import 'screens/swap_screen.dart';
import 'widgets/adaptive_screen.dart';
import 'widgets/shared.dart';

void main() {
  runApp(const CoconutApp());
}

class CoconutApp extends StatefulWidget {
  const CoconutApp({super.key});

  @override
  State<CoconutApp> createState() => _CoconutAppState();
}

class _CoconutAppState extends State<CoconutApp> {
  late final ApiClient _api;
  late final AuthRepository _authRepository;
  late final ProductRepository _productRepository;

  AuthUser? _user;
  Product? _currentProduct;
  List<Product> _history = const [];
  String? _error;
  bool _loading = true;
  StreamSubscription<List<Product>>? _historySub;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _authRepository = AuthRepository(_api);
    _productRepository = ProductRepository(_api);
    _bootstrap();
    _initAppLinks();
  }

  void _initAppLinks() {
    _appLinks = AppLinks();
    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      if (uri.scheme == 'coconut' && uri.host == 'verify') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email успешно подтверждён!')),
          );
        }
        try {
          final fresh = await _authRepository.fetchCurrentUser();
          if (fresh != null && mounted) setState(() => _user = fresh);
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _productRepository.init();
    _history = _productRepository.history;
    _historySub = _productRepository.historyStream.listen((items) {
      if (mounted) setState(() => _history = items);
    });
    final cached = await _authRepository.cachedUser();
    setState(() {
      _user = cached;
      _loading = false;
    });
    try {
      final fresh = await _authRepository.fetchCurrentUser();
      final token = await _authRepository.accessToken();
      if (fresh != null && token != null) {
        await _productRepository.syncHistory(token);
        setState(() => _user = fresh);
      }
    } catch (_) {
      await _authRepository.logout();
      setState(() => _user = null);
    }
  }



  Future<Product?> _searchBarcode(String barcode) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _authRepository.accessToken();
      final product = await _productRepository.searchByBarcode(barcode, token);
      setState(() => _currentProduct = product);
      return product;
    } catch (error) {
      setState(() => _error = error.toString());
      return null;
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    setState(() {
      _user = null;
      _currentProduct = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coconut',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Coco.emerald),
        scaffoldBackgroundColor: Coco.cream,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: _loading && _user == null
          ? const CenteredLoader()
          : _user == null
              ? AuthScreen(
                  loading: _loading,
                  error: _error,
                  onLogin: (email, password) async {
                    setState(() => _error = null);
                    try {
                      final user = await _authRepository.login(email, password);
                      final token = await _authRepository.accessToken();
                      if (token != null) await _productRepository.syncHistory(token);
                      setState(() => _user = user);
                    } catch (e) {
                      setState(() => _error = e.toString());
                      rethrow;
                    }
                  },
                  onRegister: (email, password) async {
                    setState(() => _error = null);
                    try {
                      await _authRepository.register(email, password);
                    } catch (e) {
                      setState(() => _error = e.toString());
                      rethrow;
                    }
                  },
                )
              : HomeShell(
                  user: _user!,
                  history: _history,
                  average: _productRepository.dailyAverage(),
                  streak: _productRepository.streak(),
                  loading: _loading,
                  error: _error,
                  currentProduct: _currentProduct,
                  onSearchBarcode: _searchBarcode,
                  onShowProduct: (product) => setState(() => _currentProduct = product),
                  onClearHistory: () async {
                    final token = await _authRepository.accessToken();
                    await _productRepository.clearHistory(token);
                  },
                  onDeleteProduct: _productRepository.deleteFromHistory,
                  onLogout: _logout,
                  onUpdateNickname: (nickname) async {
                    final updated = await _authRepository.updateNickname(nickname);
                    setState(() => _user = updated);
                  },
                  onDeleteAccount: () async {
                    await _authRepository.deleteAccount();
                    setState(() => _user = null);
                  },
                ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.user,
    required this.history,
    required this.average,
    required this.streak,
    required this.loading,
    required this.error,
    required this.currentProduct,
    required this.onSearchBarcode,
    required this.onShowProduct,
    required this.onClearHistory,
    required this.onDeleteProduct,
    required this.onLogout,
    required this.onUpdateNickname,
    required this.onDeleteAccount,
  });

  final AuthUser user;
  final List<Product> history;
  final int average;
  final int streak;
  final bool loading;
  final String? error;
  final Product? currentProduct;
  final Future<Product?> Function(String barcode) onSearchBarcode;
  final void Function(Product product) onShowProduct;
  final Future<void> Function() onClearHistory;
  final Future<void> Function(Product product) onDeleteProduct;
  final Future<void> Function() onLogout;
  final Future<void> Function(String nickname) onUpdateNickname;
  final Future<void> Function() onDeleteAccount;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _route = AppRoute.home;

  @override
  Widget build(BuildContext context) {
    Widget body = switch (_route) {
      AppRoute.home => HomeScreen(
          user: widget.user,
          history: widget.history,
          average: widget.average,
          streak: widget.streak,
          onScan: () => setState(() => _route = AppRoute.scan),
          onProfile: () => setState(() => _route = AppRoute.profile),
          onSearch: () => setState(() => _route = AppRoute.search),
          onJournal: () => setState(() => _route = AppRoute.journal),
          onShowProduct: (product) async {
            if (product.barcode != null && product.criteriaRatings.isEmpty) {
              final realProduct = await widget.onSearchBarcode(product.barcode!);
              if (realProduct != null && mounted) {
                widget.onShowProduct(realProduct);
                setState(() => _route = AppRoute.detail);
              }
            } else {
              widget.onShowProduct(product);
              setState(() => _route = AppRoute.detail);
            }
          },
          onClearHistory: widget.onClearHistory,
          onDeleteProduct: widget.onDeleteProduct,
        ),
      AppRoute.scan => ScanScreen(
          loading: widget.loading,
          error: widget.error,
          onBack: () => setState(() => _route = AppRoute.home),
          onFound: (barcode) async {
            final product = await widget.onSearchBarcode(barcode);
            if (product != null && mounted) setState(() => _route = AppRoute.detail);
          },
        ),
      AppRoute.detail => widget.currentProduct == null
          ? EmptyState(onBack: () => setState(() => _route = AppRoute.home))
          : ProductDetailScreen(
              product: widget.currentProduct!,
              onBack: () => setState(() => _route = AppRoute.home),
              onSwap: () => setState(() => _route = AppRoute.swap),
            ),
      AppRoute.swap => SwapScreen(
          onBack: () => setState(() => _route = AppRoute.detail),
          onClose: () => setState(() => _route = AppRoute.home),
        ),
      AppRoute.profile => ProfileScreen(
          user: widget.user,
          onBack: () => setState(() => _route = AppRoute.home),
          onLogout: widget.onLogout,
          onUpdateNickname: widget.onUpdateNickname,
          onDeleteAccount: widget.onDeleteAccount,
        ),
      AppRoute.search => SearchScreen(
          history: widget.history,
          onBack: () => setState(() => _route = AppRoute.home),
          onShowProduct: (product) async {
            if (product.barcode != null && product.criteriaRatings.isEmpty) {
              final realProduct = await widget.onSearchBarcode(product.barcode!);
              if (realProduct != null && mounted) {
                widget.onShowProduct(realProduct);
                setState(() => _route = AppRoute.detail);
              }
            } else {
              widget.onShowProduct(product);
              setState(() => _route = AppRoute.detail);
            }
          },
        ),
      AppRoute.journal => JournalScreen(
          onBack: () => setState(() => _route = AppRoute.home),
          onShowProduct: (product) {
            widget.onShowProduct(product);
            setState(() => _route = AppRoute.detail);
          },
        ),
    };
    return AdaptiveScreen(child: body);
  }
}

enum AppRoute { home, scan, detail, swap, profile, search, journal }
