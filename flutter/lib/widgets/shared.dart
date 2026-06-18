import 'package:flutter/material.dart';
import '../theme.dart';
import 'pill_button.dart';

class RoundIcon extends StatelessWidget {
  const RoundIcon(
      {super.key, required this.icon, required this.onTap, this.dark = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: dark ? Colors.white : MayakTheme.fg),
        style: IconButton.styleFrom(
            backgroundColor: dark ? Colors.white24 : MayakTheme.muted),
      );
}

class CircleIcon extends StatelessWidget {
  const CircleIcon({super.key, required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: MayakTheme.primary),
        child: Icon(icon, color: Colors.white, size: 30),
      );
}

class SmallCounter extends StatelessWidget {
  const SmallCounter({super.key, required this.icon, required this.value});
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(999)),
        child: Row(children: [
          Icon(icon,
              color: value > 0 ? Colors.red : MayakTheme.mutedFg, size: 16),
          Text('$value')
        ]),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      );
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initials, required this.size});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: MayakTheme.primary, shape: BoxShape.circle),
        child: Center(
            child: Text(initials,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: size * .38,
                    fontWeight: FontWeight.w800))),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PillButton(label: 'Назад', onTap: onBack),
        ),
      );
}
