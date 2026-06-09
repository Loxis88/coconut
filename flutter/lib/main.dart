import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'data/api_client.dart';
import 'data/auth_repository.dart';
import 'data/product_repository.dart';
import 'domain/auth_user.dart';
import 'domain/product.dart';
import 'widgets/email_auth_sheet.dart';

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

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _authRepository = AuthRepository(_api);
    _productRepository = ProductRepository(_api);
    _bootstrap();
  }

  @override
  void dispose() {
    _historySub?.cancel();
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

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authRepository.signInWithGoogle();
      final token = await _authRepository.accessToken();
      if (token != null) await _productRepository.syncHistory(token);
      setState(() => _user = user);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _emailLogin(String email, String password) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authRepository.signInWithEmail(email, password);
      final token = await _authRepository.accessToken();
      if (token != null) await _productRepository.syncHistory(token);
      setState(() => _user = user);
    } catch (error) {
      setState(() => _error = error.toString());
      rethrow;
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _emailRegister(String email, String password, String nickname) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authRepository.registerWithEmail(email, password, nickname);
    } catch (error) {
      setState(() => _error = error.toString());
      rethrow;
    } finally {
      setState(() => _loading = false);
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
                  onGoogleLogin: _login,
                  onEmailLogin: _emailLogin,
                  onEmailRegister: _emailRegister,
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
          onShowProduct: (product) {
            widget.onShowProduct(product);
            setState(() => _route = AppRoute.detail);
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
    };
    return AdaptiveScreen(child: body);
  }
}

enum AppRoute { home, scan, detail, swap, profile }

