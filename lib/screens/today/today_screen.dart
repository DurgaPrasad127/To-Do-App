import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/providers/settings_provider.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/widgets/common.dart';
import 'package:timeblock/widgets/progress_card.dart';
import 'package:timeblock/widgets/task_editor_sheet.dart';
import 'package:timeblock/widgets/timeline.dart';

class TodayScreen extends StatelessWidget {
  final VoidCallback onProfileTap;
  const TodayScreen({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TaskProvider>();
    final st = context.watch<SettingsProvider>();

    return MinuteBuilder(
      builder: (context, now) {
        final today = Fmt.day(now);
        final tasks = tp.forDate(today);
        final stats = tp.statsFor(today);
        final p = context.pal;

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  now: now,
                  name: st.name,
                  avatarColor: st.avatarColor,
                  dayEndMin: st.dayEndMin,
                  total: stats.total,
                  done: stats.done,
                  onProfileTap: onProfileTap,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: ProgressCard(done: stats.done, total: stats.total, goal: st.dailyGoal),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: SectionHeader(
                    title: "Today's schedule",
                    trailing: Text(
                      stats.total == 0
                          ? ''
                          : '${Fmt.duration(stats.plannedMin)} planned',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textMuted),
                    ),
                  ),
                ),
              ),
              if (tasks.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Your day is clear ✨',
                    subtitle: 'Add a task and start planning.',
                    actionLabel: 'Add task',
                    onAction: () => showTaskEditor(context, initialDate: today),
                  ),
                )
              else
                SliverTaskTimeline(tasks: tasks, date: today, now: now, heroScope: 'today'),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime now;
  final String name;
  final int avatarColor;
  final int dayEndMin;
  final int total;
  final int done;
  final VoidCallback onProfileTap;

  const _Header({
    required this.now,
    required this.name,
    required this.avatarColor,
    required this.dayEndMin,
    required this.total,
    required this.done,
    required this.onProfileTap,
  });

  String _subtitle() {
    if (total == 0) return 'Plan your day, one block at a time.';
    if (done == total) return 'Everything done. Time to recharge! 🎉';
    if (done == 0) return "Let's make today count.";
    return '${total - done} to go. You are doing great.';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final left = dayEndMin - Fmt.minutesOf(now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Fmt.greeting(now.hour)}${name.isEmpty ? '' : ', $name'} 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: p.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  Fmt.dateLong(now),
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    height: 1.1,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle(),
                  style: TextStyle(fontSize: 14.5, color: p.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Semantics(
                button: true,
                label: 'Open profile',
                child: Pressable(
                  onTap: onProfileTap,
                  scale: 0.9,
                  child: AvatarBadge(name: name, colorIndex: avatarColor, size: 48),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: p.surface.o(0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border.o(0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      Fmt.time(Fmt.minutesOf(now)),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.text),
                    ),
                  ],
                ),
              ),
              if (left > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${Fmt.duration(left)} left',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.textFaint),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
