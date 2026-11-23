import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemeMode {
  sunlightDark,
  sunlightLight,
  system,
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.sunlightDark);

  void setMode(AppThemeMode mode) => state = mode;

  void toggleSunlightMode() {
    if (state == AppThemeMode.sunlightDark) {
      state = AppThemeMode.sunlightLight;
    } else {
      state = AppThemeMode.sunlightDark;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});
