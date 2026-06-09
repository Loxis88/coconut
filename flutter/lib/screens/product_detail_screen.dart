import 'package:flutter/material.dart';
import '../domain/product.dart';
import '../theme.dart';
import '../widgets/coco_card.dart';
import '../widgets/product_widgets.dart';
import '../widgets/score_widgets.dart';
import '../widgets/shared.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product, required this.onBack, required this.onSwap});

  final Product product;
  final VoidCallback onBack;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final tier = scoreTier(product.score);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              RoundIcon(icon: Icons.arrow_back, onTap: onBack),
              const Spacer(),
              RoundIcon(icon: Icons.favorite_border, onTap: () {}),
              RoundIcon(icon: Icons.swap_horiz, onTap: onSwap),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductThumb(product: product, size: 88, radius: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (product.manufacturer.isNotEmpty ? product.manufacturer : product.categoryName).toUpperCase(),
                          style: const TextStyle(color: Coco.muted, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                        Text(product.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
                        if (product.price.isNotEmpty) Text(product.price, style: const TextStyle(color: Coco.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              CocoCard(
                color: tier.background,
                child: Row(
                  children: [
                    ScoreRing(score: product.score, size: 104, showLabel: false),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${tier.label}.', style: TextStyle(color: tier.ink, fontSize: 26, fontWeight: FontWeight.w900)),
                          Text(
                            product.worth.firstOrNullText('Рейтинг по стандартам Coconut.'),
                            style: TextStyle(color: tier.ink.withValues(alpha: .75), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (product.nutrients != null) ...[
                const SectionTitle('Пищевая ценность'),
                NutrientGrid(nutrients: product.nutrients!),
              ],
              if ((product.composition ?? '').isNotEmpty) ...[
                const SectionTitle('Состав'),
                CocoCard(child: Text(product.composition!)),
              ],
              const SectionTitle('Критерии качества'),
              CocoCard(
                child: product.criteriaRatings.isEmpty
                    ? const Text('Детальные критерии отсутствуют.', style: TextStyle(color: Coco.muted))
                    : Column(
                        children: product.criteriaRatings
                            .map((item) => AxisRow(label: item.title, value: (item.value * 20).round(), note: '${item.value} / 5'))
                            .toList(),
                      ),
              ),
              if (product.worth.isNotEmpty) ...[
                const SectionTitle('Стоит отметить'),
                ...product.worth.map((item) => Flag(text: item)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
