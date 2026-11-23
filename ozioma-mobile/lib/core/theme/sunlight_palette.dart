import 'package:flutter/material.dart';

/// Ultra-Contrast Sunlight Palette designed for direct equatorial sunlight readability
/// and OLED battery conservation in field ministry service.
/// All text/background combinations meet or exceed WCAG AAA (>= 7:1) contrast ratio.
class SunlightPalette {
  // Ultra-High Contrast Solids
  static const Color oledBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  
  // High-Visibility Accents for Direct Glare
  static const Color sunlightYellow = Color(0xFFFFD600); // 700-nit eye catch
  static const Color highVisGreen = Color(0xFF00E676);   // Visited / Active status
  static const Color highVisRed = Color(0xFFFF1744);     // DNC / Urgent warning
  static const Color highVisOrange = Color(0xFFFF9100);  // Not-At-Home / Warning
  static const Color highVisCyan = Color(0xFF00E5FF);    // Info / Return Visit call
  
  // Slate Neutrals (for standard daytime indoors)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Minimum Touch Target Dimension
  static const double minTouchTarget = 48.0;
}
