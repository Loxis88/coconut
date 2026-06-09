import 'package:flutter/material.dart';
import '../domain/product.dart';
import '../theme.dart';
import '../widgets/coco_card.dart';
import '../widgets/product_widgets.dart';
import '../widgets/shared.dart';

const _mockSuggestions = [
  _MockProduct('Кефир Простоквашино 2.5%', 'Данон', 'Молочные продукты', 84),
  _MockProduct('Овсяное молоко Oatly', 'Oatly', 'Растительное молоко', 88),
  _MockProduct('Греческий йогурт Epica', 'Эпика', 'Молочные продукты', 86),
  _MockProduct('Гречка Увелка', 'Увелка', 'Крупы', 92),
  _MockProduct('Шоколад Milka Молочный', 'Mondelez', 'Кондитерские изделия', 45),
  _MockProduct('Чипсы Lay\'s Сметана и лук', 'PepsiCo', 'Снеки', 19),
  _MockProduct('Кола Zero', 'The Coca-Cola Company', 'Напитки', 22),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.history, required this.onBack, required this.onShowProduct});

  final List<Product> history;
  final VoidCallback onBack;
  final void Function(Product product) onShowProduct;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Product> get _results {
    if (_query.isEmpty) return widget.history;
    final q = _query.toLowerCase();
    final fromHistory = widget.history.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.manufacturer.toLowerCase().contains(q) ||
        p.categoryName.toLowerCase().contains(q));
    final fromMock = _mockSuggestions
        .where((m) =>
            m.title.toLowerCase().contains(q) ||
            m.manufacturer.toLowerCase().contains(q) ||
            m.category.toLowerCase().contains(q))
        .map((m) => m.toProduct());
    return [...fromHistory, ...fromMock].toList();
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _query.isEmpty && widget.history.isEmpty;
    final suggestions = _mockSuggestions.map((m) => m.toProduct()).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              RoundIcon(icon: Icons.arrow_back, onTap: widget.onBack),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Поиск продуктов...',
                      hintStyle: TextStyle(color: Coco.muted),
                      icon: Icon(Icons.search, color: Coco.muted),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              showSuggestions ? 'Популярное' : '${_results.length} результатов',
              style: const TextStyle(color: Coco.muted, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Expanded(
          child: () {
            if (showSuggestions) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  CocoCard(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: suggestions
                          .map((p) => ProductRow(product: p, onTap: () => widget.onShowProduct(p)))
                          .toList(),
                    ),
                  ),
                ],
              );
            }
            if (_results.isEmpty) {
              return const Center(child: Text('Ничего не найдено', style: TextStyle(color: Coco.muted)));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              children: [
                CocoCard(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: _results
                        .map((p) => ProductRow(product: p, onTap: () => widget.onShowProduct(p)))
                        .toList(),
                  ),
                ),
              ],
            );
          }(),
        ),
      ],
    );
  }
}

class _MockProduct {
  const _MockProduct(this.title, this.manufacturer, this.category, this.score);
  final String title;
  final String manufacturer;
  final String category;
  final int score;

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