class AuthScreen extends StatelessWidget {
  const AuthScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.onGoogleLogin,
    required this.onEmailLogin,
    required this.onEmailRegister,
  });

  final bool loading;
  final String? error;
  final VoidCallback onGoogleLogin;
  final Future<void> Function(String email, String password) onEmailLogin;
  final Future<void> Function(String email, String password, String nickname) onEmailRegister;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScreen(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size.infinite, painter: GlowPainter()),
                const CoconutMark(size: 180),
                const Positioned(left: 28, top: 70, child: ScoreChip(score: 92, big: true)),
                const Positioned(right: 36, top: 120, child: ScoreChip(score: 48, big: true)),
                const Positioned(left: 36, bottom: 140, child: ScoreChip(score: 71, big: true)),
                const Positioned(right: 40, bottom: 90, child: ScoreChip(score: 88, big: true)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Coconut.', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, height: .96)),
                const SizedBox(height: 10),
                const Text(
                  'Раскуси каждый кусочек. Получи честную оценку любого продукта в один скан.',
                  style: TextStyle(color: Coco.ink2, fontSize: 19, height: 1.3),
                ),
                const SizedBox(height: 24),
                if (loading)
                  const CenteredLoader(compact: true)
                else ...[
                  PillButton(label: 'Войти через Google', kind: PillKind.brand, onTap: onGoogleLogin),
                  const SizedBox(height: 12),
                  PillButton(label: 'Войти через Apple ID', kind: PillKind.ink, onTap: () {}),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'Войти по почте',
                    kind: PillKind.ghost,
                    icon: Icons.email,
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => EmailAuthSheet(onLogin: onEmailLogin, onRegister: onEmailRegister),
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Coco.red)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.history,
    required this.average,
    required this.streak,
    required this.onScan,
    required this.onProfile,
    required this.onShowProduct,
    required this.onClearHistory,
    required this.onDeleteProduct,
  });

  final AuthUser user;
  final List<Product> history;
  final int average;
  final int streak;
  final VoidCallback onScan;
  final VoidCallback onProfile;
  final void Function(Product product) onShowProduct;
  final Future<void> Function() onClearHistory;
  final Future<void> Function(Product product) onDeleteProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Row(
            children: [
              const CoconutMark(size: 36),
              const SizedBox(width: 10),
              const Expanded(child: Text('Coconut', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
              SmallCounter(icon: Icons.local_fire_department, value: streak),
              RoundIcon(icon: Icons.notifications_none, onTap: () {}),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              const Text('Сегодня', style: TextStyle(color: Coco.muted, fontWeight: FontWeight.w700)),
              Text(
                'Привет, ${user.nickname ?? 'Пользователь'}\nвсе идет по плану.',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.05),
              ),
              const SizedBox(height: 14),
              CocoCard(
                gradient: Coco.brandGradient,
                child: Row(
                  children: [
                    ScoreRing(score: history.isEmpty ? 0 : average, size: 120, showLabel: false),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('СРЕДНИЙ БАЛЛ', style: TextStyle(color: Coco.brownDeep, fontWeight: FontWeight.w900)),
                          Text(
                            history.isEmpty ? 'Сканируй' : 'Пока\nнеплохо.',
                            style: const TextStyle(color: Coco.brownDeep, fontSize: 26, fontWeight: FontWeight.w900, height: 1.05),
                          ),
                          Text('${history.length} total scans', style: const TextStyle(color: Coco.brownDeep)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CocoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Эта неделя', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                        Text('ср. балл ${history.isEmpty ? 0 : average}', style: const TextStyle(color: Coco.muted)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    WeekBars(values: [0, 0, 0, 0, 0, 0, history.isEmpty ? 0 : average]),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(child: Text('История', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                  TextButton(onPressed: onClearHistory, child: const Text('Очистить', style: TextStyle(color: Coco.red))),
                ],
              ),
              CocoCard(
                padding: const EdgeInsets.all(6),
                child: history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Пока ничего нет. Нажми кнопку сканирования, чтобы начать!', style: TextStyle(color: Coco.muted)),
                      )
                    : Column(
                        children: history
                            .map(
                              (product) => Dismissible(
                                key: ValueKey(product.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 22),
                                  margin: const EdgeInsets.symmetric(vertical: 3),
                                  decoration: BoxDecoration(color: Coco.red, borderRadius: BorderRadius.circular(16)),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) => onDeleteProduct(product),
                                child: ProductRow(product: product, onTap: () => onShowProduct(product)),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        BottomNav(onScan: onScan, onProfile: onProfile),
      ],
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.onBack,
    required this.onFound,
  });

  final bool loading;
  final String? error;
  final VoidCallback onBack;
  final Future<void> Function(String barcode) onFound;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(torchEnabled: false);
  final _manualController = TextEditingController();
  var _manual = false;
  var _lastBarcode = '';

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!_manual)
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;
              final barcode = capture.barcodes.first.rawValue;
              if (barcode != null && barcode != _lastBarcode) {
                _lastBarcode = barcode;
                widget.onFound(barcode);
              }
            },
          )
        else
          Container(color: Coco.ink),
        Positioned.fill(child: CustomPaint(painter: ScannerFramePainter())),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    RoundIcon(icon: Icons.arrow_back, dark: true, onTap: widget.onBack),
                    const Spacer(),
                    RoundIcon(
                      icon: _manual ? Icons.document_scanner : Icons.edit_note,
                      dark: true,
                      onTap: () => setState(() => _manual = !_manual),
                    ),
                    const SizedBox(width: 8),
                    RoundIcon(icon: Icons.flash_on, dark: true, onTap: () => _controller.toggleTorch()),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Coco.cream, borderRadius: BorderRadius.circular(28)),
                child: _manual ? _manualInput() : _autoScanHint(),
              ),
            ],
          ),
        ),
        if (widget.loading) Container(color: Colors.black45, child: const CenteredLoader(compact: true)),
        if (widget.error != null)
          Container(
            color: Colors.black54,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Товар не найден', style: TextStyle(color: Coco.red, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Text(widget.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    PillButton(label: 'Сканировать снова', onTap: () => setState(() => _lastBarcode = '')),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _autoScanHint() => Row(
        children: const [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Автоскан активен', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text('Наведи камеру на штрих-код.', style: TextStyle(color: Coco.muted)),
              ],
            ),
          ),
          CircleIcon(icon: Icons.camera_alt),
        ],
      );

  Widget _manualInput() => Column(
        children: [
          TextField(
            controller: _manualController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Введите штрих-код',
              hintText: 'например 4603955002165',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ручной ввод', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    Text('Введите штрих-код для поиска.', style: TextStyle(color: Coco.muted)),
                  ],
                ),
              ),
              InkWell(
                onTap: () => widget.onFound(_manualController.text),
                child: const CircleIcon(icon: Icons.center_focus_strong),
              ),
            ],
          ),
        ],
      );
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product, required this.onBack, required this.onSwap});

  final Product product;
  final VoidCallback onBack;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final tier = scoreTier(product.score);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              RoundIcon(icon: Icons.arrow_back, onTap: onBack),
              const Spacer(),
              RoundIcon(icon: Icons.favorite_border, onTap: () {}),
              RoundIcon(icon: Icons.swap_horiz, onTap: onSwap),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductThumb(product: product, size: 88, radius: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (product.manufacturer.isNotEmpty ? product.manufacturer : product.categoryName).toUpperCase(),
                          style: const TextStyle(color: Coco.muted, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                        Text(product.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
                        if (product.price.isNotEmpty) Text(product.price, style: const TextStyle(color: Coco.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              CocoCard(
                color: tier.background,
                child: Row(
                  children: [
                    ScoreRing(score: product.score, size: 104, showLabel: false),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${tier.label}.', style: TextStyle(color: tier.ink, fontSize: 26, fontWeight: FontWeight.w900)),
                          Text(
                            product.worth.firstOrNullText('Рейтинг по стандартам Coconut.'),
                            style: TextStyle(color: tier.ink.withOpacity(.75), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (product.nutrients != null) ...[
                const SectionTitle('Пищевая ценность'),
                NutrientGrid(nutrients: product.nutrients!),
              ],
              if ((product.composition ?? '').isNotEmpty) ...[
                const SectionTitle('Состав'),
                CocoCard(child: Text(product.composition!)),
              ],
              const SectionTitle('Критерии качества'),
              CocoCard(
                child: product.criteriaRatings.isEmpty
                    ? const Text('Детальные критерии отсутствуют.', style: TextStyle(color: Coco.muted))
                    : Column(
                        children: product.criteriaRatings
                            .map((item) => AxisRow(label: item.title, value: (item.value * 20).round(), note: '${item.value} / 5'))
                            .toList(),
                      ),
              ),
              if (product.worth.isNotEmpty) ...[
                const SectionTitle('Стоит отметить'),
                ...product.worth.map((item) => Flag(text: item)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.onBack,
    required this.onLogout,
    required this.onUpdateNickname,
    required this.onDeleteAccount,
  });

  final AuthUser user;
  final VoidCallback onBack;
  final Future<void> Function() onLogout;
  final Future<void> Function(String nickname) onUpdateNickname;
  final Future<void> Function() onDeleteAccount;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nickname;
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(text: widget.user.nickname ?? '');
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              RoundIcon(icon: Icons.arrow_back, onTap: widget.onBack),
              const SizedBox(width: 8),
              const Expanded(child: Text('Профиль', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Coco.lime,
                  child: Icon(Icons.person, size: 60, color: Coco.brownDeep),
                ),
                const SizedBox(height: 24),
                if (_editing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 200, child: TextField(controller: _nickname)),
                      RoundIcon(
                        icon: Icons.save,
                        onTap: () async {
                          await widget.onUpdateNickname(_nickname.text);
                          setState(() => _editing = false);
                        },
                      ),
                      RoundIcon(icon: Icons.cancel, onTap: () => setState(() => _editing = false)),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.user.nickname ?? 'User', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                      IconButton(onPressed: () => setState(() => _editing = true), icon: const Icon(Icons.edit, size: 18)),
                    ],
                  ),
                const Text('Premium Member', style: TextStyle(color: Coco.muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                CocoCard(
                  child: Column(
                    children: [
                      InfoRow(label: 'Email', value: widget.user.email),
                      const Divider(),
                      InfoRow(label: 'ID', value: widget.user.id.isEmpty ? '-' : 'COCO-${widget.user.id.substring(0, min(8, widget.user.id.length)).toUpperCase()}'),
                      const Divider(),
                      const InfoRow(label: 'Статус', value: 'Активен'),
                    ],
                  ),
                ),
                const Spacer(),
                PillButton(label: 'Выйти из аккаунта', kind: PillKind.ghost, icon: Icons.logout, onTap: widget.onLogout),
                const SizedBox(height: 12),
                PillButton(
                  label: 'Удалить аккаунт',
                  kind: PillKind.ghost,
                  icon: Icons.delete,
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Удалить аккаунт?'),
                      content: const Text('Вы уверены, что хотите безвозвратно удалить свой аккаунт и все данные?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await widget.onDeleteAccount();
                          },
                          child: const Text('Удалить', style: TextStyle(color: Coco.red)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SwapScreen extends StatelessWidget {
  const SwapScreen({super.key, required this.onBack, required this.onClose});

  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              RoundIcon(icon: Icons.arrow_back, onTap: onBack),
              const SizedBox(width: 8),
              const Expanded(child: Text('Лучшая замена', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
              RoundIcon(icon: Icons.close, onTap: onClose),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              const SwapCard(),
              const SectionTitle('Почему это лучше?'),
              CocoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: const [
                    DeltaRow(label: 'Сахар', from: '24г', to: '14г'),
                    Divider(),
                    DeltaRow(label: 'Жиры', from: '18г', to: '12г'),
                    Divider(),
                    DeltaRow(label: 'Добавки', from: 'E471, E412', to: 'Нет'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              PillButton(label: 'Выбрать этот продукт', kind: PillKind.brand, onTap: onClose),
            ],
          ),
        ),
      ],
    );
  }
}

class Coco {
  static const cream = Color(0xfffff6e8);
  static const cream2 = Color(0xfffbefd9);
  static const ink = Color(0xff1a1410);
  static const ink2 = Color(0xff3d332b);
  static const muted = Color(0xff7a6b5c);
  static const hairline = Color(0x151a1410);
  static const lime = Color(0xffbef264);
  static const emerald = Color(0xff10b981);
  static const emeraldDeep = Color(0xff047857);
  static const amber = Color(0xfff59e0b);
  static const coral = Color(0xfff97316);
  static const red = Color(0xffe11d48);
  static const brownDeep = Color(0xff3f2412);
  static const brandGradient = LinearGradient(colors: [lime, emerald, emeraldDeep]);
}

class Tier {
  const Tier(this.label, this.color, this.background, this.ink);
  final String label;
  final Color color;
  final Color background;
  final Color ink;
}

Tier scoreTier(int score) {
  if (score >= 80) return const Tier('Супер', Coco.emerald, Color(0xffd7f5e6), Color(0xff04432a));
  if (score >= 60) return const Tier('Норма', Color(0xffa3b91d), Color(0xfff0f6cf), Color(0xff3a4407));
  if (score >= 40) return const Tier('Спорно', Coco.coral, Color(0xffffe2cc), Color(0xff5a1f00));
  return const Tier('Мусор', Coco.red, Color(0xffffd9df), Color(0xff5c0716));
}

class AdaptiveScreen extends StatelessWidget {
  const AdaptiveScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Coco.cream,
        child: SafeArea(
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: child)),
        ),
      ),
    );
  }
}

class CenteredLoader extends StatelessWidget {
  const CenteredLoader({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: compact ? 32 : 48,
          height: compact ? 32 : 48,
          child: const CircularProgressIndicator(color: Coco.emerald),
        ),
      );
}

class CoconutMark extends StatelessWidget {
  const CoconutMark({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: CoconutPainter());
}

class CoconutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = Coco.brandGradient.createShader(Offset.zero & size);
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
    final eye = Paint()..color = Coco.ink;
    for (final point in [Offset(.35, .42), Offset(.64, .42), Offset(.49, .66)]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * point.dx, size.height * point.dy), width: size.width * .1, height: size.height * .14),
        eye,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const RadialGradient(colors: [Color(0x55bef264), Colors.transparent]).createShader(
        Rect.fromCircle(center: Offset(size.width * .5, size.height * .42), radius: size.shortestSide * .62),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ScoreChip extends StatelessWidget {
  const ScoreChip({super.key, required this.score, this.big = false});
  final int score;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final tier = scoreTier(score);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 14 : 10, vertical: big ? 8 : 4),
      decoration: BoxDecoration(color: tier.color, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$score', style: TextStyle(color: Colors.white, fontSize: big ? 18 : 13, fontWeight: FontWeight.w900)),
          Text('/100', style: TextStyle(color: Colors.white70, fontSize: big ? 12 : 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

enum PillKind { ink, brand, ghost }

class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, this.icon, this.kind = PillKind.ink, required this.onTap});
  final String label;
  final IconData? icon;
  final PillKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      PillKind.ink => Coco.ink,
      PillKind.brand => null,
      PillKind.ghost => Coco.hairline,
    };
    final content = switch (kind) {
      PillKind.brand => Coco.brownDeep,
      PillKind.ink => Colors.white,
      PillKind.ghost => label.contains('Удалить') || label.contains('Выйти') ? Coco.red : Coco.ink,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          gradient: kind == PillKind.brand ? Coco.brandGradient : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: content, fontSize: 17, fontWeight: FontWeight.w900)),
            if (icon != null) ...[const SizedBox(width: 8), Icon(icon, color: content, size: 20)],
          ],
        ),
      ),
    );
  }
}

