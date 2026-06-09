import 'package:flutter/material.dart';

class Coco {
  static const cream = Color(0xfffff6e8);
  static const cream2 = Color(0xfffbefd9);
  static const ink = Color(0xff1a1410);
  static const ink2 = Color(0xff3d332b);
  static const muted = Color(0xff7a6b5c);
  static const hairline = Color(0x151a1410);
  static const lime = Color(0xffbef264);
  static const emerald = Color(0xff10b981);
  static const emeraldDeep = Color(0xff047857);
  static const amber = Color(0xfff59e0b);
  static const coral = Color(0xfff97316);
  static const red = Color(0xffe11d48);
  static const brownDeep = Color(0xff3f2412);
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lime, emerald, emeraldDeep],
    stops: [0.0, 0.75, 1.0],
  );
}

class Tier {
  const Tier(this.label, this.color, this.background, this.ink);
  final String label;
  final Color color;
  final Color background;
  final Color ink;
}

Tier scoreTier(int score) {
  if (score >= 80) return const Tier('Супер', Coco.emerald, Color(0xffd7f5e6), Color(0xff04432a));
  if (score >= 60) return const Tier('Норма', Color(0xffa3b91d), Color(0xfff0f6cf), Color(0xff3a4407));
  if (score >= 40) return const Tier('Спорно', Coco.coral, Color(0xffffe2cc), Color(0xff5a1f00));
  return const Tier('Мусор', Coco.red, Color(0xffffd9df), Color(0xff5c0716));
}
