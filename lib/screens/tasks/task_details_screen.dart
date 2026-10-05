import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/constants/task_options.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/models/task.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/widgets/common.dart';
import 'package:timeblock/widgets/task_actions.dart';
import 'package:timeblock/widgets/task_editor_sheet.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String taskId;
  final String heroTag;
  const TaskDetailsScreen({super.key, required this.taskId, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final task = context.watch<TaskProvider>().byId(taskId);

    if (task == null) {
      // The task was deleted while this screen was open.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const AppBackground(child: Scaffold(backgroundColor: Colors.transparent));
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: MinuteBuilder(
          builder: (context, now) {
            final color = AppColors.taskColor(task.colorIndex).color;
            final cat = categoryInfo(task.category);
            final pri = priorityInfo(task.priority);
            final overdue = task.isOverdue(now);
            final active = task.isActive(now);

            String status;
            IconData statusIcon;
            if (task.isCompleted) {
              status = 'Completed';
              statusIcon = Icons.check_circle_rounded;
            } else if (overdue) {
              status = 'Overdue';
              statusIcon = Icons.warning_amber_rounded;
            } else if (active) {
              status = 'In progress';
              statusIcon = Icons.bolt_rounded;
            } else {
              status = 'Upcoming';
              statusIcon = Icons.hourglass_bottom_rounded;
            }

            return SafeArea(
              bottom: false,
              child: CustomScrollView(
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
                          Text('Task details',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.text)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientFor(color),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: color.o(0.4), blurRadius: 28, offset: const Offset(0, 14))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Hero(
                                  tag: heroTag,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white.o(0.25),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(cat.icon, color: Colors.white, size: 30),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.o(0.22),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, size: 16, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        status,
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 30,
                                height: 1.12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${Fmt.dateLong(task.date)} · ${Fmt.range(task.startMin, task.endMin)}',
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white.o(0.9)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        child: Column(
                          children: [
                            _InfoRow(icon: Icons.event_rounded, label: 'Date', value: Fmt.dateLong(task.date)),
                            _InfoRow(
                              icon: Icons.schedule_rounded,
                              label: 'Time block',
                              value: Fmt.range(task.startMin, task.endMin),
                            ),
                            _InfoRow(
                              icon: Icons.timelapse_rounded,
                              label: 'Duration',
                              value: Fmt.duration(task.durationMin),
                            ),
                            _InfoRow(icon: cat.icon, label: 'Category', value: task.category),
                            _InfoRow(
                              icon: pri.icon,
                              iconColor: pri.color,
                              label: 'Priority',
                              value: pri.name,
                            ),
                            if (task.isRecurring)
                              _InfoRow(icon: Icons.repeat_rounded, label: 'Repeats', value: task.recurrence),
                            if (task.originalDate != null)
                              _InfoRow(
                                icon: Icons.update_rounded,
                                label: 'Rescheduled from',
                                value:
                                    '${Fmt.dateShort(task.originalDate!)}${task.rescheduleCount > 1 ? ' (${task.rescheduleCount} times)' : ''}',
                              ),
                            _InfoRow(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Created',
                              value: Fmt.stamp(task.createdAt),
                            ),
                            if (task.completedAt != null)
                              _InfoRow(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Completed',
                                value: Fmt.stamp(task.completedAt!),
                                last: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DESCRIPTION',
                                style: TextStyle(
                                    fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: p.textFaint),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                task.description!,
                                style: TextStyle(fontSize: 15.5, height: 1.5, color: p.text),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: task.isCompleted
                          ? _OutlineAction(
                              icon: Icons.undo_rounded,
                              label: 'Mark as not done',
                              color: p.textMuted,
                              onTap: () => toggleTask(context, task),
                              wide: true,
                            )
                          : PrimaryButton(
                              label: 'Mark as completed',
                              icon: Icons.check_rounded,
                              gradient: AppColors.successGradient,
                              shadowColor: AppColors.success,
                              onPressed: () => toggleTask(context, task),
                            ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _OutlineAction(
                              icon: Icons.edit_rounded,
                              label: 'Edit',
                              color: AppColors.primary,
                              onTap: () => showTaskEditor(context, editing: task),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OutlineAction(
                              icon: Icons.update_rounded,
                              label: 'Reschedule',
                              color: AppColors.secondary,
                              onTap: () => showRescheduleSheet(context, task),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OutlineAction(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete',
                              color: AppColors.danger,
                              onTap: () async {
                                final nav = Navigator.of(context);
                                final deleted = await deleteTaskFlow(context, task);
                                if (deleted && nav.canPop()) nav.pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final bool last;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.border.o(0.5))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool wide;
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.96,
        child: Container(
          height: wide ? 56 : 78,
          decoration: BoxDecoration(
            color: color.o(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.o(0.35)),
          ),
          child: wide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 8),
                    Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.text)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
