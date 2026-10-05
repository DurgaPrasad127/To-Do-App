import 'package:flutter/material.dart';
import 'package:timeblock/core/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppPalette.day);
  static ThemeData dark() => _build(AppPalette.night);

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: p.brightness,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.danger,
      surface: p.surface,
      onSurface: p.text,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
    );
    final tt = base.textTheme.apply(bodyColor: p.text, displayColor: p.text);
    return base.copyWith(
      scaffoldBackgroundColor: p.bgTop,
      textTheme: tt.copyWith(
        headlineLarge: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
        headlineMedium: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
        titleLarge: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
