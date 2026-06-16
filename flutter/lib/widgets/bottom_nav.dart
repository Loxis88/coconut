import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../main.dart'; // To access AppRoute

class BottomNav extends StatelessWidget {
  final AppRoute currentRoute;
  final ValueChanged<AppRoute> onRouteChanged;

  const BottomNav(
      {super.key, required this.currentRoute, required this.onRouteChanged});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(
                0xE8E8E3D6), // E8E3D6 at 0.94 opacity approx = 240 alpha -> 0xF0
            border: Border(
                top: BorderSide(color: MayakTheme.fg.withValues(alpha: 0.07))),
          ),
          padding:
              const EdgeInsets.only(bottom: 20, top: 8, left: 12, right: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: _HomeIcon(active: currentRoute == AppRoute.home),
                label: 'Главная',
                active: currentRoute == AppRoute.home,
                onTap: () => onRouteChanged(AppRoute.home),
              ),
              _NavItem(
                icon: _SearchIcon(active: currentRoute == AppRoute.search),
                label: 'Поиск',
                active: currentRoute == AppRoute.search,
                onTap: () => onRouteChanged(AppRoute.search),
              ),
              GestureDetector(
                onTap: () => onRouteChanged(AppRoute.scan),
                child: Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(
                      bottom: 2, top: 4), // Lifted up a bit
                  decoration: BoxDecoration(
                    color: MayakTheme.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: MayakTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: CustomPaint(
                      size: const Size(22, 22), painter: _ScannerIconPainter()),
                ).animate().scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    duration: 200.ms),
              ),
              _NavItem(
                icon: _HistoryIcon(active: currentRoute == AppRoute.journal),
                label: 'История',
                active: currentRoute == AppRoute.journal,
                onTap: () => onRouteChanged(AppRoute.journal),
              ),
              _NavItem(
                icon: _ProfileIcon(active: currentRoute == AppRoute.profile),
                label: 'Профиль',
                active: currentRoute == AppRoute.profile,
                onTap: () => onRouteChanged(AppRoute.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  icon,
                  if (active)
                    Positioned(
                      bottom: -4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: MayakTheme.primary, shape: BoxShape.circle),
                      ).animate().scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 200.ms),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
                color: active ? MayakTheme.primary : const Color(0xFF8A9486),
                letterSpacing: 10 * 0.01,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Icons drawn explicitly to match the React reference SVGs.

class _HomeIcon extends StatelessWidget {
  final bool active;
  const _HomeIcon({required this.active});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: const Size(22, 22), painter: _HomeIconPainter(active));
  }
}

class _HomeIconPainter extends CustomPainter {
  final bool active;
  _HomeIconPainter(this.active);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = active ? PaintingStyle.fill : PaintingStyle.stroke
      ..color = active ? MayakTheme.primary : const Color(0xFF8A9486)
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(2, 9.5)
      ..lineTo(11, 3)
      ..lineTo(20, 9.5)
      ..lineTo(20, 20)
      ..arcToPoint(const Offset(19, 21), radius: const Radius.circular(1))
      ..lineTo(14, 21)
      ..lineTo(14, 15.5)
      ..lineTo(10, 15.5)
      ..lineTo(10, 21)
      ..lineTo(3, 21)
      ..arcToPoint(const Offset(2, 20), radius: const Radius.circular(1))
      ..close();

    canvas.drawPath(path, paint);
    if (active) {
      paint.style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HomeIconPainter oldDelegate) =>
      active != oldDelegate.active;
}

class _SearchIcon extends StatelessWidget {
  final bool active;
  const _SearchIcon({required this.active});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: const Size(22, 22), painter: _SearchIconPainter(active));
  }
}

class _SearchIconPainter extends CustomPainter {
  final bool active;
  _SearchIconPainter(this.active);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = active ? MayakTheme.primary : const Color(0xFF8A9486)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(const Offset(9.5, 9.5), 6, paint);
    canvas.drawLine(const Offset(14, 14), const Offset(19, 19), paint);
  }

  @override
  bool shouldRepaint(covariant _SearchIconPainter oldDelegate) =>
      active != oldDelegate.active;
}

class _HistoryIcon extends StatelessWidget {
  final bool active;
  const _HistoryIcon({required this.active});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: const Size(22, 22), painter: _HistoryIconPainter(active));
  }
}

class _HistoryIconPainter extends CustomPainter {
  final bool active;
  _HistoryIconPainter(this.active);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = active ? MayakTheme.primary : const Color(0xFF8A9486)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(const Offset(11, 11), 8, paint);
    canvas.drawPath(
        Path()
          ..moveTo(11, 7)
          ..lineTo(11, 11)
          ..lineTo(13.5, 13.5),
        paint);
  }

  @override
  bool shouldRepaint(covariant _HistoryIconPainter oldDelegate) =>
      active != oldDelegate.active;
}

class _ProfileIcon extends StatelessWidget {
  final bool active;
  const _ProfileIcon({required this.active});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: const Size(22, 22), painter: _ProfileIconPainter(active));
  }
}

class _ProfileIconPainter extends CustomPainter {
  final bool active;
  _ProfileIconPainter(this.active);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = active ? MayakTheme.primary : const Color(0xFF8A9486)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(const Offset(11, 8.5), 3.5, paint);

    // React path is: "M3.5 20c0-3.9 3.4-7 7.5-7s7.5 3.1 7.5 7"
    final exactPath = Path()
      ..moveTo(3.5, 20)
      ..cubicTo(3.5, 16.1, 6.9, 13, 11, 13)
      ..cubicTo(15.1, 13, 18.5, 16.1, 18.5, 20);

    canvas.drawPath(exactPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ProfileIconPainter oldDelegate) =>
      active != oldDelegate.active;
}

class _ScannerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(2, 10, 18, 2), const Radius.circular(1)),
        paint);

    final xPos = [3.0, 6.5, 10.0, 13.5, 17.0];
    for (var x in xPos) {
      paint.color =
          Colors.white.withValues(alpha: x == 6.5 || x == 13.5 ? 1.0 : 0.45);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, 5, 2, 12), const Radius.circular(0.8)),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
