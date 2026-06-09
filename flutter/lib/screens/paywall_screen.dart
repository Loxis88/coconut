import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/coconut_mark.dart';
import '../widgets/pill_button.dart';
import '../widgets/shared.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, required this.onClose, required this.onSubscribe});
  final VoidCallback onClose;
  final VoidCallback onSubscribe;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  var _yearly = true;

  static const _perks = [
    ('Вся история — твоя навсегда', 'Сохрани 146 сканов и следи, как растёт средний балл по неделям'),
    ('Что купить вместо', 'Не просто «ешь полезнее» — точная замена твоему продукту под твои цели'),
    ('Проверяй до кассы', 'Мгновенный поиск по 2,3 млн товаров — прямо в магазине'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Coco.ink,
      body: Stack(
        children: [
          // Тёмный вертикальный градиент фона
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xff241d15), Coco.ink],
                ),
              ),
            ),
          ),
          // Радиальное лаймовое свечение за hero (как в референсе)
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.85),
                    radius: 0.9,
                    colors: [Color(0x66bef264), Color(0x00bef264)],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.white10),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Восстановить', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CoconutMark(size: 30),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.6),
                          children: [
                            TextSpan(text: 'Coconut ', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'Plus', style: TextStyle(color: Coco.lime)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600, height: 1.3),
                      children: [
                        TextSpan(text: 'Ты уже отсканировал 146 продуктов — '),
                        TextSpan(text: 'не теряй историю', style: TextStyle(color: Coco.lime)),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                children: _perks.map((perk) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22, height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Coco.brandGradient),
                        child: const Icon(Icons.check, size: 13, color: Coco.brownDeep),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(perk.$1, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                            const SizedBox(height: 1),
                            Text(perk.$2, style: const TextStyle(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  _PlanCard(
                    active: _yearly,
                    onTap: () => setState(() => _yearly = true),
                    badge: '−40%',
                    title: 'Год',
                    monthly: '332 ₽',
                    total: '3 990 ₽ в год',
                    strike: '6 690 ₽',
                  ),
                  const SizedBox(height: 10),
                  _PlanCard(
                    active: !_yearly,
                    onTap: () => setState(() => _yearly = false),
                    badge: '7 дней бесплатно',
                    title: 'Месяц',
                    monthly: '549 ₽',
                    total: 'первая неделя — 0 ₽',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x1abef264),
                  border: Border.all(color: const Color(0x33bef264)),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(15),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Avatar(initials: 'А', size: 42),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.star, color: Coco.amber, size: 13),
                            Icon(Icons.star, color: Coco.amber, size: 13),
                            Icon(Icons.star, color: Coco.amber, size: 13),
                            Icon(Icons.star, color: Coco.amber, size: 13),
                            Icon(Icons.star, color: Coco.amber, size: 13),
                          ]),
                          SizedBox(height: 4),
                          Text(
                            '«Перестала покупать половину старых снеков за месяц»',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, height: 1.35, fontStyle: FontStyle.italic),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Алина · подписка 3 мес.',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: PillButton(
                label: _yearly ? 'Начать за 332 ₽/мес' : 'Попробовать бесплатно 7 дней',
                icon: Icons.arrow_forward,
                kind: PillKind.brand,
                onTap: widget.onSubscribe,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                _yearly
                    ? '3 990 ₽ спишется сегодня, продление раз в год. Отмена в любой момент.\nУсловия · Конфиденциальность'
                    : 'Затем 549 ₽/мес. Отменить можно в любой момент до конца пробного периода.\nУсловия · Конфиденциальность',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.active,
    required this.onTap,
    required this.badge,
    required this.title,
    required this.monthly,
    required this.total,
    this.strike,
  });

  final bool active;
  final VoidCallback onTap;
  final String badge;
  final String title;
  final String monthly;
  final String total;
  final String? strike;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: .06),
          border: Border.all(
            color: active ? Coco.lime : Colors.white.withValues(alpha: .12),
            width: active ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Coco.emerald : Colors.transparent,
                border: active ? null : Border.all(color: Colors.white30, width: 2),
              ),
              child: active ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: active ? Coco.ink : Colors.white)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: active ? Coco.brandGradient : null,
                          color: active ? null : const Color(0x2ebef264),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(badge, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: active ? Coco.brownDeep : Coco.lime)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(monthly, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1, color: active ? Coco.ink : Colors.white)),
                      const SizedBox(width: 5),
                      Text('/мес', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Coco.muted : Colors.white54)),
                      if (strike != null) ...[
                        const SizedBox(width: 7),
                        Text(strike!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Coco.muted : Colors.white38, decoration: TextDecoration.lineThrough, decorationColor: active ? Coco.muted : Colors.white38)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 96,
              child: Text(
                total,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Coco.muted : Colors.white54, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
