import 'package:timeblock/core/utils/formatters.dart';

/// A single time-blocked task. Times are minutes since midnight so there is no
/// string comparison anywhere. Every task has a unique [id].
class Task {
  final String id;
  String title;
  String? description;
  DateTime date; // local midnight of the day the task belongs to
  int startMin;
  int endMin;
  String category;
  int priority; // 0 low, 1 medium, 2 high
  int colorIndex;
  bool isCompleted;
  final DateTime createdAt;
  DateTime? completedAt;
  String recurrence; // None | Daily | Weekdays | Weekly
  String? seriesId; // shared by tasks generated from one repeat rule
  DateTime? originalDate; // set once a task has been rescheduled
  int rescheduleCount;
  bool isSample;

  Task({
    required this.id,
    required this.title,
    this.description,
    required DateTime date,
    required this.startMin,
    required this.endMin,
    this.category = 'Other',
    this.priority = 1,
    this.colorIndex = 0,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.recurrence = 'None',
    this.seriesId,
    DateTime? originalDate,
    this.rescheduleCount = 0,
    this.isSample = false,
  })  : date = Fmt.day(date),
        createdAt = createdAt ?? DateTime.now(),
        originalDate = originalDate == null ? null : Fmt.day(originalDate);

  int get durationMin => endMin - startMin;
  bool get isRecurring => recurrence != 'None';

  DateTime get startAt => DateTime(date.year, date.month, date.day, startMin ~/ 60, startMin % 60);
  DateTime get endAt => DateTime(date.year, date.month, date.day, endMin ~/ 60, endMin % 60);

  bool isOverdue(DateTime now) => !isCompleted && endAt.isBefore(now);
  bool isActive(DateTime now) => !isCompleted && !now.isBefore(startAt) && now.isBefore(endAt);
  bool isUpcoming(DateTime now) => !isCompleted && startAt.isAfter(now);

  Task clone({String? id}) => Task(
        id: id ?? this.id,
        title: title,
        description: description,
        date: date,
        startMin: startMin,
        endMin: endMin,
        category: category,
        priority: priority,
        colorIndex: colorIndex,
        isCompleted: isCompleted,
        createdAt: createdAt,
        completedAt: completedAt,
        recurrence: recurrence,
        seriesId: seriesId,
        originalDate: originalDate,
        rescheduleCount: rescheduleCount,
        isSample: isSample,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.millisecondsSinceEpoch,
        'startMin': startMin,
        'endMin': endMin,
        'category': category,
        'priority': priority,
        'colorIndex': colorIndex,
        'isCompleted': isCompleted,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'recurrence': recurrence,
        'seriesId': seriesId,
        'originalDate': originalDate?.millisecondsSinceEpoch,
        'rescheduleCount': rescheduleCount,
        'isSample': isSample,
      };

  factory Task.fromMap(Map<String, dynamic> m) {
    DateTime? d(dynamic v) => v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
    final start = (m['startMin'] as int?) ?? 540;
    var end = (m['endMin'] as int?) ?? start + 60;
    if (end <= start) end = start + 30 > 1439 ? 1439 : start + 30;
    return Task(
      id: m['id'] as String,
      title: (m['title'] as String?) ?? 'Untitled',
      description: m['description'] as String?,
      date: d(m['date']) ?? DateTime.now(),
      startMin: start,
      endMin: end,
      category: (m['category'] as String?) ?? 'Other',
      priority: (m['priority'] as int?) ?? 1,
      colorIndex: (m['colorIndex'] as int?) ?? 0,
      isCompleted: (m['isCompleted'] as bool?) ?? false,
      createdAt: d(m['createdAt']),
      completedAt: d(m['completedAt']),
      recurrence: (m['recurrence'] as String?) ?? 'None',
      seriesId: m['seriesId'] as String?,
      originalDate: d(m['originalDate']),
      rescheduleCount: (m['rescheduleCount'] as int?) ?? 0,
      isSample: (m['isSample'] as bool?) ?? false,
    );
  }
}
