import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/widgets/common.dart';

/// ● tasks exist · ◐ partly done · ✓ all done
class StatusMark extends StatelessWidget {
  final DayStats stats;
  const StatusMark({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.total == 0) return const SizedBox.shrink();
    if (stats.done == stats.total) {
      return const Center(child: Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success));
    }
    if (stats.done == 0) {
      return Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        ),
      );
    }
    return Center(
      child: CustomPaint(size: const Size(10, 10), painter: _HalfDotPainter(AppColors.primary)),
    );
  }
}

class _HalfDotPainter extends CustomPainter {
  final Color color;
  const _HalfDotPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    final fill = Paint()..color = color;
    final inner = rect.deflate(0.7);
    canvas.drawArc(inner, math.pi / 2, math.pi, true, fill);
    canvas.drawOval(inner, outline);
  }

  @override
  bool shouldRepaint(_HalfDotPainter old) => old.color != color;
}

class CalendarWidget extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const CalendarWidget({super.key, required this.selected, required this.onSelect});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  @override
  void didUpdateWidget(CalendarWidget old) {
    super.didUpdateWidget(old);
    if (!Fmt.same(old.selected, widget.selected) &&
        (widget.selected.year != _month.year || widget.selected.month != _month.month)) {
      _month = DateTime(widget.selected.year, widget.selected.month);
    }
  }

  void _shift(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _goToday() {
    final t = Fmt.day(DateTime.now());
    setState(() => _month = DateTime(t.year, t.month));
    widget.onSelect(t);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tp = context.watch<TaskProvider>();
    final today = Fmt.day(DateTime.now());
    final first = DateTime(_month.year, _month.month, 1);
    final lead = first.weekday - 1;
    final dim = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((lead + dim) / 7).ceil();

    Widget cell(int dayNum) {
      final d = DateTime(_month.year, _month.month, dayNum);
      final stats = tp.statsFor(d);
      final isSel = Fmt.same(d, widget.selected);
      final isToday = Fmt.same(d, today);
      final summary = stats.total == 0 ? 'no tasks' : '${stats.done} of ${stats.total} completed';
      return Expanded(
        child: Semantics(
          button: true,
          selected: isSel,
          label: '${Fmt.dateLong(d)}, $summary',
          child: Pressable(
            onTap: () => widget.onSelect(d),
            scale: 0.9,
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSel ? AppColors.brandGradient : null,
                      border: (!isSel && isToday) ? Border.all(color: AppColors.primary, width: 1.8) : null,
                      boxShadow: isSel
                          ? [BoxShadow(color: AppColors.primary.o(0.35), blurRadius: 12, offset: const Offset(0, 5))]
                          : const <BoxShadow>[],
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: (isSel || isToday) ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? Colors.white : p.text,
                      ),
                      child: Text('$dayNum'),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(height: 12, child: StatusMark(stats: stats)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final grid = Column(
      key: ValueKey(Fmt.key(_month)),
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                () {
                  final dayNum = r * 7 + c - lead + 1;
                  if (dayNum < 1 || dayNum > dim) {
                    return const Expanded(child: SizedBox(height: 56));
                  }
                  return cell(dayNum);
                }(),
            ],
          ),
      ],
    );

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Align(
                    key: ValueKey(Fmt.key(_month)),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Fmt.monthYear(_month),
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: p.text),
                    ),
                  ),
                ),
              ),
              _NavButton(icon: Icons.chevron_left_rounded, label: 'Previous month', onTap: () => _shift(-1)),
              Semantics(
                button: true,
                label: 'Jump to today',
                child: Pressable(
                  onTap: _goToday,
                  scale: 0.94,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.o(0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              _NavButton(icon: Icons.chevron_right_rounded, label: 'Next month', onTap: () => _shift(1)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final w in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.textFaint),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 260), child: grid),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: Row(
              children: [
                _Legend(mark: const StatusMark(stats: DayStats(2, 0, 0, 0)), text: 'Planned'),
                const SizedBox(width: 14),
                _Legend(mark: const StatusMark(stats: DayStats(2, 1, 0, 0)), text: 'Partial'),
                const SizedBox(width: 14),
                _Legend(mark: const StatusMark(stats: DayStats(2, 2, 0, 0)), text: 'All done'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Widget mark;
  final String text;
  const _Legend({required this.mark, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        SizedBox(width: 14, height: 14, child: mark),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.textMuted)),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.85,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 28, color: p.textMuted),
        ),
      ),
    );
  }
}

