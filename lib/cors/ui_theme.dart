import 'package:flutter/material.dart';

class AppTheme {
  // Brand palette from request
  static const Color brandBrown = Color(0xFF5B331C); // #5b331c
  static const Color brandBlack = Color(0xFF000000); // #000000
  static const Color brandWhite = Color.fromARGB(255, 192, 115, 115); // #ffffff
  static const Color brandPeach = Color.fromARGB(255, 39, 17, 4); // #ffceb2

  // Backwards-compatible names used in code
  static const Color _primary = brandBrown;
  static const Color _secondary = brandPeach;
  static const Color _surface = brandWhite;
  static const Color _text = brandBlack;

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
      background: _surface,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background,
        foregroundColor: _text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Primary',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _text,
        ),
      ),
      // Default to Secondary font for general text; override titles with Primary
      textTheme: base.textTheme
          .apply(
            bodyColor: _text,
            displayColor: _text,
            fontFamily: 'Secondary',
          )
          .copyWith(
            displayLarge: base.textTheme.displayLarge?.copyWith(fontFamily: 'Primary'),
            displayMedium: base.textTheme.displayMedium?.copyWith(fontFamily: 'Primary'),
            displaySmall: base.textTheme.displaySmall?.copyWith(fontFamily: 'Primary'),
            headlineLarge: base.textTheme.headlineLarge?.copyWith(fontFamily: 'Primary'),
            headlineMedium: base.textTheme.headlineMedium?.copyWith(fontFamily: 'Primary'),
            headlineSmall: base.textTheme.headlineSmall?.copyWith(fontFamily: 'Primary'),
            titleLarge: base.textTheme.titleLarge?.copyWith(fontFamily: 'Primary'),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBrown,
          foregroundColor: brandBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandBrown,
          side: const BorderSide(color: brandBrown, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brandWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: brandWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: brandBrown,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: brandWhite,
        showUnselectedLabels: true,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      colorScheme: colorScheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBrown,
          foregroundColor: brandBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandPeach,
          side: BorderSide(color: brandPeach.withOpacity(0.7), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
