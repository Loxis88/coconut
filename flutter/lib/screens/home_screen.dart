import 'package:flutter/material.dart';
import '../domain/auth_user.dart';
import '../domain/product.dart';
import '../theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/coco_card.dart';
import '../widgets/coconut_mark.dart';
import '../widgets/product_widgets.dart';
import '../widgets/score_widgets.dart';
import '../widgets/shared.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.history,
    required this.average,
    required this.streak,
    required this.onScan,
    required this.onProfile,
    required this.onSearch,
    required this.onJournal,
    required this.onShowProduct,
    required this.onClearHistory,
    required this.onDeleteProduct,
  });

  final AuthUser user;
  final List<Product> history;
  final int average;
  final int streak;
  final VoidCallback onScan;
  final VoidCallback onProfile;
  final VoidCallback onSearch;
  final VoidCallback onJournal;
  final void Function(Product product) onShowProduct;
  final Future<void> Function() onClearHistory;
  final Future<void> Function(Product product) onDeleteProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Row(
            children: [
              const CoconutMark(size: 36),
              const SizedBox(width: 10),
              const Expanded(child: Text('Coconut', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
              SmallCounter(icon: Icons.local_fire_department, value: streak),
              RoundIcon(icon: Icons.notifications_none, onTap: () {}),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              const Text('Сегодня', style: TextStyle(color: Coco.muted, fontWeight: FontWeight.w700)),
              Text(
                'Привет, ${user.nickname ?? 'Пользователь'}\nвсе идет по плану.',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.05),
              ),
              const SizedBox(height: 14),
              CocoCard(
                gradient: Coco.brandGradient,
                child: Row(
                  children: [
                    ScoreRing(score: history.isEmpty ? 0 : average, size: 120, showLabel: false),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('СРЕДНИЙ БАЛЛ', style: TextStyle(color: Coco.brownDeep, fontWeight: FontWeight.w900)),
                          Text(
                            history.isEmpty ? 'Сканируй' : 'Пока\nнеплохо.',
                            style: const TextStyle(color: Coco.brownDeep, fontSize: 26, fontWeight: FontWeight.w900, height: 1.05),
                          ),
                          Text('${history.length} total scans', style: const TextStyle(color: Coco.brownDeep)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CocoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Эта неделя', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                        Text('ср. балл ${history.isEmpty ? 0 : average}', style: const TextStyle(color: Coco.muted)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    WeekBars(values: [0, 0, 0, 0, 0, 0, history.isEmpty ? 0 : average]),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(child: Text('История', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                  TextButton(onPressed: onClearHistory, child: const Text('Очистить', style: TextStyle(color: Coco.red))),
                ],
              ),
              CocoCard(
                padding: const EdgeInsets.all(6),
                child: history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Пока ничего нет. Нажми кнопку сканирования, чтобы начать!', style: TextStyle(color: Coco.muted)),
                      )
                    : Column(
                        children: history
                            .map(
                              (product) => Dismissible(
                                key: ValueKey(product.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 22),
                                  margin: const EdgeInsets.symmetric(vertical: 3),
                                  decoration: BoxDecoration(color: Coco.red, borderRadius: BorderRadius.circular(16)),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) => onDeleteProduct(product),
                                child: ProductRow(product: product, onTap: () => onShowProduct(product)),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        BottomNav(onScan: onScan, onProfile: onProfile, onSearch: onSearch, onJournal: onJournal),
      ],
    );
  }
}
