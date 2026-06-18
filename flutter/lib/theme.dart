import 'package:flutter/material.dart';

class MayakTheme {
  static const bg = Color(0xFFE8E3D6);
  static const fg = Color(0xFF0C1A09);
  static const card = Color(0xFFF4F0E6);
  static const muted = Color(0xFFDDD8CB);
  static const mutedFg = Color(0xFF5E6859);
  static const primary = Color(0xFF153918);
  static const accent = Color(0xFFB87D28);

  static const scoreExcellent = Color(0xFF1E6B28);
  static const scoreGood = Color(0xFF4A9152);
  static const scoreModerate = Color(0xFFB87D28);
  static const scorePoor = Color(0xFFC03B32);

  // Background for the dark theme section in auth/splash
  static const darkHeader = Color(0xFF0D1F0F);
}

class Tier {
  const Tier(this.label, this.color, this.background, this.ink);
  final String label;
  final Color color;
  final Color background;
  final Color ink;
}

Tier scoreTier(int score) {
  if (score >= 80) {
    return const Tier('Отлично', MayakTheme.scoreExcellent, Color(0xffd7f5e6),
        Color(0xff04432a));
  }
  if (score >= 60) {
    return const Tier(
        'Хорошо', MayakTheme.scoreGood, Color(0xfff0f6cf), Color(0xff3a4407));
  }
  if (score >= 40) {
    return const Tier('Спорно', MayakTheme.scoreModerate, Color(0xffffe2cc),
        Color(0xff5a1f00));
  }
  return const Tier(
      'Плохо', MayakTheme.scorePoor, Color(0xffffd9df), Color(0xff5c0716));
}