/// "9 tasks planned · 6 completed · 67%" card for any date.
class DaySummaryCard extends StatelessWidget {
  final DateTime date;
  const DaySummaryCard({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<TaskProvider>().statsFor(date);
    final today = Fmt.day(DateTime.now());
    final rel = Fmt.relativeDay(date, today);
    final isRel = rel == 'Today' || rel == 'Tomorrow' || rel == 'Yesterday';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Fmt.dateLong(date),
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: p.text),
                ),
              ),
              if (isRel)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.o(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (s.total == 0)
            Text(
              'No tasks planned for this day.',
              style: TextStyle(fontSize: 14.5, color: p.textMuted, fontWeight: FontWeight.w500),
            )
          else ...[
            Row(
              children: [
                _Stat(value: '${s.total}', label: 'planned'),
                _Stat(value: '${s.done}', label: 'completed'),
                _Stat(value: '${s.percentInt}%', label: 'completion'),
              ],
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: s.percent),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(height: 8, color: p.surfaceAlt),
                    FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        height: 8,
                        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${Fmt.duration(s.plannedMin)} planned · ${Fmt.duration(s.doneMin)} done',
              style: TextStyle(fontSize: 12.5, color: p.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: p.text)),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textMuted)),
        ],
      ),
    );
  }
}

/// Monday → Sunday overview of one week. Tap a day to open its timeline.
class WeekOverview extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onOpenDay;

  const WeekOverview({
    super.key,
    required this.weekStart,
    required this.onPrev,
    required this.onNext,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tp = context.watch<TaskProvider>();
    final today = Fmt.day(DateTime.now());
    final end = Fmt.addDays(weekStart, 6);
    final label = '${Fmt.dateShort(weekStart)} – ${Fmt.dateShort(end)}';

    return Column(
      children: [
        Row(
          children: [
            _NavButton(icon: Icons.chevron_left_rounded, label: 'Previous week', onTap: onPrev),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
                ),
              ),
            ),
            _NavButton(icon: Icons.chevron_right_rounded, label: 'Next week', onTap: onNext),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(builder: (context) {
              final d = Fmt.addDays(weekStart, i);
              final s = tp.statsFor(d);
              final isToday = Fmt.same(d, today);
              return Appear(
                index: i,
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  radius: 22,
                  onTap: () => onOpenDay(d),
                  child: Semantics(
                    label: '${Fmt.dateLong(d)}, ${s.total} tasks, ${s.done} completed',
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: isToday ? AppColors.brandGradient : null,
                            color: isToday ? null : p.surfaceAlt,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                Fmt.weekdaysShort[d.weekday - 1],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isToday ? Colors.white.o(0.85) : p.textMuted,
                                ),
                              ),
                              Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: isToday ? Colors.white : p.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: s.total == 0
                              ? Text(
                                  'Nothing planned',
                                  style: TextStyle(fontSize: 14, color: p.textFaint, fontWeight: FontWeight.w600),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${s.total} tasks · ${s.done} done',
                                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.text),
                                    ),
                                    const SizedBox(height: 7),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0, end: s.percent),
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, v, _) => LinearProgressIndicator(
                                          value: v,
                                          minHeight: 6,
                                          backgroundColor: p.surfaceAlt,
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${Fmt.duration(s.plannedMin)} planned',
                                      style: TextStyle(fontSize: 12, color: p.textMuted, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(width: 10),
                        if (s.total > 0)
                          Text(
                            '${s.percentInt}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: s.done == s.total ? AppColors.success : p.text,
                            ),
                          ),
                        Icon(Icons.chevron_right_rounded, color: p.textFaint),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}
