import 'package:flutter/material.dart';
import '../widgets/coco_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/shared.dart';
import '../widgets/swap_widgets.dart';

class SwapScreen extends StatelessWidget {
  const SwapScreen({super.key, required this.onBack, required this.onClose});

  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              RoundIcon(icon: Icons.arrow_back, onTap: onBack),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Лучшая замена',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900))),
              RoundIcon(icon: Icons.close, onTap: onClose),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              const SwapCard(),
              const SectionTitle('Почему это лучше?'),
              const CocoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    DeltaRow(label: 'Сахар', from: '24г', to: '14г'),
                    Divider(),
                    DeltaRow(label: 'Жиры', from: '18г', to: '12г'),
                    Divider(),
                    DeltaRow(label: 'Добавки', from: 'E471, E412', to: 'Нет'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              PillButton(
                  label: 'Выбрать этот продукт',
                  kind: PillKind.brand,
                  onTap: onClose),
            ],
          ),
        ),
      ],
    );
  }
}
