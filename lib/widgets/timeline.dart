import 'package:flutter/material.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/models/task.dart';
import 'package:timeblock/widgets/common.dart';
import 'package:timeblock/widgets/task_card.dart';

class _Entry {
  final Task? task;
  final bool overlap;
  final bool showTime;
  const _Entry.task(Task t, this.overlap, this.showTime) : task = t;
  const _Entry.now()
      : task = null,
        overlap = false,
        showTime = false;
  bool get isNow => task == null;
}

/// Vertical time-block timeline as a sliver: time labels on the left, a rail
/// with colour dots, task cards, a live "now" marker and overlap detection.
class SliverTaskTimeline extends StatelessWidget {
  final List<Task> tasks; // must be sorted by start time
  final DateTime date;
  final DateTime now;
  final String heroScope;

  const SliverTaskTimeline({
    super.key,
    required this.tasks,
    required this.date,
    required this.now,
    required this.heroScope,
  });

  List<_Entry> _entries() {
    final n = tasks.length;
    final overlap = List<bool>.filled(n, false);
    var maxEnd = -1;
    var maxIdx = -1;
    for (var i = 0; i < n; i++) {
      final t = tasks[i];
      if (maxIdx >= 0 && t.startMin < maxEnd) {
        overlap[i] = true;
        overlap[maxIdx] = true;
      }
      if (t.endMin > maxEnd) {
        maxEnd = t.endMin;
        maxIdx = i;
      }
    }

    final isToday = Fmt.same(date, now);
    final nowMin = Fmt.minutesOf(now);
    final out = <_Entry>[];
    var markerPlaced = !isToday;
    for (var i = 0; i < n; i++) {
      final t = tasks[i];
      if (!markerPlaced && t.startMin > nowMin) {
        out.add(const _Entry.now());
        markerPlaced = true;
      }
      out.add(_Entry.task(t, overlap[i], i == 0 || tasks[i - 1].startMin != t.startMin));
    }
    if (!markerPlaced) out.add(const _Entry.now());
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final e = entries[i];
            final isLast = i == entries.length - 1;
            return Appear(
              key: ValueKey(e.isNow ? 'now-marker' : 'row-${e.task!.id}'),
              index: i,
              child: e.isNow ? _nowRow(context, isLast) : _taskRow(context, e, isLast),
            );
          },
          childCount: entries.length,
        ),
      ),
    );
  }

  Widget _taskRow(BuildContext context, _Entry e, bool isLast) {
    final p = context.pal;
    final t = e.task!;
    final color = AppColors.taskColor(t.colorIndex).color;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 80, bottom: 12),
          child: TaskCard(task: t, now: now, heroScope: heroScope, overlapping: e.overlap),
        ),
        if (!isLast)
          Positioned(
            left: 63,
            top: 30,
            bottom: 0,
            width: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        Positioned(
          left: 0,
          top: 16,
          width: 50,
          child: e.showTime
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Fmt.clock(t.startMin),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.text),
                    ),
                    Text(
                      Fmt.ampm(t.startMin),
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.textFaint),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        Positioned(
          left: 57,
          top: 20,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: t.isCompleted ? color : p.surface,
              shape: BoxShape.circle,
              border: Border.all(color: e.overlap ? AppColors.warning : color, width: 3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _nowRow(BuildContext context, bool isLast) {
    final p = context.pal;
    const red = AppColors.nowRed;
    return SizedBox(
      height: 38,
      child: Stack(
        children: [
          Positioned(
            left: 63,
            top: 0,
            bottom: isLast ? 26 : 0,
            width: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 50,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                Fmt.clock(Fmt.minutesOf(now)),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: red),
              ),
            ),
          ),
          Positioned(
            left: 57,
            top: 12,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: red,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: red.o(0.55), blurRadius: 10, spreadRadius: 1)],
              ),
            ),
          ),
          Positioned(
            left: 80,
            right: 0,
            top: 18,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: [red, red.o(0)]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
