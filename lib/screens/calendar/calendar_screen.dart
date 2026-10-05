import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/core/utils/ui_helpers.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/screens/calendar/day_screen.dart';
import 'package:timeblock/widgets/calendar.dart';
import 'package:timeblock/widgets/common.dart';
import 'package:timeblock/widgets/task_card.dart';
import 'package:timeblock/widgets/task_editor_sheet.dart';

class CalendarScreen extends StatefulWidget {
  final ValueNotifier<DateTime> selected;
  const CalendarScreen({super.key, required this.selected});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _mode = 0; // 0 month, 1 week
  DateTime _weekStart = Fmt.weekStart(DateTime.now());

  void _openDay(DateTime d) {
    Navigator.of(context).push(appRoute(DayScreen(date: d)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tp = context.watch<TaskProvider>();

    return MinuteBuilder(
      builder: (context, now) {
        return SafeArea(
          bottom: false,
          child: ValueListenableBuilder<DateTime>(
            valueListenable: widget.selected,
            builder: (context, selected, _) {
              final dayTasks = tp.forDate(selected);
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ScreenTitle(title: 'Calendar', subtitle: 'Your plans and your history'),
                          const SizedBox(height: 16),
                          SegmentedPill(
                            options: const ['Month', 'Week'],
                            index: _mode,
                            onChanged: (i) => setState(() => _mode = i),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (_mode == 0) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CalendarWidget(
                          selected: selected,
                          onSelect: (d) => widget.selected.value = Fmt.day(d),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: DaySummaryCard(date: selected),
                      ),
                    ),
                    if (dayTasks.isEmpty)
                      SliverToBoxAdapter(
                        child: EmptyState(
                          icon: Icons.event_available_rounded,
                          title: 'No tasks planned',
                          subtitle: 'Nothing is scheduled for ${Fmt.dateShort(selected)}.',
                          actionLabel: 'Plan this day',
                          onAction: () => showTaskEditor(context, initialDate: selected),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                          child: SectionHeader(
                            title: 'Tasks',
                            trailing: Semantics(
                              button: true,
                              label: 'Open day timeline',
                              child: Pressable(
                                onTap: () => _openDay(selected),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Timeline',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final t = dayTasks[i];
                              return Appear(
                                key: ValueKey('cal-${t.id}'),
                                index: i,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TaskCard(task: t, now: now, heroScope: 'cal'),
                                ),
                              );
                            },
                            childCount: dayTasks.length,
                          ),
                        ),
                      ),
                    ],
                  ] else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: WeekOverview(
                          weekStart: _weekStart,
                          onPrev: () => setState(() => _weekStart = Fmt.addDays(_weekStart, -7)),
                          onNext: () => setState(() => _weekStart = Fmt.addDays(_weekStart, 7)),
                          onOpenDay: _openDay,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
