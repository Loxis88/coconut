import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/auth_user.dart';
import '../theme.dart';

const _dietOptions = ['Без ограничений', 'Вегетарианство', 'Веганство', 'Без глютена', 'Без лактозы', 'Кето'];
const _allergensList = ['Глютен', 'Молоко', 'Яйца', 'Арахис', 'Орехи', 'Соя', 'Морепродукты'];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.streak,
    required this.average,
    required this.scanCount,
    required this.onBack,
    required this.onLogout,
    required this.onUpdateNickname,
    required this.onDeleteAccount,
  });

  final AuthUser user;
  final int streak;
  final int average;
  final int scanCount;
  final VoidCallback onBack;
  final Future<void> Function() onLogout;
  final Future<void> Function(String nickname) onUpdateNickname;
  final Future<void> Function() onDeleteAccount;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _diet = 'Без ограничений';
  final Set<String> _allergens = {};
  bool _notifs = true;
  bool _weekly = true;

  Future<void> _editNickname(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _NicknameDialog(initial: widget.user.nickname ?? ''),
    );
    if (name != null && name.isNotEmpty) await widget.onUpdateNickname(name);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Выйти?', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: const Text('Вы выйдете из аккаунта.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти')),
        ],
      ),
    );
    if (ok == true) await widget.onLogout();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить аккаунт?', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: const Text('Это действие необратимо. Все данные будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC03B32)),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) await widget.onDeleteAccount();
  }

  void _toggleAllergen(String a) {
    setState(() {
      if (_allergens.contains(a)) {
        _allergens.remove(a);
      } else {
        _allergens.add(a);
      }
    });
  }

  String get _displayName => widget.user.nickname?.isNotEmpty == true ? widget.user.nickname! : 'Александра К.';
  String get _initials {
    final name = _displayName.trim();
    if (name.isEmpty) return 'A';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MayakTheme.bg,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
              children: [
                // Hero
                Container(
                  color: const Color(0xFF0D1F0F),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [const Color(0xFF5BAF64).withOpacity(0.15), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _initials,
                                      style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _displayName,
                                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white, letterSpacing: -0.02),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'С нами с мая 2025',
                                          style: GoogleFonts.dmMono(fontSize: 11, color: Colors.white.withOpacity(0.35)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _editNickname(context),
                                    child: Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(child: _HeroStatBox(n: '${widget.scanCount}', label: 'Продуктов')),
                                  const SizedBox(width: 8),
                                  Expanded(child: _HeroStatBox(n: '${widget.average}', label: 'Индекс', highlight: true)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _HeroStatBox(n: '${widget.streak}', label: 'Дней подряд')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Diet
                      _Section(
                        title: 'Тип питания',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _dietOptions.map((d) {
                            final active = _diet == d;
                            return GestureDetector(
                              onTap: () => setState(() => _diet = d),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFF153918) : const Color(0x0F0C1A09),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  d,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                    color: active ? Colors.white : const Color(0xFF5E6859),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Allergens
                      _Section(
                        title: 'Аллергены',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Маяк предупредит, если продукт содержит выбранные аллергены',
                              style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF5E6859), height: 1.5),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _allergensList.map((a) {
                                final active = _allergens.contains(a);
                                return GestureDetector(
                                  onTap: () => _toggleAllergen(a),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: active ? const Color(0x1AC03B32) : const Color(0x0F0C1A09),
                                      border: Border.all(color: active ? const Color(0x33C03B32) : Colors.transparent),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      a,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                        color: active ? const Color(0xFFC03B32) : const Color(0xFF5E6859),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TODO: restore Settings section when push notifications are implemented
                      // _Section(
                      //   title: 'Настройки',
                      //   child: Column(
                      //     children: [
                      //       _ToggleRow(label: 'Push-уведомления', sub: 'Советы и напоминания', on: _notifs, onChange: (v) => setState(() => _notifs = v)),
                      //       _ToggleRow(label: 'Еженедельный отчёт', sub: 'По воскресеньям', on: _weekly, onChange: (v) => setState(() => _weekly = v), last: true),
                      //     ],
                      //   ),
                      // ),
                      // const SizedBox(height: 20),

                      // About
                      _Section(
                        title: 'О приложении',
                        child: Column(
                          children: [
                            _AboutRow(label: 'Источники данных', icon: '🔬', onTap: () {}),
                            _AboutRow(label: 'Политика конфиденциальности', icon: '🔒', onTap: () {}),
                            _AboutRow(label: 'Условия использования', icon: '📄', onTap: () {}),
                            _AboutRow(label: 'Обратная связь', icon: '💬', onTap: () {}, last: true),
                            const SizedBox(height: 12),
                            Text(
                              'МАЯК v2.0.0 · 2026',
                              style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF8A9486)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Account actions
                      _Section(
                        title: 'Аккаунт',
                        child: Column(
                          children: [
                            _AboutRow(
                              label: 'Выйти из аккаунта',
                              icon: '🚪',
                              onTap: () => _confirmLogout(context),
                            ),
                            _AboutRow(
                              label: 'Удалить аккаунт',
                              icon: '🗑',
                              onTap: () => _confirmDelete(context),
                              last: true,
                              destructive: true,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _HeroStatBox extends StatelessWidget {
  final String n;
  final String label;
  final bool highlight;

  const _HeroStatBox({required this.n, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(n, style: GoogleFonts.fraunces(fontWeight: FontWeight.w900, fontSize: 24, color: highlight ? const Color(0xFF5BAF64) : Colors.white, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmMono(fontSize: 9, color: Colors.white.withOpacity(0.3), letterSpacing: 9 * 0.04)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.dmMono(fontSize: 10, color: const Color(0xFF5E6859), letterSpacing: 10 * 0.08),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F0E6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1))],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String sub;
  final bool on;
  final ValueChanged<bool> onChange;
  final bool last;

  const _ToggleRow({required this.label, required this.sub, required this.on, required this.onChange, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0x120C1A09)))),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0C1A09))),
                Text(sub, style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF5E6859))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChange(!on),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44, height: 26,
              decoration: BoxDecoration(
                color: on ? const Color(0xFF153918) : const Color(0xFFB8C0B4),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    left: on ? 22 : 4,
                    top: 4,
                    child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;
  final bool last;
  final bool destructive;

  const _AboutRow({required this.label, required this.icon, required this.onTap, this.last = false, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final textColor = destructive ? const Color(0xFFC03B32) : const Color(0xFF0C1A09);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0x120C1A09)))),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: GoogleFonts.dmSans(fontSize: 14, color: textColor))),
            Icon(Icons.chevron_right_rounded, color: destructive ? const Color(0xFFC03B32) : const Color(0xFF8A9486), size: 20),
          ],
        ),
      ),
    );
  }
}

class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.initial});
  final String initial;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Имя профиля', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: _ctrl,
          focusNode: _focus,
          decoration: const InputDecoration(hintText: 'Введите имя'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      );
}
