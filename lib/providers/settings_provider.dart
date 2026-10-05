import 'package:flutter/material.dart';
import 'package:timeblock/services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  String name = '';
  String bio = '';
  int themeIndex = 0; // 0 system, 1 light, 2 dark (matches ThemeMode.values)
  bool onboarded = false;
  bool samplesSeeded = false;
  int dailyGoal = 5;
  int dayStartMin = 6 * 60;
  int dayEndMin = 22 * 60;
  int avatarColor = 0;

  ThemeMode get themeMode => ThemeMode.values[themeIndex];

  Future<void> load() async {
    try {
      name = StorageService.read<String>('name', '');
      bio = StorageService.read<String>('bio', '');
      themeIndex = StorageService.read<int>('themeIndex', 0);
      if (themeIndex < 0 || themeIndex > 2) themeIndex = 0;
      onboarded = StorageService.read<bool>('onboarded', false);
      samplesSeeded = StorageService.read<bool>('samplesSeeded', false);
      dailyGoal = StorageService.read<int>('dailyGoal', 5);
      dayStartMin = StorageService.read<int>('dayStartMin', 6 * 60);
      dayEndMin = StorageService.read<int>('dayEndMin', 22 * 60);
      avatarColor = StorageService.read<int>('avatarColor', 0);
    } catch (_) {
      // fall back to defaults
    }
  }

  Future<void> _put(String key, dynamic value) async {
    try {
      await StorageService.write(key, value);
    } catch (_) {
      // settings are non-critical; keep running
    }
  }

  void setProfile({required String newName, required String newBio, required int newAvatar}) {
    name = newName.trim();
    bio = newBio.trim();
    avatarColor = newAvatar;
    _put('name', name);
    _put('bio', bio);
    _put('avatarColor', avatarColor);
    notifyListeners();
  }

  void setThemeIndex(int i) {
    themeIndex = i;
    _put('themeIndex', i);
    notifyListeners();
  }

  void setDailyGoal(int v) {
    dailyGoal = v < 1 ? 1 : (v > 30 ? 30 : v);
    _put('dailyGoal', dailyGoal);
    notifyListeners();
  }

  void setDayStart(int min) {
    dayStartMin = min;
    _put('dayStartMin', min);
    notifyListeners();
  }

  void setDayEnd(int min) {
    dayEndMin = min;
    _put('dayEndMin', min);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboarded = true;
    await _put('onboarded', true);
    notifyListeners();
  }

  Future<void> markSamplesSeeded() async {
    samplesSeeded = true;
    await _put('samplesSeeded', true);
  }

  /// Wipes every setting and restarts onboarding. Sample data is not re-seeded.
  Future<void> resetAll() async {
    try {
      await StorageService.clearSettings();
    } catch (_) {}
    name = '';
    bio = '';
    themeIndex = 0;
    onboarded = false;
    dailyGoal = 5;
    dayStartMin = 6 * 60;
    dayEndMin = 22 * 60;
    avatarColor = 0;
    samplesSeeded = true;
    await _put('samplesSeeded', true);
    notifyListeners();
  }
}
