import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/theme/app_theme.dart';
import 'package:timeblock/core/utils/ui_helpers.dart';
import 'package:timeblock/providers/settings_provider.dart';
import 'package:timeblock/screens/home_shell.dart';
import 'package:timeblock/screens/onboarding/onboarding_screen.dart';

class TimeBlockApp extends StatelessWidget {
  const TimeBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'TimeBlock',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppToast.key,
      themeMode: settings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: settings.onboarded
            ? const HomeShell(key: ValueKey('home'))
            : const OnboardingScreen(key: ValueKey('onboarding')),
      ),
    );
  }
}
