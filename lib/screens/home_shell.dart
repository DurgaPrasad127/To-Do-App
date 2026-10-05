import 'package:flutter/material.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/screens/calendar/calendar_screen.dart';
import 'package:timeblock/screens/insights/insights_screen.dart';
import 'package:timeblock/screens/settings/settings_screen.dart';
import 'package:timeblock/screens/tasks/tasks_screen.dart';
import 'package:timeblock/screens/today/today_screen.dart';
import 'package:timeblock/widgets/bottom_nav.dart';
import 'package:timeblock/widgets/common.dart';
import 'package:timeblock/widgets/task_editor_sheet.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _tab =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..value = 1;
  final ValueNotifier<DateTime> _calSelected = ValueNotifier<DateTime>(Fmt.day(DateTime.now()));

  @override
  void dispose() {
    _tab.dispose();
    _calSelected.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _tab.forward(from: 0);
  }

  void _add() {
    final date = _index == 1 ? _calSelected.value : Fmt.day(DateTime.now());
    showTaskEditor(context, initialDate: date);
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _tab, curve: Curves.easeOutCubic);
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(0);
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
              child: IndexedStack(
                index: _index,
                children: [
                  TodayScreen(onProfileTap: () => _go(4)),
                  CalendarScreen(selected: _calSelected),
                  const TasksScreen(),
                  const InsightsScreen(),
                  const SettingsScreen(),
                ],
              ),
            ),
          ),
          floatingActionButton: _Fab(visible: _index <= 2, onTap: _add),
          bottomNavigationBar: AppBottomNav(index: _index, onTap: _go),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  const _Fab({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      curve: visible ? Curves.easeOutBack : Curves.easeIn,
      child: IgnorePointer(
        ignoring: !visible,
        child: Semantics(
          button: true,
          label: 'Add task',
          child: Pressable(
            onTap: onTap,
            scale: 0.9,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: AppColors.primary.o(0.5), blurRadius: 24, offset: const Offset(0, 12))],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
            ),
          ),
        ),
      ),
    );
  }
}
