import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/product.dart';
import '../theme.dart';
import '../widgets/product_widgets.dart';

const _categories = [
  {'label': 'Молочные', 'icon': '🥛', 'key': 'Молочные продукты'},
  {'label': 'Сладости', 'icon': '🍫', 'key': 'Сладости'},
  {'label': 'Снеки', 'icon': '🥨', 'key': 'Снеки'},
  {'label': 'Напитки', 'icon': '🥤', 'key': 'Напитки'},
  {'label': 'Крупы', 'icon': '🌾', 'key': 'Крупы'},
  {'label': 'Мясо', 'icon': '🥩', 'key': 'Мясо'},
];

const _scoreFilters = [
  {'key': 'all', 'label': 'Все', 'color': Color(0xFF5E6859)},
  {'key': 'good', 'label': 'Хорошие', 'color': Color(0xFF1E6B28)},
  {'key': 'ok', 'label': 'Средние', 'color': Color(0xFFB87D28)},
  {'key': 'bad', 'label': 'Плохие', 'color': Color(0xFFC03B32)},
];


class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.history,
    required this.onShowProduct,
    required this.onLoadCatalog,
  });

  final List<Product> history;
  final void Function(Product product) onShowProduct;
  final Future<List<Product>> Function({String? category, String score, int limit, int offset}) onLoadCatalog;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollCtrl = ScrollController();

  String _query = '';
  bool _focused = false;
  String? _categoryFilter;
  String _scoreFilter = 'all';

  List<Product> _catalog = const [];
  bool _catalogLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
    _scrollCtrl.addListener(_onScroll);
    _loadCatalog();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadCatalog({String? category}) async {
    setState(() {
      _catalogLoading = true;
      _offset = 0;
      _hasMore = true;
      _catalog = const [];
    });
    try {
      final items = await widget.onLoadCatalog(category: category, score: 'all', limit: _pageSize, offset: 0);
      if (mounted) {
        setState(() {
          _catalog = items;
          _offset = items.length;
          _hasMore = items.length >= _pageSize;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _catalogLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _catalogLoading) return;
    setState(() => _loadingMore = true);
    try {
      final items = await widget.onLoadCatalog(
        category: _categoryFilter,
        score: 'all',
        limit: _pageSize,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          _catalog = [..._catalog, ...items];
          _offset += items.length;
          _hasMore = items.length >= _pageSize;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  bool _matchScore(int score, String filter) {
    if (filter == 'good') return score >= 70;
    if (filter == 'ok') return score >= 40 && score < 70;
    if (filter == 'bad') return score < 40;
    return true;
  }

  List<Product> get _results {
    final q = _query.trim().toLowerCase();
    return _catalog.where((p) {
      final matchText = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.manufacturer.toLowerCase().contains(q);
      final matchScore = _matchScore(p.score, _scoreFilter);
      return matchText && matchScore;
    }).toList();
  }


  void _clear() {
    _textCtrl.clear();
    _focusNode.unfocus();
    final hadCategory = _categoryFilter != null;
    setState(() {
      _query = '';
      _scoreFilter = 'all';
      if (hadCategory) {
        _categoryFilter = null;
        _catalog = const [];
        _catalogLoading = true;
        _offset = 0;
        _hasMore = true;
      }
    });
    if (hadCategory) _loadCatalog();
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return MayakTheme.scoreExcellent;
    if (score >= 40) return MayakTheme.scoreModerate;
    return MayakTheme.scorePoor;
  }

  String _getScoreLabel(int score) {
    if (score >= 70) return 'Хорошо';
    if (score >= 40) return 'Спорно';
    return 'Плохо';
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.trim().isNotEmpty || _categoryFilter != null;
    final results = _results;
    if (_catalogLoading && _catalog.isEmpty) {
      return Container(
        color: MayakTheme.bg,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      color: MayakTheme.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _focused ? const Color(0xFFF4F0E6) : const Color(0x120C1A09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _focused ? const Color(0x38153918) : Colors.transparent, width: 1.5),
                  boxShadow: _focused ? const [BoxShadow(color: Color(0x14153918), blurRadius: 16, offset: Offset(0, 4))] : [],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0x800C1A09), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        focusNode: _focusNode,
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.dmSans(fontSize: 15, color: const Color(0xFF0C1A09)),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Продукт, бренд или категория…',
                          hintStyle: GoogleFonts.dmSans(color: const Color(0x800C1A09)),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty || _categoryFilter != null)
                      GestureDetector(
                        onTap: _clear,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0x1A121A09), shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Color(0xFF5E6859)),
                        ),
                      ).animate().scale(duration: 150.ms),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: isSearching
                  ? _buildResults(results)
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Categories
        Text(
          'КАТЕГОРИИ',
          style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486), letterSpacing: 10 * 0.08),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return GestureDetector(
              onTap: () {
                final key = cat['key'] as String;
                setState(() {
                  _categoryFilter = key;
                  _catalog = const [];
                  _catalogLoading = true;
                  _offset = 0;
                  _hasMore = true;
                });
                _loadCatalog(category: key);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MayakTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cat['icon'] as String, style: const TextStyle(fontSize: 22, height: 1)),
                    const SizedBox(height: 6),
                    Text(
                      cat['label'] as String,
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF0C1A09)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        // Catalog
        Text(
          'ТОП ОЦЕНОК',
          style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486), letterSpacing: 10 * 0.08),
        ),
        const SizedBox(height: 10),
        ..._catalog.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ResultItem(product: p, onTap: () => widget.onShowProduct(p)),
            )),
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!_hasMore && _catalog.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('Все продукты загружены', style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486))),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildResults(List<Product> results) {
    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Filters
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (_categoryFilter != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _categoryFilter = null;
                    _catalog = const [];
                    _catalogLoading = true;
                    _offset = 0;
                    _hasMore = true;
                  });
                  _loadCatalog();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF153918), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_categories.firstWhere((c) => c['key'] == _categoryFilter)['icon']} ${_categories.firstWhere((c) => c['key'] == _categoryFilter)['label']}',
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.close, size: 12, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ..._scoreFilters.map((f) {
              final active = _scoreFilter == f['key'];
              final color = f['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _scoreFilter = f['key'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? color.withOpacity(0.1) : const Color(0x0F0C1A09),
                    border: Border.all(color: active ? color.withOpacity(0.25) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    f['label'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? color : const Color(0xFF5E6859),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),

        // Count
        Text(
          results.isNotEmpty ? '${results.length} результатов' : 'Ничего не найдено',
          style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486), letterSpacing: 10 * 0.04),
        ),
        const SizedBox(height: 10),

        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: const Color(0x0F0C1A09), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.search_off_rounded, color: Color(0xFF8A9486), size: 28),
                ),
                const SizedBox(height: 12),
                Text('Ничего не найдено', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF0C1A09))),
                const SizedBox(height: 4),
                Text(
                  'Попробуйте другой запрос или сбросьте фильтры',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF5E6859)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _clear,
                  style: TextButton.styleFrom(backgroundColor: const Color(0x1A153918), foregroundColor: const Color(0xFF153918), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Сбросить', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          )
        else
          ...results.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ResultItem(product: p, onTap: () => widget.onShowProduct(p)),
              )),
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!_hasMore && results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('Все продукты загружены', style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486))),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _ResultItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ResultItem({required this.product, required this.onTap});

  Color _getScoreColor(int score) {
    if (score >= 70) return MayakTheme.scoreExcellent;
    if (score >= 40) return MayakTheme.scoreModerate;
    return MayakTheme.scorePoor;
  }

  String _getScoreLabel(int score) {
    if (score >= 70) return 'Хорошо';
    if (score >= 40) return 'Спорно';
    return 'Плохо';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(product.score);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MayakTheme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))],
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: MayakTheme.muted, borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: product.thumbnail != null
                  ? NetImg(product.thumbnail!)
                  : const Icon(Icons.fastfood, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0C1A09)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(product.manufacturer, style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF5E6859)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${product.nutrients?.calories ?? 0} ккал', style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486))),
                      Container(margin: const EdgeInsets.symmetric(horizontal: 6), width: 2, height: 2, decoration: const BoxDecoration(color: Color(0xFFC4BFB4), shape: BoxShape.circle)),
                      Flexible(child: Text(product.categoryName, style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${product.score}', style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 20, color: color, height: 1)),
                const SizedBox(height: 1),
                Text(_getScoreLabel(product.score), style: GoogleFonts.dmMono(fontSize: 8, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

