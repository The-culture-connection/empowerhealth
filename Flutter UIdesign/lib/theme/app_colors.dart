import 'package:flutter/material.dart';

/// Matches `src/styles/theme.css` and Layout/Home usage in the React app.
abstract final class AppColors {
  static const Color lightBackground = Color(0xFFFAF8F4);
  static const Color darkBackground = Color(0xFF1A1520);

  static const Color lightSurface = Color(0xFFFAF8F4);
  static const Color darkSurface = Color(0xFF2A2435);

  static const Color primary = Color(0xFF663399);
  static const Color primaryDarkMode = Color(0xFF9D7AB8);

  static const Color accent = Color(0xFFD4A574);
  static const Color accentSoft = Color(0xFFE0B589);

  static const Color textPrimaryLight = Color(0xFF2D2235);
  static const Color textPrimaryDark = Color(0xFFF5F0F7);

  static const Color mutedLight = Color(0xFF75657D);
  static const Color mutedDark = Color(0xFFCBBEC9);

  static const Color borderLight = Color(0x66E8E0F0);
  static const Color borderDark = Color(0x663A3043);

  static const Color navInactiveLight = Color(0xFFCBBEC9);
  static const Color navInactiveDark = Color(0xFF75657D);

  static const Color purpleBlur = Color(0xFFB899D4);
  static const Color goldBlur = Color(0xFFD4A574);

  static const Color journeyGradientStart = Color(0xFF663399);
  static const Color journeyGradientMid = Color(0xFF7744AA);
  static const Color journeyGradientEnd = Color(0xFF8855BB);

  static const Color journeyDarkStart = Color(0xFF2A2435);
  static const Color journeyDarkMid = Color(0xFF3A3149);
  static const Color journeyDarkEnd = Color(0xFF4A3E5D);
}
