import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingSlide {
  final String num;
  final String heading;
  final String body;
  final Widget visual;
  final Color bg;
  final Color ink;

  const OnboardingSlide({
    required this.num,
    required this.heading,
    required this.body,
    required this.visual,
    required this.bg,
    required this.ink,
  });
}

final _slides = [
  OnboardingSlide(
    num: "01",
    heading: "Понимайте\nчто вы едите",
    body: "МАЯК расшифровывает этикетки продуктов и объясняет состав простым и честным языком — без химического жаргона.",
    visual: CustomPaint(size: const Size(260, 200), painter: Visual1Painter()),
    bg: const Color(0xFFF4F1E8),
    ink: const Color(0xFF153918),
  ),
  OnboardingSlide(
    num: "02",
    heading: "Сканируйте\nза секунду",
    body: "Наведите камеру на штрихкод — и получите полный научный анализ продукта до того, как положите его в корзину.",
    visual: CustomPaint(size: const Size(260, 200), painter: Visual2Painter()),
    bg: const Color(0xFFEBF3E8),
    ink: const Color(0xFF153918),
  ),
  OnboardingSlide(
    num: "03",
    heading: "Научная\nоснова",
    body: "Каждая оценка опирается на рецензируемые исследования, критерии ВОЗ и базу данных Open Food Facts.",
    visual: CustomPaint(size: const Size(260, 200), painter: Visual3Painter()),
    bg: const Color(0xFFF4F1E8),
    ink: const Color(0xFF153918),
  ),
  OnboardingSlide(
    num: "04",
    heading: "Найдите\nлучшую замену",
    body: "Маяк предложит более полезную альтернативу в той же категории и объяснит, чем она лучше.",
    visual: CustomPaint(size: const Size(260, 200), painter: Visual4Painter()),
    bg: const Color(0xFFEBF3E8),
    ink: const Color(0xFF153918),
  ),
];

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_idx];

    return Scaffold(
      backgroundColor: slide.bg,
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          color: slide.bg,
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_idx + 1} / ${_slides.length}',
                      style: GoogleFonts.dmMono(
                        fontSize: 12,
                        color: slide.ink.withOpacity(0.4),
                        letterSpacing: 12 * 0.04,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onComplete,
                      style: TextButton.styleFrom(
                        foregroundColor: slide.ink.withOpacity(0.55),
                        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      child: const Text('Пропустить'),
                    ),
                  ],
                ),
              ),

              // Illustration
              SizedBox(
                height: 220,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_idx),
                      child: slide.visual,
                    ),
                  ),
                ),
              ),

              // Text block
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 28, right: 28, bottom: 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_idx),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.num,
                            style: GoogleFonts.fraunces(
                              fontWeight: FontWeight.w900,
                              fontSize: 96,
                              height: 0.85,
                              color: slide.ink.withOpacity(0.08),
                              letterSpacing: 96 * -0.04,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide.heading,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 28,
                                    height: 1.15,
                                    letterSpacing: 28 * -0.03,
                                    color: slide.ink,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  slide.body,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    height: 1.65,
                                    color: slide.ink.withOpacity(0.88),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom
              Padding(
                padding: const EdgeInsets.only(left: 28, right: 28, bottom: 32, top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dots
                    Row(
                      children: List.generate(_slides.length, (i) {
                        final isActive = i == _idx;
                        return GestureDetector(
                          onTap: () => setState(() => _idx = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.only(right: 8),
                            height: 6,
                            width: isActive ? 24 : 6,
                            decoration: BoxDecoration(
                              color: isActive ? slide.ink : slide.ink.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                    // CTA
                    GestureDetector(
                      onTap: () {
                        if (_idx < _slides.length - 1) {
                          setState(() => _idx++);
                        } else {
                          widget.onComplete();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: slide.ink,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _idx < _slides.length - 1 ? "Далее" : "Начать",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: slide.bg,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, color: slide.bg, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Painters for the visuals
class Visual1Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Product label
    paint.color = Colors.white.withOpacity(0.7);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(55, 20, 150, 160), const Radius.circular(16)), paint);
    
    paint.color = const Color(0xFF153918).withOpacity(0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 36, 120, 14), const Radius.circular(7)), paint);
    
    paint.color = const Color(0xFF153918).withOpacity(0.07);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 58, 88, 9), const Radius.circular(4.5)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 74, 104, 9), const Radius.circular(4.5)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 90, 72, 9), const Radius.circular(4.5)), paint);
    
    // Score bubble
    paint.color = const Color(0xFF153918).withOpacity(0.08);
    canvas.drawCircle(const Offset(130, 148), 30, paint);
    
    final tp = TextPainter(
      text: TextSpan(text: '87', style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xD9153918))), // opacity 0.85 approx D9
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(130 - tp.width / 2, 148 - tp.height / 2));
    
    // Green checks
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(70, 58.0 + i * 16);
      
      paint.color = const Color(0xFF4A9152).withOpacity(0.18);
      canvas.drawCircle(Offset.zero, 5, paint);
      
      final path = Path()
        ..moveTo(-2.5, 0)
        ..lineTo(-0.7, 1.8)
        ..lineTo(2.8, -1.7);
        
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.4;
      paint.color = const Color(0xFF1E6B28);
      paint.strokeCap = StrokeCap.round;
      paint.strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint);
      
      paint.style = PaintingStyle.fill;
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Visual2Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Phone silhouette
    paint.color = const Color(0xFF153918).withOpacity(0.08);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(95, 10, 70, 120), const Radius.circular(12)), paint);
    
    paint.color = Colors.white.withOpacity(0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(100, 16, 60, 108), const Radius.circular(9)), paint);
    
    // Scan frame
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    paint.color = const Color(0xFF153918).withOpacity(0.3);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(113, 38, 34, 52), const Radius.circular(4)), paint);
    
    // Corner marks
    paint.color = const Color(0xFF1E6B28);
    paint.strokeWidth = 2.5;
    paint.strokeCap = StrokeCap.round;
    
    final corners = [[113.0,38.0],[147.0,38.0],[113.0,90.0],[147.0,90.0]];
    for (int i = 0; i < corners.length; i++) {
      final x = corners[i][0];
      final y = corners[i][1];
      canvas.drawLine(Offset(x, y), Offset(x + (i % 2 == 0 ? 8 : -8), y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, y + (i < 2 ? 8 : -8)), paint);
    }
    
    // Scan line
    paint.color = const Color(0xFF4A9152).withOpacity(0.7);
    paint.strokeWidth = 1.5;
    canvas.drawLine(const Offset(113, 64), const Offset(147, 64), paint);
    
    // Barcode bars
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      paint.color = const Color(0xFF153918).withOpacity(0.08 + (i % 3) * 0.04);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(116.0 + i * 4, 46, 2.0 + (i % 3), 36), const Radius.circular(0.5)), paint);
    }
    
    // Success flash
    paint.color = const Color(0xFF4A9152).withOpacity(0.12);
    canvas.drawCircle(const Offset(130, 158), 20, paint);
    
    final path = Path()
      ..moveTo(122, 158)
      ..lineTo(127, 163)
      ..lineTo(138, 152);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    paint.color = const Color(0xFF1E6B28);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Visual3Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    paint.color = const Color(0xFF153918).withOpacity(0.07);
    
    canvas.drawCircle(const Offset(130, 100), 72, paint);
    canvas.drawCircle(const Offset(130, 100), 50, paint);
    
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF153918).withOpacity(0.06);
    canvas.drawCircle(const Offset(130, 100), 28, paint);
    
    final tpCenter = TextPainter(
      text: TextSpan(text: 'ВОЗ', style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF153918).withOpacity(0.6))),
      textDirection: TextDirection.ltr,
    );
    tpCenter.layout();
    tpCenter.paint(canvas, Offset(130 - tpCenter.width / 2, 100 - tpCenter.height / 2));
    
    final nodes = [
      {'angle': -60.0, 'r': 72.0, 'label': 'A'},
      {'angle': 20.0, 'r': 72.0, 'label': 'B'},
      {'angle': 110.0, 'r': 72.0, 'label': 'C'},
    ];
    
    for (var node in nodes) {
      final rad = ((node['angle'] as double) * pi) / 180;
      final r = node['r'] as double;
      final label = node['label'] as String;
      
      final x = 130 + r * cos(rad);
      final y = 100 + r * sin(rad);
      
      paint.style = PaintingStyle.stroke;
      paint.color = const Color(0xFF153918).withOpacity(0.1);
      canvas.drawLine(const Offset(130, 100), Offset(x, y), paint);
      
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 16, paint);
      
      final tp = TextPainter(
        text: TextSpan(text: label, style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF153918).withOpacity(0.6))),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Visual4Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    final products = [
      {'x': 40.0, 'score': '28', 'label': 'Нутелла', 'bad': true},
      {'x': 148.0, 'score': '62', 'label': '7 орехов', 'bad': false},
    ];
    
    for (var p in products) {
      final x = p['x'] as double;
      final bad = p['bad'] as bool;
      final score = p['score'] as String;
      final label = p['label'] as String;
      
      final color = bad ? const Color(0xFFC03B32) : const Color(0xFF1E6B28);
      
      paint.color = color.withOpacity(0.07);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 30, 72, 96), const Radius.circular(12)), paint);
      
      paint.color = Colors.white.withOpacity(0.5);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 8, 38, 56, 40), const Radius.circular(8)), paint);
      
      final tpScore = TextPainter(
        text: TextSpan(text: score, style: GoogleFonts.fraunces(fontSize: 30, fontWeight: FontWeight.w900, color: color.withOpacity(0.85))),
        textDirection: TextDirection.ltr,
      );
      tpScore.layout();
      tpScore.paint(canvas, Offset(x + 36 - tpScore.width / 2, 86));
      
      final tpLabel = TextPainter(
        text: TextSpan(text: label, style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF153918).withOpacity(0.5))),
        textDirection: TextDirection.ltr,
      );
      tpLabel.layout();
      tpLabel.paint(canvas, Offset(x + 36 - tpLabel.width / 2, 136));
    }
    
    // Arrow
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    paint.strokeCap = StrokeCap.round;
    paint.color = const Color(0xFF1E6B28);
    canvas.drawLine(const Offset(120, 80), const Offset(136, 80), paint);
    
    final arrowHead = Path()
      ..moveTo(132, 76)
      ..lineTo(138, 80)
      ..lineTo(132, 84);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    canvas.drawPath(arrowHead, paint);
    
    // Star
    final tpStar = TextPainter(
      text: TextSpan(text: '✦', style: TextStyle(fontSize: 14, color: const Color(0xFF1E6B28).withOpacity(0.7))),
      textDirection: TextDirection.ltr,
    );
    tpStar.layout();
    tpStar.paint(canvas, const Offset(184, 16));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
