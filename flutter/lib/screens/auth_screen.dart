import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/adaptive_screen.dart';
import '../widgets/coconut_mark.dart';
import '../widgets/pill_button.dart';
import '../widgets/score_widgets.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.onGoogleLogin,
  });

  final bool loading;
  final String? error;
  final VoidCallback onGoogleLogin;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScreen(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size.infinite, painter: GlowPainter()),
                const CoconutMark(size: 180),
                const Positioned(left: 28, top: 70, child: ScoreChip(score: 92, big: true)),
                const Positioned(right: 36, top: 120, child: ScoreChip(score: 48, big: true)),
                const Positioned(left: 36, bottom: 140, child: ScoreChip(score: 71, big: true)),
                const Positioned(right: 40, bottom: 90, child: ScoreChip(score: 88, big: true)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Coconut.', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, height: .96)),
                const SizedBox(height: 10),
                const Text(
                  'Раскуси каждый кусочек. Получи честную оценку любого продукта в один скан.',
                  style: TextStyle(color: Coco.ink2, fontSize: 19, height: 1.3),
                ),
                const SizedBox(height: 24),
                if (loading)
                  const CenteredLoader(compact: true)
                else ...[
                  PillButton(label: 'Войти через Google', kind: PillKind.brand, onTap: onGoogleLogin),
                  const SizedBox(height: 12),
                  PillButton(label: 'Войти через Apple ID', kind: PillKind.ink, onTap: () {}),
                  const SizedBox(height: 12),
                  PillButton(label: 'Войти по почте', kind: PillKind.ghost, icon: Icons.email, onTap: () {}),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Coco.red)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
