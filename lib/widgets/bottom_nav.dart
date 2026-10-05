import 'package:flutter/material.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/widgets/common.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.index, required this.onTap});

  static const _items = <_NavSpec>[
    _NavSpec('Today', Icons.today_outlined, Icons.today_rounded),
    _NavSpec('Calendar', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
    _NavSpec('Tasks', Icons.checklist_rounded, Icons.checklist_rtl_rounded),
    _NavSpec('Insights', Icons.insights_outlined, Icons.insights_rounded),
    _NavSpec('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.surface.o(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: p.border.o(0.6))),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 30, offset: const Offset(0, -8))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    spec: _items[i],
                    selected: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavSpec(this.label, this.icon, this.activeIcon);
}

class _NavItem extends StatelessWidget {
  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.spec, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: Pressable(
        onTap: onTap,
        scale: 0.92,
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: selected ? 58 : 36,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.o(p.dark ? 0.28 : 0.16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  selected ? spec.activeIcon : spec.icon,
                  size: 24,
                  color: selected ? AppColors.primary : p.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.primary : p.textMuted,
                ),
                child: Text(spec.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
