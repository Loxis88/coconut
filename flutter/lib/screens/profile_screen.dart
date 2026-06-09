import 'package:flutter/material.dart';
import '../domain/auth_user.dart';
import '../theme.dart';
import '../widgets/shared.dart';

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
  late final TextEditingController _nickname;
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(text: widget.user.nickname ?? '');
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  String get _displayName => widget.user.nickname?.isNotEmpty == true ? widget.user.nickname! : 'Пользователь';
  String get _initials {
    final name = _displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(backgroundColor: Coco.hairline),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Профиль', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8))),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
                style: IconButton.styleFrom(backgroundColor: Coco.hairline),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Avatar(initials: _initials, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _editing
                          ? Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nickname,
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                    decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Coco.emerald, size: 20),
                                  onPressed: () async {
                                    await widget.onUpdateNickname(_nickname.text);
                                    setState(() => _editing = false);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() => _editing = false),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                                const SizedBox(height: 1),
                                Text(widget.user.email, style: const TextStyle(fontSize: 13, color: Coco.muted, fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                    if (!_editing)
                      SizedBox(
                        width: 34, height: 34,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => _editing = true),
                          icon: const Icon(Icons.chevron_right, size: 20),
                          style: IconButton.styleFrom(backgroundColor: Coco.hairline),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatBox(value: '${widget.streak}', label: 'дней подряд', color: Coco.coral),
                    const SizedBox(width: 8),
                    _StatBox(value: '${widget.average}', label: 'средний балл', color: Coco.emerald),
                    const SizedBox(width: 8),
                    _StatBox(value: '${widget.scanCount}', label: 'сканов', color: Coco.ink),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(gradient: Coco.brandGradient, borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .1), shape: BoxShape.circle),
                        child: const Icon(Icons.workspace_premium, color: Coco.brownDeep, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Coconut Plus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Coco.brownDeep, letterSpacing: -0.3)),
                            Text('Активна · продление 14 июня', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Coco.brownDeep)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Coco.brownDeep),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _GroupLabel('Настройки'),
                const _SettingsCard(children: [
                  _SettingsRow(icon: Icons.track_changes_outlined, title: 'Цели и предпочтения'),
                  _SettingsRow(icon: Icons.notifications_none, title: 'Уведомления', trailing: _Toggle(on: true), divider: true),
                  _SettingsRow(icon: Icons.language, title: 'Язык', value: 'Русский', divider: true),
                ]),
                const _GroupLabel('Поддержка и данные'),
                const _SettingsCard(children: [
                  _SettingsRow(icon: Icons.help_outline, title: 'Техподдержка', isLink: true),
                  _SettingsRow(icon: Icons.shield_outlined, title: 'Конфиденциальность', divider: true),
                  _SettingsRow(icon: Icons.info_outline, title: 'О приложении', value: 'v1.0.0', divider: true),
                ]),
                const _GroupLabel('Аккаунт'),
                _SettingsCard(children: [
                  _SettingsRow(icon: Icons.logout, title: 'Выйти из аккаунта', onTap: widget.onLogout),
                  _SettingsRow(
                    icon: Icons.delete_outline,
                    title: 'Удалить аккаунт',
                    tone: Coco.red,
                    divider: true,
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить аккаунт?'),
                        content: const Text('Вы уверены, что хотите безвозвратно удалить свой аккаунт и все данные?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                          TextButton(
                            onPressed: () async { Navigator.pop(ctx); await widget.onDeleteAccount(); },
                            child: const Text('Удалить', style: TextStyle(color: Coco.red)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  '$v',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: color, letterSpacing: -1, height: 1),
                ),
              ),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Coco.muted, fontWeight: FontWeight.w600, height: 1.15)),
            ],
          ),
        ),
      );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Coco.muted, letterSpacing: 1.5)),
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.hardEdge,
        child: Column(children: children),
      );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.tone,
    this.divider = false,
    this.isLink = false,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final Color? tone;
  final bool divider;
  final bool isLink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? Coco.ink;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          if (divider) const Divider(height: 1, indent: 58, endIndent: 0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color.withValues(alpha: tone == Coco.red ? 1 : .85)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.2)),
                ),
                if (value != null)
                  Text(value!, style: const TextStyle(fontSize: 14, color: Coco.muted, fontWeight: FontWeight.w600)),
                if (trailing != null) trailing!,
                if (value == null && trailing == null)
                  Icon(
                    isLink ? Icons.arrow_forward : Icons.chevron_right,
                    size: isLink ? 18 : 24,
                    color: tone == Coco.red ? Coco.red.withValues(alpha: .6) : Coco.muted,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46, height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: on ? Coco.emerald : Colors.black.withValues(alpha: .18),
        ),
        child: Align(
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22, height: 22,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))]),
          ),
        ),
      );
}
