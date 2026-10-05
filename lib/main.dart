import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/app.dart';
import 'package:timeblock/providers/settings_provider.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await StorageService.init();

  final settings = SettingsProvider();
  final tasks = TaskProvider();
  await settings.load();
  await tasks.load();

  // First launch: fill the app with sample data so it looks alive.
  // Sample tasks can be removed any time from Settings > Data.
  if (!settings.samplesSeeded) {
    await tasks.seedSamples(DateTime.now());
    await settings.markSamplesSeeded();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<TaskProvider>.value(value: tasks),
      ],
      child: const TimeBlockApp(),
    ),
  );
}
