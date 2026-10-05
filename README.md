# TimeBlock - time-blocking to-do & daily planner (Flutter)

Plan your day -> follow your time blocks -> complete tasks -> see your progress.
Fully offline. State: Provider. Storage: Hive. No code generation needed.

## Run it

```bash
flutter create timeblock --org com.example --platforms android
cd timeblock
# copy this project's `lib/` folder and `pubspec.yaml` over the generated ones
rm -f test/widget_test.dart
flutter pub get
flutter run
```

Requires Flutter 3.22+ (Dart 3.3+).

## Structure
lib/main.dart, app.dart · core/{theme,constants,utils} · models/task.dart ·
services/storage_service.dart · providers/{task,settings}_provider.dart ·
widgets/ (task_card, timeline, progress_card, calendar, task_editor_sheet, ...) ·
screens/{onboarding,today,calendar,tasks,insights,settings}

Sample tasks are added on first launch (Profile > Data > Remove sample tasks).
