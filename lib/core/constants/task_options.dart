import 'package:flutter/material.dart';
import 'package:timeblock/core/theme/app_colors.dart';

class CategoryInfo {
  final String name;
  final IconData icon;
  final int colorIndex;
  const CategoryInfo(this.name, this.icon, this.colorIndex);
}

const List<CategoryInfo> kCategories = [
  CategoryInfo('Study', Icons.menu_book_rounded, 0),
  CategoryInfo('Work', Icons.work_rounded, 1),
  CategoryInfo('Gym', Icons.fitness_center_rounded, 4),
  CategoryInfo('Personal', Icons.self_improvement_rounded, 3),
  CategoryInfo('College', Icons.school_rounded, 2),
  CategoryInfo('Project', Icons.rocket_launch_rounded, 5),
  CategoryInfo('Other', Icons.bubble_chart_rounded, 7),
];

CategoryInfo categoryInfo(String name) {
  for (final c in kCategories) {
    if (c.name == name) return c;
  }
  return kCategories.last;
}

class PriorityInfo {
  final String name;
  final IconData icon;
  final Color color;
  const PriorityInfo(this.name, this.icon, this.color);
}

const List<PriorityInfo> kPriorities = [
  PriorityInfo('Low', Icons.arrow_downward_rounded, AppColors.secondary),
  PriorityInfo('Medium', Icons.remove_rounded, AppColors.warning),
  PriorityInfo('High', Icons.priority_high_rounded, AppColors.danger),
];

PriorityInfo priorityInfo(int i) {
  final idx = i < 0 ? 0 : (i >= kPriorities.length ? kPriorities.length - 1 : i);
  return kPriorities[idx];
}

const List<String> kRepeats = ['None', 'Daily', 'Weekdays', 'Weekly'];
