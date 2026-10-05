import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/core/utils/ui_helpers.dart';
import 'package:timeblock/models/task.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/screens/tasks/task_details_screen.dart';
import 'package:timeblock/widgets/common.dart';
import 'package:timeblock/widgets/task_editor_sheet.dart';

void openTaskDetails(BuildContext context, Task task, String heroTag) {
  Navigator.of(context).push(appRoute(TaskDetailsScreen(taskId: task.id, heroTag: heroTag)));
}

Future<void> toggleTask(BuildContext context, Task task) async {
  final tp = context.read<TaskProvider>();
  final wasDone = task.isCompleted;
  HapticFeedback.mediumImpact();
  final ok = await tp.toggle(task.id);
  if (!ok) {
    AppToast.error("Couldn't save that change. Please try again.");
    return;
  }
  if (!wasDone) {
    final s = tp.statsFor(task.date);
    if (s.total > 1 && s.done == s.total) {
      AppToast.show('Every task done for the day! 🎉',
          icon: Icons.emoji_events_rounded, iconColor: AppColors.warning);
    } else {
      AppToast.show('Nice work, task completed ✨');
    }
  }
}

Future<bool> deleteTaskFlow(BuildContext context, Task task) async {
  final ok = await confirmDialog(
    context,
    title: 'Delete task?',
    message: '"${task.title}" will be removed from your plan and history.',
  );
  if (!ok || !context.mounted) return false;
  final tp = context.read<TaskProvider>();
  final removed = await tp.delete(task.id);
  if (removed != null) {
    HapticFeedback.mediumImpact();
    AppToast.show(
      'Task deleted',
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.danger,
      actionLabel: 'Undo',
      onAction: () => tp.add(removed),
    );
  }
  return removed != null;
}

Future<void> duplicateTask(BuildContext context, Task task) async {
  final tp = context.read<TaskProvider>();
  final copy = await tp.duplicate(task.id);
  if (copy != null) {
    AppToast.show('Task duplicated', icon: Icons.copy_rounded, iconColor: AppColors.secondary);
  }
}

Future<void> showTaskActions(BuildContext context, Task task) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final p = ctx.pal;
      void run(VoidCallback fn) {
        Navigator.pop(ctx);
        fn();
      }

      return SheetSurface(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
              ),
              const SizedBox(height: 2),
              Text(
                '${Fmt.dateShort(task.date)} · ${Fmt.range(task.startMin, task.endMin)}',
                style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _ActionRow(
                icon: Icons.edit_rounded,
                label: 'Edit',
                color: AppColors.primary,
                onTap: () => run(() => showTaskEditor(context, editing: task)),
              ),
              _ActionRow(
                icon: task.isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
                label: task.isCompleted ? 'Mark as not done' : 'Mark as complete',
                color: AppColors.success,
                onTap: () => run(() => toggleTask(context, task)),
              ),
              _ActionRow(
                icon: Icons.copy_rounded,
                label: 'Duplicate',
                color: AppColors.secondary,
                onTap: () => run(() => duplicateTask(context, task)),
              ),
              _ActionRow(
                icon: Icons.update_rounded,
                label: 'Reschedule',
                color: AppColors.warning,
                onTap: () => run(() => showRescheduleSheet(context, task)),
              ),
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: AppColors.danger,
                onTap: () => run(() => deleteTaskFlow(context, task)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.98,
        child: Container(
          height: 56,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.o(0.14), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text)),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── reschedule ─────────────────────────

Future<void> showRescheduleSheet(BuildContext context, Task task) async {
  final msg = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RescheduleSheet(task: task),
  );
  if (msg != null) {
    AppToast.show(msg, icon: Icons.update_rounded, iconColor: AppColors.secondary);
  }
}

class _RescheduleSheet extends StatefulWidget {
  final Task task;
  const _RescheduleSheet({required this.task});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late DateTime _date = widget.task.date;
  late int _start = widget.task.startMin;
  late int _end = widget.task.endMin;

  DateTime get _today => Fmt.day(DateTime.now());

  void _setDate(DateTime d) => setState(() => _date = Fmt.day(d));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) _setDate(d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _start ~/ 60, minute: _start % 60),
    );
    if (t == null) return;
    final dur = widget.task.durationMin;
    var s = t.hour * 60 + t.minute;
    if (s + dur > 1439) s = 1439 - dur;
    setState(() {
      _start = s;
      _end = s + dur;
    });
  }

  Future<void> _confirm() async {
    final nav = Navigator.of(context);
    final tp = context.read<TaskProvider>();
    await tp.reschedule(widget.task.id, date: _date, startMin: _start, endMin: _end);
    nav.pop('Moved to ${Fmt.relativeDay(_date, _today)}, ${Fmt.time(_start)}');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final task = widget.task;
    final color = AppColors.taskColor(task.colorIndex).color;
    final tomorrow = Fmt.addDays(_today, 1);
    final nextWeek = Fmt.addDays(_today, 7);

    return SheetSurface(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reschedule',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: p.text, letterSpacing: -0.5)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 44,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ORIGINAL',
                            style: TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: p.textFaint)),
                        const SizedBox(height: 2),
                        Text(task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
                        Text(
                          '${Fmt.dateShort(task.date)} · ${Fmt.range(task.startMin, task.endMin)}',
                          style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!Fmt.same(task.date, _today))
                  AppChip(
                    label: 'Today',
                    icon: Icons.today_rounded,
                    selected: Fmt.same(_date, _today),
                    onTap: () => _setDate(_today),
                  ),
                AppChip(
                  label: 'Tomorrow',
                  icon: Icons.wb_sunny_rounded,
                  selected: Fmt.same(_date, tomorrow),
                  onTap: () => _setDate(tomorrow),
                ),
                AppChip(
                  label: 'Next week',
                  icon: Icons.next_week_rounded,
                  selected: Fmt.same(_date, nextWeek),
                  onTap: () => _setDate(nextWeek),
                ),
                AppChip(label: 'Pick date', icon: Icons.calendar_month_rounded, onTap: _pickDate),
                AppChip(label: 'Pick time', icon: Icons.schedule_rounded, onTap: _pickTime),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.o(0.22), color.o(0.08)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEW SLOT',
                      style: TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: p.textFaint)),
                  const SizedBox(height: 4),
                  Text(
                    '${Fmt.dateLong(_date)}\n${Fmt.range(_start, _end)}',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(label: 'Move task', icon: Icons.update_rounded, onPressed: _confirm),
          ],
        ),
      ),
    );
  }
}
