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
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/search_screen.dart';
import 'screens/swap_screen.dart';
import 'theme.dart';
import 'widgets/adaptive_screen.dart';
import 'widgets/bottom_nav.dart';
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
  bool _loading = false;
  AppPhase _phase = AppPhase.splash;
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
    if (mounted) {
      setState(() {
        _user = cached;
      });
    }
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

  void _onSplashComplete() {
    if (_user != null) {
      setState(() => _phase = AppPhase.app);
    } else {
      setState(() => _phase = AppPhase.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'МАЯК',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: MayakTheme.primary, background: MayakTheme.bg),
        scaffoldBackgroundColor: MayakTheme.bg,
        fontFamily: 'DM Sans', // Set in pubspec / google_fonts ideally, or here
        useMaterial3: true,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (_phase) {
          AppPhase.splash => SplashScreen(key: const ValueKey('splash'), onComplete: _onSplashComplete),
          AppPhase.onboarding => OnboardingScreen(key: const ValueKey('onboarding'), onComplete: () => setState(() => _phase = AppPhase.auth)),
          AppPhase.auth => AuthScreen(
              key: const ValueKey('auth'),
              loading: _loading,
              error: _error,
              onLogin: (email, password) async {
                setState(() { _error = null; _loading = true; });
                try {
                  final user = await _authRepository.login(email, password);
                  final token = await _authRepository.accessToken();
                  if (token != null) await _productRepository.syncHistory(token);
                  setState(() { _user = user; _phase = AppPhase.app; });
                } catch (e) {
                  setState(() => _error = e.toString());
                  rethrow;
                } finally {
                  setState(() => _loading = false);
                }
              },
              onRegister: (email, password) async {
                setState(() { _error = null; _loading = true; });
                try {
                  await _authRepository.register(email, password);
                } catch (e) {
                  setState(() => _error = e.toString());
                  rethrow;
                } finally {
                  setState(() => _loading = false);
                }
              },
            ),
          AppPhase.app => HomeShell(
              key: const ValueKey('app'),
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
              onLogout: () async {
                await _logout();
                setState(() => _phase = AppPhase.auth);
              },
              onUpdateNickname: (nickname) async {
                final updated = await _authRepository.updateNickname(nickname);
                setState(() => _user = updated);
              },
              onDeleteAccount: () async {
                await _authRepository.deleteAccount();
                setState(() => _phase = AppPhase.auth);
              },
            ),
        },
      ),
    );
  }
}

enum AppPhase { splash, onboarding, auth, app }

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
          onNavigateToHistory: () => setState(() => _route = AppRoute.journal),
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
          streak: widget.streak,
          average: widget.average,
          scanCount: widget.history.length,
          onBack: () => setState(() => _route = AppRoute.home),
          onLogout: widget.onLogout,
          onUpdateNickname: widget.onUpdateNickname,
          onDeleteAccount: widget.onDeleteAccount,
        ),
      AppRoute.search => SearchScreen(
          history: widget.history,
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
          onShowProduct: (product) {
            widget.onShowProduct(product);
            setState(() => _route = AppRoute.detail);
          },
        ),
    };

    final showNav = _route == AppRoute.home || _route == AppRoute.search || _route == AppRoute.journal || _route == AppRoute.profile;

    return AdaptiveScreen(
      child: body,
      bottomNav: showNav ? BottomNav(
        currentRoute: _route,
        onRouteChanged: (r) => setState(() => _route = r),
      ) : null,
    );
  }
}

enum AppRoute { home, scan, detail, swap, profile, search, journal }
