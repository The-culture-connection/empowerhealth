import 'package:flutter/material.dart';

class AppTheme {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF5F2EE); // light tan
  static const Color lightForeground = Color(0xFF5C524A); // dark brown text
  static const Color lightCard = Color(0xFFFAF9F7); // very light tan
  static const Color lightPrimary = Color(0xFFB8865A); // medium tan/brown
  static const Color lightSecondary = Color(0xFFD9CEB8); // light beige
  static const Color lightAccent = Color(0xFFC8A97A); // tan/gold
  static const Color lightBorder = Color(0xFFD4C9BC); // tan border
  static const Color lightMuted = Color(0xFFE0D9D0); // muted tan

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF3D342E); // dark tan
  static const Color darkForeground = Color(0xFFE0D9D0); // light tan text
  static const Color darkCard = Color(0xFF433A33); // dark tan card
  static const Color darkPrimary = Color(0xFFA07050); // muted tan
  static const Color darkSecondary = Color(0xFFA89A70); // olive tan
  static const Color darkAccent = Color(0xFFB08B60); // tan accent

  // Shared colors
  static const Color success = Color(0xFF6B9B7A);
  static const Color warning = Color(0xFFD4A574);
  static const Color error = Color(0xFFB86B5C);

  // Spacing & Radii
  static const double radius = 20;
  static const double radiusSmall = 12;
  static const double spacingXS = 8;
  static const double spacingS = 12;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // Shadows
  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: const Color(0xFF5C524A).withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    )
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 4),
    )
  ];

  // Typography
  static const String fontFamily = 'Inter';

  static TextTheme lightTextTheme = const TextTheme(
    displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.2),
    displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
    displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2),
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.3),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
  ).apply(
    bodyColor: lightForeground,
    displayColor: lightForeground,
    fontFamily: fontFamily,
  );

  static TextTheme darkTextTheme = lightTextTheme.apply(
    bodyColor: darkForeground,
    displayColor: darkForeground,
    fontFamily: fontFamily,
  );

  // Light Theme
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        onPrimary: Colors.white,
        secondary: lightSecondary,
        onSecondary: lightForeground,
        surface: lightCard,
        onSurface: lightForeground,
        error: error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: lightTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: lightForeground,
        titleTextStyle: TextStyle(
          color: lightForeground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shadowColor: lightForeground.withOpacity(0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: lightForeground, fontFamily: fontFamily),
        hintStyle: TextStyle(color: lightForeground.withOpacity(0.5), fontFamily: fontFamily),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
            fontFamily: fontFamily,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: lightPrimary, width: 2),
          foregroundColor: lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
            fontFamily: fontFamily,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: fontFamily,
          ),
        ),
      ),
      dividerColor: lightBorder,
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
    );
  }

  // Dark Theme
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: Colors.white,
        secondary: darkSecondary,
        onSecondary: darkForeground,
        surface: darkCard,
        onSurface: darkForeground,
        error: error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: darkTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: darkForeground,
        titleTextStyle: TextStyle(
          color: darkForeground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.2),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: darkForeground.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: darkForeground.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: darkForeground, fontFamily: fontFamily),
        hintStyle: TextStyle(color: darkForeground.withOpacity(0.5), fontFamily: fontFamily),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
            fontFamily: fontFamily,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: darkPrimary, width: 2),
          foregroundColor: darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
            fontFamily: fontFamily,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: fontFamily,
          ),
        ),
      ),
      dividerColor: darkForeground.withOpacity(0.2),
      dividerTheme: DividerThemeData(
        color: darkForeground.withOpacity(0.2),
        thickness: 1,
      ),
    );
  }
}
