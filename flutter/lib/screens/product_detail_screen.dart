import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/product.dart';
import '../theme.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onBack,
    required this.onSwap,
  });

  final Product product;
  final VoidCallback onBack;
  final VoidCallback onSwap; // Will be mapped to "Альтернативы" or used elsewhere if needed

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  var _faved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return MayakTheme.scoreExcellent;
    if (score >= 40) return MayakTheme.scoreModerate;
    return MayakTheme.scorePoor;
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.product.score;
    final cardAccent = _getScoreColor(score);
    final composition = widget.product.composition ?? 'Состав не указан';

    return Container(
      color: MayakTheme.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HeaderButton(
                    onTap: widget.onBack,
                    icon: Icons.arrow_back_ios_new_rounded,
                  ),
                  _HeaderButton(
                    onTap: () => setState(() => _faved = !_faved),
                    icon: _faved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    iconColor: _faved ? const Color(0xFFC03B32) : const Color(0xFF0C1A09),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: MayakTheme.card,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 2))],
                            border: Border(left: BorderSide(color: cardAccent, width: 4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color: MayakTheme.muted,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: widget.product.thumbnail != null
                                    ? Image.network(widget.product.thumbnail!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.fastfood, color: Colors.white))
                                    : const Icon(Icons.fastfood, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.product.manufacturer} · ${widget.product.categoryName}'.toUpperCase(),
                                      style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF5E6859), letterSpacing: 10 * 0.07),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.product.title,
                                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 17, color: const Color(0xFF0C1A09), height: 1.25, letterSpacing: 17 * -0.02),
                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _ScoreArc(score: score),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          indicator: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFF153918), width: 2.5)),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: const Color(0xFF0C1A09),
                          unselectedLabelColor: const Color(0xFF8A9486),
                          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
                          unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w400, fontSize: 14),
                          dividerColor: const Color(0x140C1A09),
                          tabs: const [
                            Tab(text: 'Обзор'),
                            Tab(text: 'Альтернативы'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(product: widget.product, composition: composition),
                    _AlternativesTab(product: widget.product),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Product product;
  final String composition;

  const _OverviewTab({required this.product, required this.composition});

  @override
  Widget build(BuildContext context) {
    final nutrients = product.nutrients;
    final calories = nutrients?.calories ?? '0';
    final proteins = nutrients?.proteins ?? '0';
    final fats = nutrients?.fats ?? '0';
    final carbs = nutrients?.carbohydrates ?? '0';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Macros
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label(text: 'Калорийность · 100г'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    calories.replaceAll(RegExp(r'[^0-9]'), ''), // Keep only digits for large number
                    style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 52, color: const Color(0xFF0C1A09), height: 1, letterSpacing: 52 * -0.03),
                  ),
                  const SizedBox(width: 8),
                  Text('ккал', style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF5E6859))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _MacroBox(label: 'Белки', val: proteins, unit: 'г')),
                  const SizedBox(width: 8),
                  Expanded(child: _MacroBox(label: 'Жиры', val: fats, unit: 'г')),
                  const SizedBox(width: 8),
                  Expanded(child: _MacroBox(label: 'Углеводы', val: carbs, unit: 'г')),
                ],
              ),
              const SizedBox(height: 16),
              
              // Criteria details
              if (product.criteriaRatings.isNotEmpty)
                ...product.criteriaRatings.map((c) {
                  final warn = c.value < 3; // Mocking warning logic based on rating < 3
                  final pct = (c.value / 5.0) * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(c.title, style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF5E6859))),
                                if (warn) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(color: const Color(0x1AC03B32), borderRadius: BorderRadius.circular(4)),
                                    child: Text('плохо', style: GoogleFonts.dmMono(fontSize: 9, color: const Color(0xFFC03B32))),
                                  ),
                                ],
                              ],
                            ),
                            Text('${c.value.toStringAsFixed(1)} / 5', style: GoogleFonts.dmMono(fontSize: 12, color: warn ? const Color(0xFFC03B32) : const Color(0xFF5E6859))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 4, width: double.infinity,
                          decoration: BoxDecoration(color: const Color(0x120C1A09), borderRadius: BorderRadius.circular(2)),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: pct / 100,
                            child: Container(
                              decoration: BoxDecoration(color: warn ? const Color(0xFFC03B32) : const Color(0xFF4A9152), borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Additives - Mocked from "info" or just display empty if none
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label(text: 'Особенности'),
              const SizedBox(height: 8),
              if (product.worth.isEmpty)
                Text('Ничего особенного не обнаружено', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF4A9152)))
              else
                ...product.worth.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4, right: 8),
                        child: Icon(Icons.circle, size: 6, color: Color(0xFF1E6B28)),
                      ),
                      Expanded(
                        child: Text(w, style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF0C1A09))),
                      ),
                    ],
                  ),
                )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Composition
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label(text: 'Состав'),
              const SizedBox(height: 8),
              Text(
                composition,
                style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF3A5040), height: 1.65),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlternativesTab extends StatelessWidget {
  final Product product;

  const _AlternativesTab({required this.product});

  Color _getScoreColor(int score) {
    if (score >= 70) return MayakTheme.scoreExcellent;
    if (score >= 40) return MayakTheme.scoreModerate;
    return MayakTheme.scorePoor;
  }

  Color _getScoreBg(int score) {
    if (score >= 70) return const Color(0xFFD7F5E6);
    if (score >= 40) return const Color(0xFFFFE2CC);
    return const Color(0xFFFFD9DF);
  }

  @override
  Widget build(BuildContext context) {
    if (product.recommendations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: const Color(0x14153918), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF153918), size: 28),
            ),
            const SizedBox(height: 12),
            Text('Это уже лучший выбор', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF0C1A09))),
            const SizedBox(height: 4),
            Text(
              'Маяк не нашёл более полезной альтернативы в этой категории',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF5E6859)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Более полезные варианты в категории «${product.categoryName}»',
            style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF5E6859)),
          ),
        ),
        ...product.recommendations.map((alt) {
          final altScore = (alt.totalRating * 20).round().clamp(0, 100).toInt();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MayakTheme.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))],
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: MayakTheme.muted, borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: alt.thumbnail != null
                      ? Image.network(alt.thumbnail!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.fastfood, color: Colors.white))
                      : const Icon(Icons.fastfood, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alt.title, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0C1A09)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(alt.manufacturer, style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF5E6859)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('Сейчас: ${product.score}', style: GoogleFonts.dmMono(fontSize: 11, color: const Color(0xFF8A9486))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF1E6B28)),
                          ),
                          Text('$altScore', style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E6B28))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: _getScoreBg(altScore), borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: Text('$altScore', style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 18, color: _getScoreColor(altScore))),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}


