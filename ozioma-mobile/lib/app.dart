import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/sunlight_theme.dart';
import 'core/theme/theme_provider.dart';
import 'screens/lock_screen.dart';
import 'screens/shell.dart';

class OziomaApp extends ConsumerWidget {
  const OziomaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);

    ThemeMode themeMode;
    switch (mode) {
      case AppThemeMode.sunlightDark:
        themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.sunlightLight:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp(
      title: 'Ozioma',
      debugShowCheckedModeBanner: false,
      theme: SunlightTheme.sunlightLightTheme,
      darkTheme: SunlightTheme.sunlightDarkTheme,
      themeMode: themeMode,
      home: const LockScreen(child: Shell()),
    );
  }
}
