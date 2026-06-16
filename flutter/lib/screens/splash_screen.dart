import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _playSequence();
  }

  void _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _step = 1);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _step = 2);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _step = 3);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MayakTheme.darkHeader,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric rings
          for (int i = 0; i < 3; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              width: _step >= 1 ? [200.0, 300.0, 420.0][i] : 120.0,
              height: _step >= 1 ? [200.0, 300.0, 420.0][i] : 120.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x265BAF64)), // 0.15 opacity
              ),
            ).animate(target: _step >= 1 ? 1 : 0).fadeIn(duration: 1400.ms, delay: (120 * i).ms),

          // Core glow
          Container(
            width: 128,
            height: 128,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x2E5BAF64), Colors.transparent], // 0.18 opacity
                stops: [0.0, 0.7],
              ),
            ),
          ).animate(target: _step >= 1 ? 1 : 0).fadeIn(duration: 1200.ms),

          // Lighthouse mark
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(56, 72),
                painter: LighthousePainter(_step >= 2),
              )
              .animate(target: _step >= 1 ? 1 : 0)
              .fadeIn(duration: 800.ms)
              .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutCubic)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 800.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 32),

              Text(
                'МАЯК',
                style: GoogleFonts.fraunces(
                  fontWeight: FontWeight.w900,
                  fontSize: 44,
                  color: Colors.white,
                  letterSpacing: 44 * 0.18,
                  height: 1,
                ),
              )
              .animate(target: _step >= 2 ? 1 : 0)
              .fadeIn(duration: 700.ms)
              .slideY(begin: 0.2, end: 0, duration: 700.ms),

              const SizedBox(height: 10),

              Text(
                'НАВИГАТОР ПИТАНИЯ',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 12 * 0.12,
                ),
              )
              .animate(target: _step >= 3 ? 1 : 0)
              .fadeIn(duration: 600.ms),
            ],
          ),

          // Progress line
          Positioned(
            bottom: 64,
            child: Container(
              width: 64,
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 2000),
                curve: Curves.linear,
                width: _step >= 2 ? 64 : 0,
                height: 1,
                color: const Color(0xCC5BAF64), // 0.8 opacity
              ),
            ).animate(target: _step >= 2 ? 1 : 0).fadeIn(duration: 300.ms),
          ),
        ],
      ),
    );
  }
}

class LighthousePainter extends CustomPainter {
  final bool showBeam;

  LighthousePainter(this.showBeam);

  @override
  void paint(Canvas canvas, Size size) {
    // Beam
    if (showBeam) {
      final beamPath = Path()
        ..moveTo(28, 18)
        ..lineTo(50, 68)
        ..lineTo(6, 68)
        ..close();
      canvas.drawPath(beamPath, Paint()..color = const Color(0x125BAF64));
    }

    // Tower
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(22, 28, 12, 42), const Radius.circular(1.5)), Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawRect(const Rect.fromLTWH(22, 42, 12, 7), Paint()..color = Colors.white.withValues(alpha: 0.25));

    // Lantern
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 18, 20, 13), const Radius.circular(2.5)), Paint()..color = Colors.white);

    // Light pulse (simulated static for painter, real pulse needs animation builder, but simple is ok here)
    canvas.drawCircle(const Offset(28, 24), 4.5, Paint()..color = const Color(0xFFFFD566));

    // Cap
    final capPath = Path()
      ..moveTo(20, 18)
      ..quadraticBezierTo(28, 11, 36, 18);
    canvas.drawPath(capPath, Paint()..color = Colors.white.withValues(alpha: 0.85));

    // Base
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 68, 20, 4), const Radius.circular(1.0)), Paint()..color = Colors.white.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant LighthousePainter oldDelegate) => showBeam != oldDelegate.showBeam;
}
