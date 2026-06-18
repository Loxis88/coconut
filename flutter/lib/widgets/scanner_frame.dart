import 'package:flutter/material.dart';

class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * .65;
    final rect = Rect.fromCenter(
        center: size.center(Offset.zero), width: side, height: side);
    final paint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 34.0;
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, len), paint);
    canvas.drawLine(
        rect.topRight, rect.topRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, len), paint);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + const Offset(len, 0), paint);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + const Offset(0, -len), paint);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight + const Offset(-len, 0), paint);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight + const Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
