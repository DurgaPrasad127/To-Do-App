import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/widgets/calendar.dart';
import 'package:timeblock/widgets/common.dart';
import 'package:timeblock/widgets/task_editor_sheet.dart';
import 'package:timeblock/widgets/timeline.dart';

/// Full timeline for any single date (history, week view, future days).
class DayScreen extends StatelessWidget {
  final DateTime date;
  const DayScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tp = context.watch<TaskProvider>();
    final d = Fmt.day(date);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: MinuteBuilder(
            builder: (context, now) {
              final tasks = tp.forDate(d);
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Semantics(
                            button: true,
                            label: 'Back',
                            child: Pressable(
                              onTap: () => Navigator.of(context).pop(),
                              scale: 0.9,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: p.surface.o(0.9),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: p.border.o(0.6)),
                                ),
                                child: Icon(Icons.arrow_back_rounded, color: p.text),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Day timeline',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.text),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Add task to this day',
                            child: Pressable(
                              onTap: () => showTaskEditor(context, initialDate: d),
                              scale: 0.9,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_rounded, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: DaySummaryCard(date: d),
                    ),
                  ),
                  if (tasks.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'No tasks planned for this day.',
                        subtitle: 'Add a task to start time blocking.',
                        actionLabel: 'Add task',
                        onAction: () => showTaskEditor(context, initialDate: d),
                      ),
                    )
                  else
                    SliverTaskTimeline(tasks: tasks, date: d, now: now, heroScope: 'day'),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
