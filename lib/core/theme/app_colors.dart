import 'package:flutter/material.dart';

extension ColorX on Color {
  /// Same colour with the given opacity (0..1).
  Color o(double opacity) {
    final a = opacity < 0 ? 0.0 : (opacity > 1 ? 1.0 : opacity);
    return withAlpha((a * 255).round());
  }
}

class TaskColor {
  final String name;
  final Color color;
  const TaskColor(this.name, this.color);
}

class AppColors {
  AppColors._();

  static const primary = Color(0xFF6C63FF);
  static const secondary = Color(0xFF38BDF8);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const nowRed = Color(0xFFFF4D6D);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B6CFF), Color(0xFF5B7CFF), Color(0xFF38BDF8)],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
  );

  static const taskColors = <TaskColor>[
    TaskColor('Purple', Color(0xFF7C6CFF)),
    TaskColor('Blue', Color(0xFF3B82F6)),
    TaskColor('Cyan', Color(0xFF22B8E6)),
    TaskColor('Green', Color(0xFF22C55E)),
    TaskColor('Orange', Color(0xFFFB8A3C)),
    TaskColor('Pink', Color(0xFFEC4899)),
    TaskColor('Red', Color(0xFFEF4444)),
    TaskColor('Yellow', Color(0xFFF5B00B)),
  ];

  static TaskColor taskColor(int i) {
    final idx = i < 0 ? 0 : (i >= taskColors.length ? taskColors.length - 1 : i);
    return taskColors[idx];
  }

  static LinearGradient gradientFor(Color c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(c, Colors.white, 0.24)!, c],
      );
}

/// Light / dark design tokens. Dark mode is designed, not inverted.
class AppPalette {
  final Brightness brightness;
  final Color bgTop;
  final Color bgBottom;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color border;
  final Color shadow;

  const AppPalette({
    required this.brightness,
    required this.bgTop,
    required this.bgBottom,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.border,
    required this.shadow,
  });

  bool get dark => brightness == Brightness.dark;

  static const day = AppPalette(
    brightness: Brightness.light,
    bgTop: Color(0xFFF4F2FF),
    bgBottom: Color(0xFFE8F4FF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0F1FA),
    text: Color(0xFF14152B),
    textMuted: Color(0xFF5B6080),
    textFaint: Color(0xFF9AA0BC),
    border: Color(0xFFE2E5F4),
    shadow: Color(0x1A5B54D6),
  );

  static const night = AppPalette(
    brightness: Brightness.dark,
    bgTop: Color(0xFF0B0E22),
    bgBottom: Color(0xFF121A38),
    surface: Color(0xFF181E3F),
    surfaceAlt: Color(0xFF222A55),
    text: Color(0xFFF2F4FF),
    textMuted: Color(0xFFA7ADCE),
    textFaint: Color(0xFF6F76A3),
    border: Color(0xFF2B3466),
    shadow: Color(0x66000000),
  );
}

extension PaletteContext on BuildContext {
  AppPalette get pal =>
      Theme.of(this).brightness == Brightness.dark ? AppPalette.night : AppPalette.day;
}
