import 'package:flutter/material.dart';
import '../theme.dart';

class AdaptiveScreen extends StatelessWidget {
  const AdaptiveScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Coco.cream,
        child: SafeArea(
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: child)),
        ),
      ),
    );
  }
}

class CenteredLoader extends StatelessWidget {
  const CenteredLoader({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: compact ? 32 : 48,
          height: compact ? 32 : 48,
          child: const CircularProgressIndicator(color: Coco.emerald),
        ),
      );
}
