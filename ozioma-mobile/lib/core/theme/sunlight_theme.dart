import 'package:flutter/material.dart';
import 'sunlight_palette.dart';

/// Theocratic Sunlight & Modern Field Design System
/// Enforces WCAG AAA contrast and >= 48x48dp touch bounds for field preaching.
class SunlightTheme {
  static ThemeData get sunlightDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SunlightPalette.oledBlack,
      canvasColor: SunlightPalette.oledBlack,
      cardColor: const Color(0xFF10151E),
      colorScheme: const ColorScheme.dark(
        primary: SunlightPalette.sunlightYellow,
        onPrimary: SunlightPalette.oledBlack,
        secondary: SunlightPalette.highVisGreen,
        onSecondary: SunlightPalette.oledBlack,
        surface: Color(0xFF0A0E14),
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
          letterSpacing: 0.3,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: SunlightPalette.sunlightYellow,
        unselectedLabelColor: Color(0xFFB0BEC5),
        indicatorColor: SunlightPalette.sunlightYellow,
        dividerColor: Color(0xFF222A36),
        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF141A24),
        selectedColor: SunlightPalette.sunlightYellow.withValues(alpha: 0.22),
        side: const BorderSide(color: Color(0xFF2A3444)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(color: SunlightPalette.pureWhite, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF121822),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SunlightPalette.sunlightYellow, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SunlightPalette.sunlightYellow,
        foregroundColor: SunlightPalette.oledBlack,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF070A0F),
        indicatorColor: SunlightPalette.sunlightYellow,
        elevation: 4,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: SunlightPalette.sunlightYellow,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: SunlightPalette.pureWhite,
            fontWeight: FontWeight.normal,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: SunlightPalette.oledBlack,
              size: 25,
            );
          }
          return const IconThemeData(
            color: SunlightPalette.pureWhite,
            size: 23,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
          backgroundColor: SunlightPalette.sunlightYellow,
          foregroundColor: SunlightPalette.oledBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
          backgroundColor: SunlightPalette.sunlightYellow,
          foregroundColor: SunlightPalette.oledBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
          foregroundColor: SunlightPalette.pureWhite,
          side: const BorderSide(color: Color(0xFF475569), width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF10151E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF222A36), width: 1.2),
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
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: SunlightPalette.pureWhite,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0F172A),
        onPrimary: SunlightPalette.pureWhite,
        secondary: Color(0xFF059669),
        onSecondary: SunlightPalette.pureWhite,
        surface: SunlightPalette.pureWhite,
        onSurface: SunlightPalette.oledBlack,
        error: Color(0xFFD32F2F),
        onError: SunlightPalette.pureWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        foregroundColor: SunlightPalette.oledBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: SunlightPalette.oledBlack,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF0F172A),
        unselectedLabelColor: SunlightPalette.slate700,
        indicatorColor: Color(0xFF059669),
        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SunlightPalette.pureWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SunlightPalette.slate200),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SunlightPalette.pureWhite,
        indicatorColor: const Color(0xFFD1FAE5),
        elevation: 4,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFF065F46),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: SunlightPalette.slate700,
            fontWeight: FontWeight.normal,
            fontSize: 11,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: SunlightPalette.pureWhite,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: SunlightPalette.pureWhite,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: SunlightPalette.slate200, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(SunlightPalette.minTouchTarget, SunlightPalette.minTouchTarget),
        ),
      ),
      cardTheme: const CardThemeData(
        color: SunlightPalette.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: SunlightPalette.slate200, width: 1.2),
        ),
      ),
    );
  }
}
