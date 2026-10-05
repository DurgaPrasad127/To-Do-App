import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/models/task.dart';
import 'package:timeblock/services/storage_service.dart';

class DayStats {
  final int total;
  final int done;
  final int plannedMin;
  final int doneMin;
  const DayStats(this.total, this.done, this.plannedMin, this.doneMin);

  static const empty = DayStats(0, 0, 0, 0);

  double get percent => total == 0 ? 0 : done / total;
  int get percentInt => (percent * 100).round();
}

class _Tpl {
  final String title;
  final String? desc;
  final int s;
  final int e;
  final String cat;
  final int pri;
  final int color;
  const _Tpl(this.title, this.desc, this.s, this.e, this.cat, this.pri, this.color);
}

const List<_Tpl> _kSamples = [
  _Tpl('Morning Workout', 'Mobility + 30 min run', 480, 540, 'Gym', 2, 4),
  _Tpl('College / Classes', 'Lectures and lab session', 600, 750, 'College', 1, 1),
  _Tpl('Lunch', null, 780, 825, 'Personal', 0, 3),
  _Tpl('DSA Practice', 'Two medium problems + review', 840, 960, 'Study', 2, 0),
  _Tpl('Gym', 'Push day', 1020, 1110, 'Gym', 1, 5),
  _Tpl('Project Work', 'Ship the next feature', 1140, 1260, 'Project', 2, 2),
  _Tpl('Reading', 'One research paper', 1260, 1305, 'Personal', 0, 7),
];

class TaskProvider extends ChangeNotifier {
  final Map<String, Task> _byId = {};
  Map<String, List<Task>>? _index;
  final Random _rng = Random();
  int _seq = 0;

  // ───────────────────────── loading ─────────────────────────

  Future<void> load() async {
    for (final m in StorageService.loadTaskMaps()) {
      try {
        final t = Task.fromMap(m);
        _byId[t.id] = t;
      } catch (_) {
        // ignore a corrupted record instead of crashing
      }
    }
    _index = null;
  }

