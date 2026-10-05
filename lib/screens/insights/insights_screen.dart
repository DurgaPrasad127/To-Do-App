import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/constants/task_options.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/widgets/common.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  DateTime _weekStart = Fmt.weekStart(DateTime.now());

  void _shift(int weeks) {
    HapticFeedback.selectionClick();
    setState(() => _weekStart = Fmt.addDays(_weekStart, weeks * 7));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tp = context.watch<TaskProvider>();
    final today = Fmt.day(DateTime.now());
    final todayStats = tp.statsFor(today);
    final week = tp.rangeStats(_weekStart, 7);
    final days = [for (var i = 0; i < 7; i++) tp.statsFor(Fmt.addDays(_weekStart, i))];

    // best day: highest completion %, ties broken by tasks completed
    int best = -1;
    for (var i = 0; i < 7; i++) {
      if (days[i].total == 0) continue;
      if (best < 0 ||
          days[i].percent > days[best].percent ||
          (days[i].percent == days[best].percent && days[i].done > days[best].done)) {
        best = i;
      }
    }
    final bestLabel = (best < 0 || days[best].done == 0) ? '—' : Fmt.weekdays[best];

    // category distribution for the week
    final counts = <String, int>{};
    for (final t in tp.rangeTasks(_weekStart, 7)) {
      final name = categoryInfo(t.category).name;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final cats = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCat = cats.isEmpty ? 1 : cats.first.value;

    final maxPlanned = days.fold<int>(1, (m, d) => d.total > m ? d.total : m);
    final isThisWeek = Fmt.same(_weekStart, Fmt.weekStart(today));
    final weekLabel = isThisWeek
        ? 'This week'
        : '${Fmt.dateShort(_weekStart)} – ${Fmt.dateShort(Fmt.addDays(_weekStart, 6))}';

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenTitle(title: 'Insights', subtitle: 'See how consistent you are'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Arrow(icon: Icons.chevron_left_rounded, label: 'Previous week', onTap: () => _shift(-1)),
                      Expanded(
                        child: Center(
                          child: Text(
                            weekLabel,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
                          ),
                        ),
                      ),
                      _Arrow(icon: Icons.chevron_right_rounded, label: 'Next week', onTap: () => _shift(1)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.today_rounded,
                          label: "Today's completion",
                          value: todayStats.percentInt,
                          suffix: '%',
                          caption: '${todayStats.done} of ${todayStats.total} tasks',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.date_range_rounded,
                          label: 'Weekly completion',
                          value: week.percentInt,
                          suffix: '%',
                          caption: '${week.done} of ${week.total} tasks',
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.task_alt_rounded,
                          label: 'Tasks completed',
                          value: week.done,
                          caption: '${tp.totalCompleted} all time',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.timer_rounded,
                          label: 'Focused time',
                          text: Fmt.duration(week.doneMin),
                          caption: 'of ${Fmt.duration(week.plannedMin)} planned',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.warning.o(0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: AppColors.warning),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text('Best day', style: TextStyle(fontWeight: FontWeight.w700, color: p.textMuted)),
                        ),
                        Text(
                          bestLabel,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Weekly activity',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text)),
                        ),
                        _Dot(color: AppColors.primary, label: 'Done'),
                        const SizedBox(width: 12),
                        _Dot(color: p.surfaceAlt, label: 'Planned', border: p.border),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 176,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: _Bar(
                                key: ValueKey('${Fmt.key(_weekStart)}-$i'),
                                label: Fmt.weekdaysShort[i].substring(0, 3),
                                planned: days[i].total,
                                done: days[i].done,
                                max: maxPlanned,
                                highlight: Fmt.same(Fmt.addDays(_weekStart, i), today),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Categories',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text)),
                    const SizedBox(height: 14),
                    if (cats.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text('No tasks planned this week.',
                            style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w500)),
                      )
                    else
                      for (final e in cats)
                        _CategoryRow(
                          info: categoryInfo(e.key),
                          count: e.value,
                          fraction: e.value / maxCat,
                          share: e.value / week.total,
                        ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Arrow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.85,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: p.surface.o(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: p.border.o(0.6)),
          ),
          child: Icon(icon, color: p.textMuted),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? value;
  final String? text;
  final String suffix;
  final String caption;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.caption,
    required this.color,
    this.value,
    this.text,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final style = TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: p.text);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.o(0.16), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: value != null ? AnimatedCount(value: value!, suffix: suffix, style: style) : Text(text ?? '', style: style),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.text)),
          Text(caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.textMuted)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  final Color? border;
  const _Dot({required this.color, required this.label, this.border});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border!),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textMuted)),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int planned;
  final int done;
  final int max;
  final bool highlight;
  const _Bar({
    super.key,
    required this.label,
    required this.planned,
    required this.done,
    required this.max,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const maxH = 120.0;
    return Semantics(
      label: '$label: $done of $planned tasks completed',
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 20,
            child: Text(
              planned == 0 ? '' : '$done',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.textMuted),
            ),
          ),
          SizedBox(
            height: maxH,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                final plannedH = planned == 0 ? 6.0 : (planned / max) * maxH * t;
                final doneH = done == 0 ? 0.0 : (done / max) * maxH * t;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 22,
                        height: plannedH < 6 ? 6 : plannedH,
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      Container(
                        width: 22,
                        height: doneH,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
              color: highlight ? AppColors.primary : p.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryInfo info;
  final int count;
  final double fraction;
  final double share;
  const _CategoryRow({
    required this.info,
    required this.count,
    required this.fraction,
    required this.share,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = AppColors.taskColor(info.colorIndex).color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.o(0.16), borderRadius: BorderRadius.circular(12)),
            child: Icon(info.icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(info.name,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: p.text)),
                    ),
                    Text('$count · ${(share * 100).round()}%',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: p.textMuted)),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: p.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
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
