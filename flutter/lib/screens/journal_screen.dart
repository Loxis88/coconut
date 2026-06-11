import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/product.dart';
import '../theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, required this.history, required this.onShowProduct});

  final List<Product> history;
  final void Function(Product product) onShowProduct;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String _filter = 'all';
  final Set<int> _favs = {};

  @override
  void initState() {
    super.initState();
    if (widget.history.isNotEmpty) {
      _favs.add(widget.history.first.id); // Default mock fav
    }
  }

  void _toggleFav(int id) {
    setState(() {
      if (_favs.contains(id)) {
        _favs.remove(id);
      } else {
        _favs.add(id);
      }
    });
  }

  List<Product> get _visible {
    return widget.history.where((p) {
      if (_filter == 'good') return p.score >= 75;
      if (_filter == 'mid') return p.score >= 35 && p.score < 75;
      if (_filter == 'bad') return p.score < 35;
      if (_filter == 'fav') return _favs.contains(p.id);
      return true;
    }).toList();
  }

  Color _getScoreColor(int score) {
    if (score >= 75) return MayakTheme.scoreExcellent;
    if (score >= 35) return MayakTheme.scoreModerate;
    return MayakTheme.scorePoor;
  }

  String _getScoreLabel(int score) {
    if (score >= 75) return 'ОТЛИЧНО';
    if (score >= 35) return 'СПОРНО';
    return 'ПЛОХО';
  }

  @override
  Widget build(BuildContext context) {
    final avg = widget.history.isEmpty
        ? 0
        : (widget.history.map((e) => e.score).reduce((a, b) => a + b) / widget.history.length).round();

    final countGood = widget.history.where((p) => p.score >= 75).length;
    final countMid = widget.history.where((p) => p.score >= 35 && p.score < 75).length;
    final countBad = widget.history.where((p) => p.score < 35).length;

    final visible = _visible;

    return Container(
      color: MayakTheme.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('История', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 26, color: const Color(0xFF0C1A09), letterSpacing: 26 * -0.025)),
                          const SizedBox(height: 2),
                          Text('${widget.history.length} продуктов за 30 дней', style: GoogleFonts.dmMono(fontSize: 11, color: const Color(0xFF5E6859))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$avg', style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 36, color: _getScoreColor(avg), height: 1)),
                          const SizedBox(height: 2),
                          Text('СРЕДНИЙ БАЛЛ', style: GoogleFonts.dmMono(fontSize: 9, color: const Color(0xFF5E6859), letterSpacing: 9 * 0.04)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stat row
                  Row(
                    children: [
                      Expanded(child: _StatBox(label: 'Отлично', count: countGood, color: const Color(0xFF1E6B28))),
                      const SizedBox(width: 8),
                      Expanded(child: _StatBox(label: 'Хорошо', count: countMid, color: const Color(0xFF4A9152))),
                      const SizedBox(width: 8),
                      Expanded(child: _StatBox(label: 'Плохо', count: countBad, color: const Color(0xFFC03B32))),
                      const SizedBox(width: 8),
                      Expanded(child: _StatBox(label: 'Избранные', count: _favs.length, color: const Color(0xFFB87D28))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(id: 'all', label: 'Все', activeId: _filter, onSelect: (id) => setState(() => _filter = id)),
                        _FilterChip(id: 'good', label: '≥ 75', activeId: _filter, onSelect: (id) => setState(() => _filter = id)),
                        _FilterChip(id: 'mid', label: '35–74', activeId: _filter, onSelect: (id) => setState(() => _filter = id)),
                        _FilterChip(id: 'bad', label: '< 35', activeId: _filter, onSelect: (id) => setState(() => _filter = id)),
                        _FilterChip(id: 'fav', label: 'Избранные', activeId: _filter, onSelect: (id) => setState(() => _filter = id)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Пусто', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0C1A09))),
                          const SizedBox(height: 12),
                          Text('Измените фильтр', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF5E6859))),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
                        Text('ПОСЛЕДНИЕ 30 ДНЕЙ', style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486), letterSpacing: 10 * 0.06)),
                        const SizedBox(height: 10),
                        ...visible.asMap().entries.map((entry) {
                          final i = entry.key;
                          final p = entry.value;
                          final isFav = _favs.contains(p.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => widget.onShowProduct(p),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F0E6),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(color: const Color(0xFFDDD8CB), borderRadius: BorderRadius.circular(12)),
                                      clipBehavior: Clip.antiAlias,
                                      child: p.thumbnail != null
                                          ? Image.network(p.thumbnail!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.fastfood, color: Colors.white))
                                          : const Icon(Icons.fastfood, color: Colors.white),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.title, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0C1A09)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          Text(p.manufacturer, style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF5E6859)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 1),
                                          Text('Сегодня', style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486))),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${p.score}', style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 24, color: _getScoreColor(p.score), height: 1)),
                                        const SizedBox(height: 2),
                                        Text(_getScoreLabel(p.score), style: GoogleFonts.dmMono(fontSize: 9, color: _getScoreColor(p.score), letterSpacing: 9 * 0.03)),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _toggleFav(p.id),
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          color: isFav ? const Color(0xFFC03B32) : const Color(0xFFB8C0B4),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(duration: 200.ms, delay: (i * 40).ms).slideY(begin: 0.1, duration: 200.ms, delay: (i * 40).ms),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBox({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF4F0E6), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$count', style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 20, color: color, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmMono(fontSize: 9, color: const Color(0xFF5E6859), letterSpacing: 9 * 0.04)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String id;
  final String label;
  final String activeId;
  final ValueChanged<String> onSelect;

  const _FilterChip({required this.id, required this.label, required this.activeId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final active = id == activeId;
    return GestureDetector(
      onTap: () => onSelect(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF153918) : const Color(0xFFF4F0E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : const Color(0xFF5E6859),
          ),
        ),
      ),
    );
  }
}
