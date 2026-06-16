import 'package:flutter/material.dart';
import '../theme.dart';
import 'coco_card.dart';

class SwapCard extends StatelessWidget {
  const SwapCard({super.key});

  @override
  Widget build(BuildContext context) => const CocoCard(
        child: Column(children: [
          ProductLetter(label: 'Ч'),
          SizedBox(height: 8),
          Text('Чистая Линия', style: TextStyle(fontWeight: FontWeight.w900)),
          Text('Мороженое Пломбир ванильный в вафельном стаканчике',
              textAlign: TextAlign.center,
              style: TextStyle(color: MayakTheme.mutedFg)),
          Text('95',
              style: TextStyle(
                  color: MayakTheme.scoreExcellent,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
        ]),
      );
}

class ProductLetter extends StatelessWidget {
  const ProductLetter({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
            color: const Color(0xffd9f99d),
            borderRadius: BorderRadius.circular(18)),
        child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: MayakTheme.scoreExcellent,
                    fontSize: 28,
                    fontWeight: FontWeight.w900))),
      );
}

class DeltaRow extends StatelessWidget {
  const DeltaRow(
      {super.key, required this.label, required this.from, required this.to});
  final String label;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(from,
              style: const TextStyle(
                  color: MayakTheme.mutedFg,
                  decoration: TextDecoration.lineThrough)),
          const Icon(Icons.arrow_forward, size: 14, color: MayakTheme.mutedFg),
          Text(to,
              style: const TextStyle(
                  color: MayakTheme.scoreExcellent,
                  fontWeight: FontWeight.w900)),
        ]),
      );
}
