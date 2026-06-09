import 'package:flutter/material.dart';
import '../theme.dart';

enum PillKind { ink, brand, ghost }

class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, this.icon, this.kind = PillKind.ink, required this.onTap});
  final String label;
  final IconData? icon;
  final PillKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      PillKind.ink => Coco.ink,
      PillKind.brand => null,
      PillKind.ghost => Coco.hairline,
    };
    final content = switch (kind) {
      PillKind.brand => Coco.brownDeep,
      PillKind.ink => Colors.white,
      PillKind.ghost => label.contains('Удалить') || label.contains('Выйти') ? Coco.red : Coco.ink,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          gradient: kind == PillKind.brand ? Coco.brandGradient : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: content, fontSize: 17, fontWeight: FontWeight.w900)),
            if (icon != null) ...[const SizedBox(width: 8), Icon(icon, color: content, size: 20)],
          ],
        ),
      ),
    );
  }
}
