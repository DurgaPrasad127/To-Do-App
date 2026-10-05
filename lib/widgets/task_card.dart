import 'package:flutter/material.dart';
import 'package:timeblock/core/constants/task_options.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/models/task.dart';
import 'package:timeblock/widgets/animated_check.dart';
import 'package:timeblock/widgets/common.dart';
import 'package:timeblock/widgets/task_actions.dart';

/// Subtle breathing glow around the task that is happening right now.
class PulseGlow extends StatefulWidget {
  final bool active;
  final Color color;
  final double radius;
  final Widget child;
  const PulseGlow({
    super.key,
    required this.active,
    required this.color,
    required this.radius,
    required this.child,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseGlow old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: widget.color.o(0.18 + 0.20 * t),
                blurRadius: 10 + 14 * t,
                spreadRadius: 0.5 + 1.5 * t,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final DateTime now;
  final String heroScope;
  final bool showDate;
  final bool overlapping;
  final bool swipeable;
  final bool showOverdueActions;

  const TaskCard({
    super.key,
    required this.task,
    required this.now,
    required this.heroScope,
    this.showDate = false,
    this.overlapping = false,
    this.swipeable = true,
    this.showOverdueActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = AppColors.taskColor(task.colorIndex).color;
    final cat = categoryInfo(task.category);
    final pri = priorityInfo(task.priority);
    final done = task.isCompleted;
    final overdue = task.isOverdue(now);
    final active = task.isActive(now);
    final heroTag = 'task-$heroScope-${task.id}';
    final today = Fmt.day(now);

    final timeText =
        '${showDate ? '${Fmt.relativeDay(task.date, today)} · ' : ''}${Fmt.range(task.startMin, task.endMin)}';

    final badge = Hero(
      tag: heroTag,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: AppColors.gradientFor(color),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: color.o(0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(cat.icon, color: Colors.white, size: 24),
      ),
    );

    final titleStyle = TextStyle(
      fontSize: 16.5,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: done ? p.textMuted : p.text,
      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: p.textMuted,
      decorationThickness: 2,
    );

    final chips = <Widget>[
      if (active) MiniChip(icon: Icons.bolt_rounded, label: 'Now', color: color, strong: true),
      if (overdue)
        const MiniChip(
          icon: Icons.warning_amber_rounded,
          label: 'Overdue',
          color: AppColors.warning,
          strong: true,
        ),
      if (overlapping)
        const MiniChip(icon: Icons.layers_rounded, label: 'Overlaps', color: AppColors.warning),
      MiniChip(icon: cat.icon, label: task.category, color: color),
      MiniChip(icon: pri.icon, label: '${pri.name} priority', color: pri.color),
      if (task.rescheduleCount > 0)
        const MiniChip(icon: Icons.update_rounded, label: 'Rescheduled', color: AppColors.secondary),
      if (task.isRecurring)
        MiniChip(icon: Icons.repeat_rounded, label: task.recurrence, color: AppColors.primary),
    ];

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          badge,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AnimatedDefaultTextStyle(
                    style: titleStyle,
                    duration: const Duration(milliseconds: 250),
                    child: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: p.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$timeText · ${Fmt.duration(task.durationMin)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: p.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: chips),
                if (overdue && showOverdueActions) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionPill(
                        label: 'Complete',
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        onTap: () => toggleTask(context, task),
                      ),
                      _ActionPill(
                        label: 'Reschedule',
                        icon: Icons.update_rounded,
                        color: AppColors.secondary,
                        onTap: () => showRescheduleSheet(context, task),
                      ),
                      _ActionPill(
                        label: 'Delete',
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        onTap: () => deleteTaskFlow(context, task),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          AnimatedCheck(
            checked: done,
            color: color,
            label: done ? 'Mark ${task.title} as not done' : 'Mark ${task.title} as done',
            onTap: () => toggleTask(context, task),
          ),
        ],
      ),
    );

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.o(p.dark ? 0.16 : 0.09), p.surface),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: overdue
              ? AppColors.warning.o(0.8)
              : (active ? color.o(0.85) : p.border.o(0.55)),
          width: (overdue || active) ? 1.6 : 1,
        ),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: body,
    );

    card = PulseGlow(active: active, color: color, radius: 22, child: card);
    card = AnimatedScale(
      scale: done ? 0.985 : 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: done ? 0.66 : 1,
        duration: const Duration(milliseconds: 260),
        child: card,
      ),
    );
    card = Pressable(
      scale: 0.985,
      onTap: () => openTaskDetails(context, task, heroTag),
      onLongPress: () => showTaskActions(context, task),
      child: card,
    );
    card = Semantics(
      label: '${task.title}, $timeText, ${task.category}, ${pri.name} priority, '
          '${done ? 'completed' : (overdue ? 'overdue' : 'not completed')}',
      child: card,
    );

    if (!swipeable) return card;

    return Dismissible(
      key: ValueKey('dismiss-$heroScope-${task.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeBg(
        color: AppColors.success,
        icon: done ? Icons.undo_rounded : Icons.check_rounded,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBg(
        color: AppColors.danger,
        icon: Icons.delete_outline_rounded,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await toggleTask(context, task);
        } else {
          await deleteTaskFlow(context, task);
        }
        return false; // the list rebuilds itself from the provider
      },
      child: card,
    );
  }

  Widget _swipeBg({required Color color, required IconData icon, required Alignment alignment}) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.94,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.o(0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
