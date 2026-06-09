import 'package:flutter/material.dart';
import '../theme.dart';

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
    for (final point in [const Offset(.35, .42), const Offset(.64, .42), const Offset(.49, .66)]) {
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