/* ── Helpers ── */

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MayakTheme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF5E6859), letterSpacing: 10 * 0.08),
    );
  }
}

class _MacroBox extends StatelessWidget {
  final String label;
  final String val;
  final String unit;
  const _MacroBox({required this.label, required this.val, required this.unit});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFE8E3D6), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val.replaceAll(RegExp(r'[^0-9.]'), ''), style: GoogleFonts.fraunces(fontWeight: FontWeight.w800, fontSize: 20, color: const Color(0xFF0C1A09), height: 1)),
          const SizedBox(height: 3),
          Text('$label, $unit', style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF5E6859))),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  const _HeaderButton({required this.onTap, required this.icon, this.iconColor = const Color(0xFF0C1A09)});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(color: Color(0x140C1A09), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 16),
      ),
    );
  }
}

class _ScoreArc extends StatelessWidget {
  final int score;
  const _ScoreArc({required this.score});

  Color _getScoreColor(int score) {
    if (score >= 70) return MayakTheme.scoreExcellent;
    if (score >= 40) return MayakTheme.scoreModerate;
    return MayakTheme.scorePoor;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    return SizedBox(
      width: 68, height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(68, 68),
            painter: _ArcPainter(score: score, color: color),
          ).animate().fadeIn(duration: 400.ms),
          Text(
            '$score',
            style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF0C1A09), height: 1),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final int score;
  final Color color;
  _ArcPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = 28.0;
    final center = Offset(size.width / 2, size.height / 2);
    final circ = 2 * math.pi * r;
    final arc = circ * 0.7;
    
    final bgPaint = Paint()
      ..color = const Color(0x120C1A09)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = 126 * (math.pi / 180);
    final sweepAngle = 0.7 * 2 * math.pi;

    canvas.drawArc(Rect.fromCircle(center: center, radius: r), startAngle, sweepAngle, false, bgPaint);
    
    final fillSweep = sweepAngle * (score / 100);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), startAngle, fillSweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => score != oldDelegate.score;
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: MayakTheme.bg,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