  String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}-${_rng.nextInt(99999)}';

  // ───────────────────────── queries ─────────────────────────

  List<Task> get all => _byId.values.toList(growable: false);
  int get totalCount => _byId.length;
  Task? byId(String id) => _byId[id];
  bool get hasSamples => _byId.values.any((t) => t.isSample);

  int get totalCompleted {
    var n = 0;
    for (final t in _byId.values) {
      if (t.isCompleted) n++;
    }
    return n;
  }

  Map<String, List<Task>> get _dayIndex {
    final cached = _index;
    if (cached != null) return cached;
    final map = <String, List<Task>>{};
    for (final t in _byId.values) {
      (map[Fmt.key(t.date)] ??= <Task>[]).add(t);
    }
    for (final l in map.values) {
      l.sort(_byTime);
    }
    return _index = map;
  }

  static int _byTime(Task a, Task b) {
    final c = a.startMin.compareTo(b.startMin);
    if (c != 0) return c;
    final e = a.endMin.compareTo(b.endMin);
    return e != 0 ? e : a.createdAt.compareTo(b.createdAt);
  }

  /// Tasks of one day sorted by start time.
  List<Task> forDate(DateTime d) => _dayIndex[Fmt.key(d)] ?? const <Task>[];

  DayStats statsFor(DateTime d) {
    final list = forDate(d);
    if (list.isEmpty) return DayStats.empty;
    var done = 0, planned = 0, doneMin = 0;
    for (final t in list) {
      planned += t.durationMin;
      if (t.isCompleted) {
        done++;
        doneMin += t.durationMin;
      }
    }
    return DayStats(list.length, done, planned, doneMin);
  }

  DayStats rangeStats(DateTime start, int days) {
    var total = 0, done = 0, planned = 0, doneMin = 0;
    for (var i = 0; i < days; i++) {
      final s = statsFor(Fmt.addDays(start, i));
      total += s.total;
      done += s.done;
      planned += s.plannedMin;
      doneMin += s.doneMin;
    }
    return DayStats(total, done, planned, doneMin);
  }

  List<Task> rangeTasks(DateTime start, int days) {
    final out = <Task>[];
    for (var i = 0; i < days; i++) {
      out.addAll(forDate(Fmt.addDays(start, i)));
    }
    return out;
  }

  // ───────────────────────── mutations ─────────────────────────

  void _changed() {
    _index = null;
    notifyListeners();
  }

  Future<bool> _persist(Future<void> Function() op) async {
    try {
      await op();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> add(Task t) => addAll([t]);

  Future<bool> addAll(List<Task> tasks) {
    final maps = <Map<String, dynamic>>[];
    for (final t in tasks) {
      // guard against duplicate ids
      final fixed = _byId.containsKey(t.id) ? t.clone(id: newId()) : t;
      _byId[fixed.id] = fixed;
      maps.add(fixed.toMap());
    }
    _changed();
    return _persist(() => StorageService.saveTasks(maps));
  }

  Future<bool> update(Task t) {
    _byId[t.id] = t;
    _changed();
    return _persist(() => StorageService.saveTask(t.toMap()));
  }

  Future<bool> toggle(String id) {
    final t = _byId[id];
    if (t == null) return Future.value(false);
    t.isCompleted = !t.isCompleted;
    t.completedAt = t.isCompleted ? DateTime.now() : null;
    return update(t);
  }

  Future<Task?> delete(String id) async {
    final t = _byId.remove(id);
    if (t == null) return null;
    _changed();
    await _persist(() => StorageService.deleteTask(id));
    return t;
  }

  Future<Task?> duplicate(String id) async {
    final t = _byId[id];
    if (t == null) return null;
    final copy = Task(
      id: newId(),
      title: t.title,
      description: t.description,
      date: t.date,
      startMin: t.startMin,
      endMin: t.endMin,
      category: t.category,
      priority: t.priority,
      colorIndex: t.colorIndex,
    );
    await add(copy);
    return copy;
  }

  Future<bool> reschedule(
    String id, {
    required DateTime date,
    required int startMin,
    required int endMin,
  }) {
    final t = _byId[id];
    if (t == null) return Future.value(false);
    final nd = Fmt.day(date);
    final changed = !Fmt.same(nd, t.date) || startMin != t.startMin || endMin != t.endMin;
    if (changed) {
      t.originalDate ??= t.date; // remember where it came from
      t.rescheduleCount += 1;
    }
    t.date = nd;
    t.startMin = startMin;
    t.endMin = endMin;
    return update(t);
  }

  Future<int> clearCompleted() async {
    final ids = _byId.values.where((t) => t.isCompleted).map((t) => t.id).toList();
    for (final id in ids) {
      _byId.remove(id);
    }
    _changed();
    await _persist(() => StorageService.deleteTasks(ids));
    return ids.length;
  }

  Future<int> removeSamples() async {
    final ids = _byId.values.where((t) => t.isSample).map((t) => t.id).toList();
    for (final id in ids) {
      _byId.remove(id);
    }
    _changed();
    await _persist(() => StorageService.deleteTasks(ids));
    return ids.length;
  }

  Future<void> resetAll() async {
    _byId.clear();
    _changed();
    await _persist(() => StorageService.clearTasks());
  }

  String exportJson() {
    final data = {
      'app': 'TimeBlock',
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': _byId.values.map((t) => t.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // ───────────────────────── sample data ─────────────────────────

  Future<void> seedSamples(DateTime now) async {
    final today = Fmt.day(now);
    final nowMin = Fmt.minutesOf(now);
    final list = <Task>[];
    for (var d = -6; d <= 1; d++) {
      final date = Fmt.addDays(today, d);
      for (var j = 0; j < _kSamples.length; j++) {
        final tpl = _kSamples[j];
        if (d < 0 && (j + d.abs()) % 5 == 0) continue;
        if (d == 1 && j != 3 && j != 5) continue;
        bool done;
        if (d < 0) {
          done = ((j * 3 + d.abs() * 2) % 7) != 0;
        } else if (d == 0) {
          done = tpl.e <= nowMin && j % 4 != 3;
        } else {
          done = false;
        }
        list.add(Task(
          id: newId(),
          title: tpl.title,
          description: tpl.desc,
          date: date,
          startMin: tpl.s,
          endMin: tpl.e,
          category: tpl.cat,
          priority: tpl.pri,
          colorIndex: tpl.color,
          isCompleted: done,
          completedAt: done ? DateTime(date.year, date.month, date.day, tpl.e ~/ 60, tpl.e % 60) : null,
          isSample: true,
        ));
      }
    }
    await addAll(list);
  }
}
