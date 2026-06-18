import 'package:flutter/material.dart';

class CocoCard extends StatelessWidget {
  const CocoCard(
      {super.key,
      required this.child,
      this.color = Colors.white,
      this.gradient,
      this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final Color color;
  final Gradient? gradient;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final shadow = gradient != null
        ? const BoxShadow(
            color: Color(0x3010b981),
            blurRadius: 28,
            offset: Offset(0, 8),
            spreadRadius: -4)
        : const BoxShadow(
            color: Color(0x141a1410),
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: 0);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [shadow],
      ),
      child: child,
    );
  }
}
