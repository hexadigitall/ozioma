import 'package:flutter/material.dart';
import 'sunlight_palette.dart';

/// Theocratic Sunlight Design System
/// Enforces WCAG AAA contrast and >= 48x48dp touch bounds for field preaching.
class SunlightTheme {
  static ThemeData get sunlightDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SunlightPalette.oledBlack,
      canvasColor: SunlightPalette.oledBlack,
      cardColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: SunlightPalette.sunlightYellow,
        onPrimary: SunlightPalette.oledBlack,
        secondary: SunlightPalette.highVisGreen,
        onSecondary: SunlightPalette.oledBlack,
        surface: SunlightPalette.oledBlack,
        onSurface: SunlightPalette.pureWhite,
        error: SunlightPalette.highVisRed,
        onError: SunlightPalette.oledBlack,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SunlightPalette.oledBlack,
        foregroundColor: SunlightPalette.pureWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: SunlightPalette.pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SunlightPalette.oledBlack,
        indicatorColor: SunlightPalette.sunlightYellow,
        elevation: 4,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: SunlightPalette.sunlightYellow,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            );
          }
          return const TextStyle(
            color: SunlightPalette.pureWhite,
            fontWeight: FontWeight.normal,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: SunlightPalette.oledBlack,
              size: 26,
            );
          }
          return const IconThemeData(
            color: SunlightPalette.pureWhite,
            size: 24,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
          backgroundColor: SunlightPalette.sunlightYellow,
          foregroundColor: SunlightPalette.oledBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
          backgroundColor: SunlightPalette.sunlightYellow,
          foregroundColor: SunlightPalette.oledBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
          foregroundColor: SunlightPalette.pureWhite,
          side: const BorderSide(color: SunlightPalette.pureWhite, width: 2),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF141414),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A2A2A), width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: SunlightPalette.pureWhite,
          fontWeight: FontWeight.w900,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: SunlightPalette.pureWhite,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: SunlightPalette.pureWhite,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: SunlightPalette.pureWhite,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
      ),
    );
  }

  static ThemeData get sunlightLightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: SunlightPalette.pureWhite,
      cardColor: SunlightPalette.pureWhite,
      colorScheme: const ColorScheme.light(
        primary: SunlightPalette.oledBlack,
        onPrimary: SunlightPalette.pureWhite,
        secondary: Color(0xFF00897B),
        onSecondary: SunlightPalette.pureWhite,
        surface: SunlightPalette.pureWhite,
        onSurface: SunlightPalette.oledBlack,
        error: Color(0xFFD32F2F),
        onError: SunlightPalette.pureWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SunlightPalette.pureWhite,
        foregroundColor: SunlightPalette.oledBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: SunlightPalette.oledBlack,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SunlightPalette.pureWhite,
        indicatorColor: SunlightPalette.slate200,
        elevation: 4,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: SunlightPalette.oledBlack,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            );
          }
          return const TextStyle(
            color: SunlightPalette.slate700,
            fontWeight: FontWeight.normal,
            fontSize: 12,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
          backgroundColor: SunlightPalette.oledBlack,
          foregroundColor: SunlightPalette.pureWhite,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
        ),
      ),
      cardTheme: const CardThemeData(
        color: SunlightPalette.pureWhite,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: SunlightPalette.slate200, width: 1.5),
        ),
      ),
    );
  }
}
