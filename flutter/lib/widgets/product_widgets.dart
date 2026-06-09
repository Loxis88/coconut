import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../domain/product.dart';
import '../theme.dart';
import 'coco_card.dart';
import 'score_widgets.dart';

class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              ProductThumb(product: product, size: 52, radius: 16),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      product.manufacturer.isNotEmpty ? product.manufacturer : product.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Coco.muted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              ScoreChip(score: product.score),
            ],
          ),
        ),
      );
}

class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.product, required this.size, required this.radius});
  final Product product;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (product.thumbnail != null && product.thumbnail!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(imageUrl: product.thumbnail!, width: size, height: size, fit: BoxFit.cover),
      );
    }
    final label = product.title.isEmpty ? '?' : product.title.characters.first;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xffffe4b5), borderRadius: BorderRadius.circular(radius)),
      child: Center(child: Text(label, style: TextStyle(color: Coco.coral, fontSize: size * .38, fontWeight: FontWeight.w900))),
    );
  }
}

class NutrientGrid extends StatelessWidget {
  const NutrientGrid({super.key, required this.nutrients});
  final Nutrients nutrients;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(children: [
            NutrientCell(label: 'Белки', value: nutrients.proteins ?? '-'),
            NutrientCell(label: 'Жиры', value: nutrients.fats ?? '-'),
            NutrientCell(label: 'Углеводы', value: nutrients.carbohydrates ?? '-'),
          ]),
          Row(children: [
            NutrientCell(label: 'Ккал', value: nutrients.calories ?? '-'),
            if (nutrients.fiber != null) NutrientCell(label: 'Клетчатка', value: nutrients.fiber!),
          ]),
        ],
      );
}

class NutrientCell extends StatelessWidget {
  const NutrientCell({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(label.toUpperCase(), style: const TextStyle(color: Coco.muted, fontSize: 10, fontWeight: FontWeight.w900)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class AxisRow extends StatelessWidget {
  const AxisRow({super.key, required this.label, required this.value, required this.note});
  final String label;
  final int value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final tier = scoreTier(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))), Text('$value', style: TextStyle(color: tier.color))]),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(value: v, color: tier.color, backgroundColor: Coco.hairline),
          ),
          Text(note, style: const TextStyle(color: Coco.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class Flag extends StatelessWidget {
  const Flag({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CocoCard(
          child: Row(children: [
            const CircleAvatar(backgroundColor: Coco.emerald, child: Icon(Icons.check, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: Coco.muted, fontWeight: FontWeight.w600))),
          ]),
        ),
      );
}

extension StringListX on List<String> {
  String firstOrNullText(String fallback) => isEmpty ? fallback : first;
}
