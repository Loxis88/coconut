import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

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

class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, required this.size, this.showLabel = true});
  final int score;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final tier = scoreTier(score);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final animatedTier = scoreTier(value.round());
        return SizedBox(
          width: size, height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: Size.square(size), painter: RingPainter(score: value.round(), color: animatedTier.color)),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${value.round()}', style: TextStyle(fontSize: size * .42, fontWeight: FontWeight.w900, height: .9)),
                  if (showLabel) Text(tier.label.toUpperCase(), style: TextStyle(color: tier.color, fontSize: size * .1, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        );
      },
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
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: value / 100),
                        duration: Duration(milliseconds: 600 + index * 60),
                        curve: Curves.easeOutCubic,
                        builder: (context, factor, _) => FractionallySizedBox(
                          heightFactor: factor,
                          widthFactor: 1,
                          child: Container(decoration: BoxDecoration(color: scoreTier((factor * 100).round()).color, borderRadius: BorderRadius.circular(8))),
                        ),
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