class CocoCard extends StatelessWidget {
  const CocoCard({super.key, required this.child, this.color = Colors.white, this.gradient, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final Color color;
  final Gradient? gradient;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: gradient == null ? color : null, gradient: gradient, borderRadius: BorderRadius.circular(24)),
        child: child,
      );
}

class RoundIcon extends StatelessWidget {
  const RoundIcon({super.key, required this.icon, required this.onTap, this.dark = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: dark ? Colors.white : Coco.ink),
        style: IconButton.styleFrom(backgroundColor: dark ? Colors.white24 : Coco.hairline),
      );
}

class CircleIcon extends StatelessWidget {
  const CircleIcon({super.key, required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Coco.brandGradient),
        child: Icon(icon, color: Coco.brownDeep, size: 30),
      );
}

class SmallCounter extends StatelessWidget {
  const SmallCounter({super.key, required this.icon, required this.value});
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
        child: Row(children: [Icon(icon, color: value > 0 ? Coco.coral : Coco.muted, size: 16), Text('$value')]),
      );
}

class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, required this.size, this.showLabel = true});
  final int score;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final tier = scoreTier(score);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size.square(size), painter: RingPainter(score: score, color: tier.color)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score', style: TextStyle(fontSize: size * .42, fontWeight: FontWeight.w900, height: .9)),
              if (showLabel) Text(tier.label.toUpperCase(), style: TextStyle(color: tier.color, fontSize: size * .1, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  RingPainter({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const thickness = 12.0;
    final rect = Rect.fromLTWH(thickness / 2, thickness / 2, size.width - thickness, size.height - thickness);
    final bg = Paint()
      ..color = Coco.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, pi * 2, false, bg);
    canvas.drawArc(rect, -pi / 2, pi * 2 * (score / 100), false, fg);
  }

  @override
  bool shouldRepaint(RingPainter oldDelegate) => oldDelegate.score != score || oldDelegate.color != color;
}

class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.values});
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    const labels = ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'];
    return SizedBox(
      height: 86,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final value = values[index].clamp(0, 100);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: value / 100,
                        widthFactor: 1,
                        child: Container(decoration: BoxDecoration(color: scoreTier(value).color, borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                  ),
                  Text(labels[index], style: TextStyle(color: index == values.length - 1 ? Coco.ink : Coco.muted, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              ProductThumb(product: product, size: 52, radius: 16),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      product.manufacturer.isNotEmpty ? product.manufacturer : product.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Coco.muted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              ScoreChip(score: product.score),
            ],
          ),
        ),
      );
}

