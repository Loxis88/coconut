import 'package:flutter/material.dart';
import '../theme.dart';
import 'shared.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.onScan, required this.onProfile, required this.onSearch, required this.onJournal});
  final VoidCallback onScan;
  final VoidCallback onProfile;
  final VoidCallback onSearch;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x121a1410), blurRadius: 16, offset: Offset(0, -4))],
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavItem(icon: Icons.home, label: 'Главная', active: false, onTap: () {}),
            NavItem(icon: Icons.edit_note, label: 'Журнал', active: false, onTap: onJournal),
            InkWell(onTap: onScan, child: const Column(children: [CircleIcon(icon: Icons.center_focus_strong), Text('Скан')])),
            NavItem(icon: Icons.search, label: 'Поиск', active: false, onTap: onSearch),
            NavItem(icon: Icons.person, label: 'Профиль', active: false, onTap: onProfile),
          ],
        ),
      );
}

class NavItem extends StatelessWidget {
  const NavItem({super.key, required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 62,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            color: active ? Coco.ink.withValues(alpha: .07) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, key: ValueKey(active), color: active ? Coco.ink : Coco.muted),
              ),
              Text(label, maxLines: 1, softWrap: false, overflow: TextOverflow.visible, style: TextStyle(color: active ? Coco.ink : Coco.muted, fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
            ],
          ),
        ),
      );
}
