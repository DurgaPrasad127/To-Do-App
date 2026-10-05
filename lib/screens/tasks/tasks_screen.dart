import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/constants/task_options.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/models/task.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/widgets/common.dart';
import 'package:timeblock/widgets/task_card.dart';
import 'package:timeblock/widgets/task_editor_sheet.dart';

enum _Filter { all, today, upcoming, completed, overdue }

enum _Sort { time, priority, date, category }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.date;

  static const _filterLabels = {
    _Filter.all: 'All',
    _Filter.today: 'Today',
    _Filter.upcoming: 'Upcoming',
    _Filter.completed: 'Completed',
    _Filter.overdue: 'Overdue',
  };

  static const _sortLabels = {
    _Sort.time: 'Time',
    _Sort.priority: 'Priority',
    _Sort.date: 'Date',
    _Sort.category: 'Category',
  };

  static const _sortIcons = {
    _Sort.time: Icons.schedule_rounded,
    _Sort.priority: Icons.flag_rounded,
    _Sort.date: Icons.event_rounded,
    _Sort.category: Icons.category_rounded,
  };

  bool _matches(_Filter f, Task t, DateTime now) {
    switch (f) {
      case _Filter.all:
        return true;
      case _Filter.today:
        return Fmt.same(t.date, now);
      case _Filter.upcoming:
        return t.isUpcoming(now);
      case _Filter.completed:
        return t.isCompleted;
      case _Filter.overdue:
        return t.isOverdue(now);
    }
  }

  /// Flattened list of section headers (String) and tasks (Task).
  List<Object> _build(List<Task> source, DateTime now) {
    final list = source.where((t) => _matches(_filter, t, now)).toList();
    int byDateTime(Task a, Task b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.startMin.compareTo(b.startMin);
    }

    final out = <Object>[];
    switch (_sort) {
      case _Sort.time:
        list.sort((a, b) {
          final c = a.startMin.compareTo(b.startMin);
          return c != 0 ? c : a.date.compareTo(b.date);
        });
        out.addAll(list);
        break;
      case _Sort.date:
        if (_filter == _Filter.completed) {
          list.sort((a, b) => byDateTime(b, a));
        } else {
          list.sort(byDateTime);
        }
        DateTime? last;
        for (final t in list) {
          if (last == null || !Fmt.same(last, t.date)) {
            out.add('${Fmt.relativeDay(t.date, Fmt.day(now))} · ${Fmt.dateLong(t.date)}');
            last = t.date;
          }
          out.add(t);
        }
        break;
      case _Sort.priority:
        for (var pr = 2; pr >= 0; pr--) {
          final group = list.where((t) => t.priority == pr).toList()..sort(byDateTime);
          if (group.isEmpty) continue;
          out.add('${priorityInfo(pr).name} priority');
          out.addAll(group);
        }
        break;
      case _Sort.category:
        for (final c in kCategories) {
          final group = list.where((t) => categoryInfo(t.category).name == c.name).toList()..sort(byDateTime);
          if (group.isEmpty) continue;
          out.add(c.name);
          out.addAll(group);
        }
        break;
    }
    return out;
  }

  ({String title, String subtitle, IconData icon}) _empty() {
    switch (_filter) {
      case _Filter.completed:
        return (title: 'Nothing completed yet.', subtitle: 'Finish a task and it will show up here.', icon: Icons.emoji_events_rounded);
      case _Filter.overdue:
        return (title: 'You are all caught up', subtitle: 'No overdue tasks. Nice.', icon: Icons.verified_rounded);
      case _Filter.upcoming:
        return (title: 'Nothing coming up', subtitle: 'Plan something for later.', icon: Icons.upcoming_rounded);
      case _Filter.today:
        return (title: 'Your day is clear ✨', subtitle: 'Add a task and start planning.', icon: Icons.auto_awesome_rounded);
      case _Filter.all:
        return (title: 'No tasks yet', subtitle: 'Tap + to add your first time block.', icon: Icons.checklist_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tp = context.watch<TaskProvider>();

    return MinuteBuilder(
      builder: (context, now) {
        final all = tp.all;
        final counts = <_Filter, int>{
          for (final f in _Filter.values) f: all.where((t) => _matches(f, t, now)).length,
        };
        final items = _build(all, now);
        final empty = _empty();

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: ScreenTitle(
                    title: 'Tasks',
                    subtitle: '${counts[_Filter.all]} total · ${counts[_Filter.completed]} completed',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    itemCount: _Filter.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f = _Filter.values[i];
                      final n = counts[f] ?? 0;
                      return AppChip(
                        label: '${_filterLabels[f]}${n > 0 ? '  $n' : ''}',
                        selected: _filter == f,
                        color: f == _Filter.overdue ? AppColors.warning : AppColors.primary,
                        onTap: () => setState(() => _filter = f),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    itemCount: _Sort.values.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Center(
                          child: Text(
                            'SORT',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: p.textFaint,
                            ),
                          ),
                        );
                      }
                      final s = _Sort.values[i - 1];
                      return AppChip(
                        label: _sortLabels[s]!,
                        icon: _sortIcons[s],
                        selected: _sort == s,
                        color: AppColors.secondary,
                        onTap: () => setState(() => _sort = s),
                      );
                    },
                  ),
                ),
              ),
              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: empty.icon,
                    title: empty.title,
                    subtitle: empty.subtitle,
                    actionLabel: (_filter == _Filter.all || _filter == _Filter.today) ? 'Add task' : null,
                    onAction: () => showTaskEditor(context),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final item = items[i];
                        if (item is String) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 12),
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: p.textMuted,
                              ),
                            ),
                          );
                        }
                        final t = item as Task;
                        return Padding(
                          key: ValueKey('tasks-${t.id}'),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TaskCard(task: t, now: now, heroScope: 'tasks', showDate: _sort != _Sort.date),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        );
      },
    );
  }
}