class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.product, required this.size, required this.radius});
  final Product product;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (product.thumbnail != null && product.thumbnail!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(imageUrl: product.thumbnail!, width: size, height: size, fit: BoxFit.cover),
      );
    }
    final label = product.title.isEmpty ? '?' : product.title.characters.first;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xffffe4b5), borderRadius: BorderRadius.circular(radius)),
      child: Center(child: Text(label, style: TextStyle(color: Coco.coral, fontSize: size * .38, fontWeight: FontWeight.w900))),
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.onScan, required this.onProfile});
  final VoidCallback onScan;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavItem(icon: Icons.home, label: 'Главная', active: true, onTap: () {}),
            NavItem(icon: Icons.edit_note, label: 'Журнал', active: false, onTap: () {}),
            InkWell(onTap: onScan, child: const Column(children: [CircleIcon(icon: Icons.center_focus_strong), Text('Скан')])),
            NavItem(icon: Icons.groups, label: 'Друзья', active: false, onTap: () {}),
            NavItem(icon: Icons.person, label: 'Профиль', active: false, onTap: onProfile),
          ],
        ),
      );
}

class NavItem extends StatelessWidget {
  const NavItem({super.key, required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 58,
          child: Column(
            children: [
              Icon(icon, color: active ? Coco.ink : Coco.muted),
              Text(label, style: TextStyle(color: active ? Coco.ink : Coco.muted, fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
            ],
          ),
        ),
      );
}

class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * .65;
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    final paint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 34.0;
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, len), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, len), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -len), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class NutrientGrid extends StatelessWidget {
  const NutrientGrid({super.key, required this.nutrients});
  final Nutrients nutrients;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(children: [
            NutrientCell(label: 'Белки', value: nutrients.proteins ?? '-'),
            NutrientCell(label: 'Жиры', value: nutrients.fats ?? '-'),
            NutrientCell(label: 'Углеводы', value: nutrients.carbohydrates ?? '-'),
          ]),
          Row(children: [
            NutrientCell(label: 'Ккал', value: nutrients.calories ?? '-'),
            if (nutrients.fiber != null) NutrientCell(label: 'Клетчатка', value: nutrients.fiber!),
          ]),
        ],
      );
}

