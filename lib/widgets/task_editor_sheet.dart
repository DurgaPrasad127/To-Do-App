import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/constants/task_options.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/core/utils/ui_helpers.dart';
import 'package:timeblock/models/task.dart';
import 'package:timeblock/providers/settings_provider.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/widgets/common.dart';

/// Opens the add / edit task sheet. Shows a toast with the result.
Future<void> showTaskEditor(
  BuildContext context, {
  Task? editing,
  DateTime? initialDate,
}) async {
  final msg = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskEditorSheet(editing: editing, initialDate: initialDate),
  );
  if (msg != null) AppToast.show(msg);
}

class TaskEditorSheet extends StatefulWidget {
  final Task? editing;
  final DateTime? initialDate;
  const TaskEditorSheet({super.key, this.editing, this.initialDate});

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();

  late DateTime _date;
  late int _start;
  late int _end;
  String _category = 'Study';
  int _priority = 1;
  int _color = 0;
  bool _colorTouched = false;
  String _repeat = 'None';
  bool _more = false;
  bool _saving = false;
  String? _titleError;
  String? _timeError;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _title.text = e.title;
      _desc.text = e.description ?? '';
      _date = e.date;
      _start = e.startMin;
      _end = e.endMin;
      _category = e.category;
      _priority = e.priority;
      _color = e.colorIndex;
      _colorTouched = true;
      _more = true;
    } else {
      final now = DateTime.now();
      _date = Fmt.day(widget.initialDate ?? now);
      final dayStart = context.read<SettingsProvider>().dayStartMin;
      var s = Fmt.same(_date, now) ? (now.hour + 1) * 60 : dayStart;
      s = math.min(s, 22 * 60);
      _start = s;
      _end = s + 60;
      _color = categoryInfo(_category).colorIndex;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  // ───────────── pickers ─────────────

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = Fmt.day(d));
  }

  Future<void> _pickStart() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _start ~/ 60, minute: _start % 60),
    );
    if (t == null) return;
    setState(() {
      final dur = _end - _start > 0 ? _end - _start : 60;
      _start = t.hour * 60 + t.minute;
      _end = math.min(_start + dur, 1439);
      _timeError = _end <= _start ? 'End time must be later than start time.' : null;
    });
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _end ~/ 60, minute: _end % 60),
    );
    if (t == null) return;
    setState(() {
      _end = t.hour * 60 + t.minute;
      _timeError = _end <= _start ? 'End time must be later than start time.' : null;
    });
  }

  void _setDuration(int minutes) {
    setState(() {
      _end = math.min(_start + minutes, 1439);
      _timeError = _end <= _start ? 'End time must be later than start time.' : null;
    });
  }

  Task? _conflict() {
    final tp = context.read<TaskProvider>();
    for (final t in tp.forDate(_date)) {
      if (t.id == widget.editing?.id) continue;
      if (_start < t.endMin && t.startMin < _end) return t;
    }
    return null;
  }

  // ───────────── save ─────────────

  List<DateTime> _repeatDates() {
    final out = <DateTime>[];
    switch (_repeat) {
      case 'Daily':
        for (var i = 0; i < 30; i++) {
          out.add(Fmt.addDays(_date, i));
        }
        break;
      case 'Weekdays':
        for (var i = 0; i < 42; i++) {
          final d = Fmt.addDays(_date, i);
          if (d.weekday <= 5) out.add(d);
        }
        break;
      case 'Weekly':
        for (var i = 0; i < 12; i++) {
          out.add(Fmt.addDays(_date, i * 7));
        }
        break;
      default:
        out.add(_date);
    }
    return out;
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() => _titleError = 'Give your task a name');
      return;
    }
    if (_end <= _start) {
      HapticFeedback.heavyImpact();
      setState(() => _timeError = 'End time must be later than start time.');
      return;
    }
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final tp = context.read<TaskProvider>();
    final desc = _desc.text.trim();

    String message;
    bool ok;
    final e = widget.editing;
    if (e != null) {
      e.title = title;
      e.description = desc.isEmpty ? null : desc;
      e.date = Fmt.day(_date);
      e.startMin = _start;
      e.endMin = _end;
      e.category = _category;
      e.priority = _priority;
      e.colorIndex = _color;
      ok = await tp.update(e);
      message = 'Task updated';
    } else {
      final dates = _repeatDates();
      final seriesId = dates.length > 1 ? tp.newId() : null;
      final created = <Task>[
        for (final d in dates)
          Task(
            id: tp.newId(),
            title: title,
            description: desc.isEmpty ? null : desc,
            date: d,
            startMin: _start,
            endMin: _end,
            category: _category,
            priority: _priority,
            colorIndex: _color,
            recurrence: _repeat,
            seriesId: seriesId,
          ),
      ];
      ok = await tp.addAll(created);
      message = created.length > 1 ? 'Added ${created.length} repeating tasks' : 'Task added';
    }
    HapticFeedback.mediumImpact();
    if (!ok) {
      AppToast.error("Saved for now, but couldn't write to storage.");
    }
    nav.pop(ok ? message : null);
  }

  // ───────────── UI ─────────────

  String _dateLabel(DateTime today) {
    final rel = Fmt.relativeDay(_date, today);
    final prefix = (rel == 'Today' || rel == 'Tomorrow' || rel == 'Yesterday')
        ? rel
        : Fmt.weekdaysShort[_date.weekday - 1];
    return '$prefix · ${Fmt.dateShort(_date)}';
  }

  Widget _label(String text) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: p.textFaint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final today = Fmt.day(DateTime.now());
    final conflict = _conflict();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SheetSurface(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit task' : 'New task',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: p.text),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close',
                    child: Pressable(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: p.surfaceAlt, shape: BoxShape.circle),
                        child: Icon(Icons.close_rounded, color: p.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: p.text),
                decoration: inputDecoration(
                  context,
                  hint: 'What do you want to do?',
                  error: _titleError,
                ),
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
              ),
              _label('WHEN'),
              _PickTile(
                icon: Icons.calendar_month_rounded,
                label: 'Date',
                value: _dateLabel(today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PickTile(
                      icon: Icons.play_arrow_rounded,
                      label: 'Start',
                      value: Fmt.time(_start),
                      onTap: _pickStart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickTile(
                      icon: Icons.stop_rounded,
                      label: 'End',
                      value: Fmt.time(_end),
                      onTap: _pickEnd,
                      error: _timeError != null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in const [30, 60, 90, 120])
                    AppChip(
                      label: d == 30
                          ? '30 min'
                          : (d == 60 ? '1 hr' : (d == 90 ? '1.5 hr' : '2 hr')),
                      selected: _end - _start == d,
                      onTap: () => _setDuration(d),
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _timeError == null && conflict == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _timeError != null ? Icons.error_outline_rounded : Icons.layers_rounded,
                              size: 18,
                              color: _timeError != null ? AppColors.danger : AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _timeError ??
                                    'Overlaps with "${conflict!.title}" (${Fmt.range(conflict.startMin, conflict.endMin)}). You can still save.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                  color: _timeError != null ? AppColors.danger : p.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Semantics(
                button: true,
                label: _more ? 'Hide more options' : 'Show more options',
                child: Pressable(
                  onTap: () => setState(() => _more = !_more),
                  scale: 0.98,
                  child: Container(
                    height: 48,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'More options',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _more ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: Icon(Icons.keyboard_arrow_down_rounded, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _more ? _moreOptions(p) : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _isEdit ? 'Save changes' : 'Add task',
                icon: Icons.check_rounded,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreOptions(AppPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('DESCRIPTION'),
        TextField(
          controller: _desc,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: 15, color: p.text),
          decoration: inputDecoration(context, hint: 'Add notes (optional)'),
        ),
        _label('CATEGORY'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in kCategories)
              AppChip(
                label: c.name,
                icon: c.icon,
                selected: _category == c.name,
                color: AppColors.taskColor(c.colorIndex).color,
                onTap: () => setState(() {
                  _category = c.name;
                  if (!_colorTouched) _color = c.colorIndex;
                }),
              ),
          ],
        ),
        _label('PRIORITY'),
        Row(
          children: [
            for (var i = 0; i < kPriorities.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _PriorityTile(
                  info: kPriorities[i],
                  selected: _priority == i,
                  onTap: () => setState(() => _priority = i),
                ),
              ),
            ],
          ],
        ),
        _label('COLOR'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < AppColors.taskColors.length; i++)
              _ColorDot(
                info: AppColors.taskColors[i],
                selected: _color == i,
                onTap: () => setState(() {
                  _color = i;
                  _colorTouched = true;
                }),
              ),
          ],
        ),
        if (!_isEdit) ...[
          _label('REPEAT'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in kRepeats)
                AppChip(
                  label: r,
                  icon: r == 'None' ? Icons.block_rounded : Icons.repeat_rounded,
                  selected: _repeat == r,
                  onTap: () => setState(() => _repeat = r),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool error;
  const _PickTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      label: '$label, $value',
      child: Pressable(
        onTap: onTap,
        scale: 0.97,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(18),
            border: error ? Border.all(color: AppColors.danger, width: 1.4) : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: error ? AppColors.danger : AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: p.textFaint),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityTile extends StatelessWidget {
  final PriorityInfo info;
  final bool selected;
  final VoidCallback onTap;
  const _PriorityTile({required this.info, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      selected: selected,
      label: '${info.name} priority',
      child: Pressable(
        onTap: onTap,
        scale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 56,
          decoration: BoxDecoration(
            color: selected ? info.color.o(0.18) : p.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? info.color : Colors.transparent, width: 1.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(info.icon, size: 18, color: info.color),
              const SizedBox(width: 6),
              Text(
                info.name,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: p.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final TaskColor info;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({required this.info, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${info.name} color',
      child: Pressable(
        onTap: onTap,
        scale: 0.88,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? info.color : Colors.transparent, width: 2.4),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.gradientFor(info.color),
            ),
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
          ),
        ),
      ),
    );
  }
}
