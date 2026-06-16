import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../widgets/product_widgets.dart';

import '../domain/auth_user.dart';
import '../domain/product.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.history,
    required this.average,
    required this.streak,
    required this.onShowProduct,
    required this.onNavigateToHistory,
  });

  final AuthUser user;
  final List<Product> history;
  final int average;
  final int streak;
  final void Function(Product product) onShowProduct;
  final VoidCallback onNavigateToHistory;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM', 'ru_RU').format(now);
    final greetingName = widget.user.nickname ?? 'Пользователь';
    final initialLetter = greetingName.isNotEmpty ? greetingName[0].toUpperCase() : 'П';
    
    final averageScore = widget.history.isEmpty ? 0 : widget.average;
    final scoreTier = scoreTierData(averageScore);

    return Container(
      color: MayakTheme.bg,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
        children: [
          // Hero
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Greeting row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: MayakTheme.mutedFg,
                            letterSpacing: 11 * 0.06,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Привет, $greetingName',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: MayakTheme.fg,
                            letterSpacing: 22 * -0.02,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: MayakTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initialLetter,
                        style: GoogleFonts.fraunces(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Food index card
                Container(
                  decoration: BoxDecoration(
                    color: MayakTheme.darkHeader,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ИНДЕКС ПИТАНИЯ · 7 ДНЕЙ',
                          style: GoogleFonts.dmMono(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.35),
                            letterSpacing: 10 * 0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Big editorial number
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$averageScore',
                              style: GoogleFonts.fraunces(
                                fontWeight: FontWeight.w900,
                                fontSize: 88,
                                height: 0.9,
                                color: const Color(0xFF5BAF64),
                                letterSpacing: 88 * -0.04,
                              ),
                            ).animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 600.ms, curve: Curves.easeOutCubic).fade(),
                            const SizedBox(width: 16),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scoreTier.label,
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Text(
                                    'из 100',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_upward_rounded, color: Color(0xFF5BAF64), size: 10),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+5 за неделю',
                                        style: GoogleFonts.dmMono(fontSize: 11, color: const Color(0xFF5BAF64)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Progress track
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            height: 6,
                            width: MediaQuery.of(context).size.width * (averageScore / 100),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5BAF64),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Macro bars (mocked for now as in React)
                        const Row(
                          children: [
                            Expanded(child: _MacroBar(label: 'Белки', pct: 78, good: true)),
                            SizedBox(width: 24),
                            Expanded(child: _MacroBar(label: 'Клетчатка', pct: 44, good: true)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Expanded(child: _MacroBar(label: 'Сахар', pct: 63, good: false)),
                            SizedBox(width: 24),
                            Expanded(child: _MacroBar(label: 'Добавки', pct: 22, good: false)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recent scans
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Последние сканы',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: MayakTheme.fg,
                        letterSpacing: 16 * -0.02,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onNavigateToHistory,
                      style: TextButton.styleFrom(
                        foregroundColor: MayakTheme.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      child: const Text('Все →'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (widget.history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text('Пока нет сканов.', style: GoogleFonts.dmSans(color: MayakTheme.mutedFg)),
                  )
                else
                  ...widget.history.take(3).toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final product = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecentScanItem(product: product, onTap: () => widget.onShowProduct(product))
                        .animate().fade(delay: (idx * 50).ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Tier scoreTierData(int score) {
    if (score >= 80) return const Tier('Отлично', MayakTheme.scoreExcellent, Color(0xffd7f5e6), Color(0xff04432a));
    if (score >= 60) return const Tier('Хорошо', MayakTheme.scoreGood, Color(0xfff0f6cf), Color(0xff3a4407));
    if (score >= 40) return const Tier('Спорно', MayakTheme.scoreModerate, Color(0xffffe2cc), Color(0xff5a1f00));
    return const Tier('Плохо', MayakTheme.scorePoor, Color(0xffffd9df), Color(0xff5c0716));
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int pct;
  final bool good;

  const _MacroBar({required this.label, required this.pct, required this.good});

  @override
  Widget build(BuildContext context) {
    final color = good ? const Color(0xFF5BAF64) : const Color(0xFFD49842);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withValues(alpha: 0.45))),
            Text('$pct%', style: GoogleFonts.dmMono(fontSize: 11, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(2)),
          alignment: Alignment.centerLeft,
          child: Container(
            height: 4,
            width: MediaQuery.of(context).size.width * (pct / 100),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
        ),
      ],
    );
  }
}

class _RecentScanItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _RecentScanItem({required this.product, required this.onTap});

  Tier scoreTierData(int score) {
    if (score >= 80) return const Tier('Отлично', MayakTheme.scoreExcellent, Color(0xffd7f5e6), Color(0xff04432a));
    if (score >= 60) return const Tier('Хорошо', MayakTheme.scoreGood, Color(0xfff0f6cf), Color(0xff3a4407));
    if (score >= 40) return const Tier('Спорно', MayakTheme.scoreModerate, Color(0xffffe2cc), Color(0xff5a1f00));
    return const Tier('Плохо', MayakTheme.scorePoor, Color(0xffffd9df), Color(0xff5c0716));
  }

  @override
  Widget build(BuildContext context) {
    final tier = scoreTierData(product.score);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MayakTheme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: MayakTheme.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: product.thumbnail != null
                ? NetImg(product.thumbnail!)
                : const Icon(Icons.fastfood, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14, color: MayakTheme.fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.manufacturer.isNotEmpty ? product.manufacturer : 'Неизвестно',
                    style: GoogleFonts.dmSans(fontSize: 12, color: MayakTheme.mutedFg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Только что', // Simplified for demo
                    style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Text(
                  '${product.score}',
                  style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 24, color: tier.color, height: 1),
                ),
                Text(
                  tier.label,
                  style: GoogleFonts.dmMono(fontSize: 9, color: tier.color, letterSpacing: 9 * 0.03),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