class NutrientCell extends StatelessWidget {
  const NutrientCell({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(label.toUpperCase(), style: const TextStyle(color: Coco.muted, fontSize: 10, fontWeight: FontWeight.w900)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      );
}

class AxisRow extends StatelessWidget {
  const AxisRow({super.key, required this.label, required this.value, required this.note});
  final String label;
  final int value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final tier = scoreTier(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))), Text('$value', style: TextStyle(color: tier.color))]),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: value / 100, color: tier.color, backgroundColor: Coco.hairline),
          Text(note, style: const TextStyle(color: Coco.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class Flag extends StatelessWidget {
  const Flag({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CocoCard(
          child: Row(children: [
            const CircleAvatar(backgroundColor: Coco.emerald, child: Icon(Icons.check, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: Coco.muted, fontWeight: FontWeight.w600))),
          ]),
        ),
      );
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Text(label, style: const TextStyle(color: Coco.muted, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );
}

class SwapCard extends StatelessWidget {
  const SwapCard({super.key});

  @override
  Widget build(BuildContext context) => CocoCard(
        child: Column(children: const [
          ProductLetter(label: 'Ч'),
          SizedBox(height: 8),
          Text('Чистая Линия', style: TextStyle(fontWeight: FontWeight.w900)),
          Text('Мороженое Пломбир ванильный в вафельном стаканчике', textAlign: TextAlign.center, style: TextStyle(color: Coco.muted)),
          Text('95', style: TextStyle(color: Coco.emerald, fontSize: 32, fontWeight: FontWeight.w900)),
        ]),
      );
}

class ProductLetter extends StatelessWidget {
  const ProductLetter({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(color: const Color(0xffd9f99d), borderRadius: BorderRadius.circular(18)),
        child: Center(child: Text(label, style: const TextStyle(color: Coco.emerald, fontSize: 28, fontWeight: FontWeight.w900))),
      );
}

class DeltaRow extends StatelessWidget {
  const DeltaRow({super.key, required this.label, required this.from, required this.to});
  final String label;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(from, style: const TextStyle(color: Coco.muted, decoration: TextDecoration.lineThrough)),
          const Icon(Icons.arrow_forward, size: 14, color: Coco.muted),
          Text(to, style: const TextStyle(color: Coco.emerald, fontWeight: FontWeight.w900)),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PillButton(label: 'Назад', onTap: onBack),
        ),
      );
}

extension _StringListX on List<String> {
  String firstOrNullText(String fallback) => isEmpty ? fallback : first;
}
