import 'package:flutter/material.dart';
import '../domain/product.dart';
import '../theme.dart';
import '../widgets/coco_card.dart';
import '../widgets/product_widgets.dart';
import '../widgets/score_widgets.dart';
import '../widgets/shared.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key, required this.onBack, required this.onShowProduct});

  final VoidCallback onBack;
  final void Function(Product product) onShowProduct;

  static const _mock = [
    _Entry('Кефир Простоквашино 2.5%', 'Данон', 'Молочные продукты', 84, 0),
    _Entry('Чипсы Lay\'s Сметана и лук', 'PepsiCo', 'Снеки', 19, 0),
    _Entry('Овсяное молоко Oatly', 'Oatly', 'Растительное молоко', 88, 0),
    _Entry('Кола Zero', 'The Coca-Cola Company', 'Напитки', 22, 1),
    _Entry('Греческий йогурт Epica', 'Эпика', 'Молочные продукты', 86, 1),
    _Entry('Шоколад Milka Молочный', 'Mondelez', 'Кондитерские изделия', 45, 2),
    _Entry('Гречка Увелка', 'Увелка', 'Крупы', 92, 2),
  ];

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<_Entry>>{};
    for (final e in _mock) {
      final key = switch (e.daysAgo) { 0 => 'Сегодня', 1 => 'Вчера', _ => '2 июня' };
      (grouped[key] ??= []).add(e);
    }

    final todayScores = _mock.where((e) => e.daysAgo == 0).map((e) => e.score);
    final avgToday = todayScores.isEmpty ? 0 : todayScores.reduce((a, b) => a + b) ~/ todayScores.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              RoundIcon(icon: Icons.arrow_back, onTap: onBack),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Журнал', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ),
              Text('${_mock.length} сканов', style: const TextStyle(color: Coco.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              CocoCard(
                gradient: Coco.brandGradient,
                child: Row(
                  children: [
                    ScoreRing(score: avgToday, size: 90, showLabel: false),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('СЕГОДНЯ', style: TextStyle(color: Coco.brownDeep, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                        SizedBox(height: 2),
                        Text('Средний\nбалл', style: TextStyle(color: Coco.brownDeep, fontSize: 22, fontWeight: FontWeight.w900, height: 1.05)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              for (final group in grouped.entries) ...[
                Text(group.key, style: const TextStyle(color: Coco.muted, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                CocoCard(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: group.value.map((e) {
                      final p = e.toProduct();
                      return ProductRow(product: p, onTap: () => onShowProduct(p));
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Entry {
  const _Entry(this.title, this.manufacturer, this.category, this.score, this.daysAgo);
  final String title;
  final String manufacturer;
  final String category;
  final int score;
  final int daysAgo;

  Product toProduct() => Product(
        id: title.hashCode,
        title: title,
        totalRating: score / 20,
        description: '',
        categoryName: category,
        manufacturer: manufacturer,
        price: '',
        thumbnail: null,
        criteriaRatings: const [],
        worth: const [],
        info: const [],
        recommendations: const [],
        nutrients: null,
        composition: null,
        hasQualityMark: false,
        hasBadQualityMark: false,
      );
}
