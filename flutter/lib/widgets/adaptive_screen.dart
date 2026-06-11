import 'package:flutter/material.dart';
import '../theme.dart';

class AdaptiveScreen extends StatelessWidget {
  const AdaptiveScreen({super.key, required this.child, this.bottomNav});
  final Widget child;
  final Widget? bottomNav;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MayakTheme.bg,
      body: SafeArea(
        top: false, // Screens will manage their own top safe area
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Stack(
              children: [
                child,
                if (bottomNav != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: bottomNav!,
                  ),
              ],
            ),
          ),
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
          child: const CircularProgressIndicator(color: MayakTheme.primary),
        ),
      );
}
