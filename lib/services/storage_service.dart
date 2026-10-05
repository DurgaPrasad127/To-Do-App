import 'package:hive_flutter/hive_flutter.dart';

/// Thin wrapper over Hive. Tasks live in their own box (one record per task,
/// keyed by id); settings live in a second box.
class StorageService {
  StorageService._();

  static late Box<dynamic> _tasks;
  static late Box<dynamic> _settings;

  static Future<void> init() async {
    await Hive.initFlutter();
    _tasks = await Hive.openBox<dynamic>('tasks');
    _settings = await Hive.openBox<dynamic>('settings');
  }

  static List<Map<String, dynamic>> loadTaskMaps() {
    final out = <Map<String, dynamic>>[];
    for (final v in _tasks.values) {
      if (v is Map) {
        try {
          out.add(Map<String, dynamic>.from(v));
        } catch (_) {
          // skip corrupted record
        }
      }
    }
    return out;
  }

  static Future<void> saveTask(Map<String, dynamic> m) => _tasks.put(m['id'], m);

  static Future<void> saveTasks(List<Map<String, dynamic>> list) =>
      _tasks.putAll({for (final m in list) m['id'] as String: m});

  static Future<void> deleteTask(String id) => _tasks.delete(id);

  static Future<void> deleteTasks(Iterable<String> ids) => _tasks.deleteAll(ids);

  static Future<void> clearTasks() async {
    await _tasks.clear();
  }

  static T read<T>(String key, T fallback) {
    final v = _settings.get(key);
    return v is T ? v : fallback;
  }

  static Future<void> write(String key, dynamic value) => _settings.put(key, value);

  static Future<void> clearSettings() async {
    await _settings.clear();
  }
}
