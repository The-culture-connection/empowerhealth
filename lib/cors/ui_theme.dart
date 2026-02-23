import 'package:flutter/material.dart';

class AppTheme {
  // Brand palette matching NewUI design system
  static const Color brandTurquoise = Color(0xFF23C0C2); // #23C0C2
  static const Color brandPurple = Color(0xFF663399); // #663399 (NewUI primary)
  static const Color brandPurpleLight = Color(0xFF8855BB); // #8855BB (NewUI gradient end)
  static const Color brandBlack = Color(0xFF2D2733); // #2d2733 (NewUI foreground)
  static const Color brandGold = Color(0xFFD4A574); // #d4a574 (NewUI accent gold)
  static const Color brandWhite = Color(0xFFFFFFFF); // White
  static const Color backgroundWarm = Color(0xFFFAF8F4); // #faf8f4 (NewUI background)
  static const Color backgroundGradientStart = Color(0xFFFFFFFF); // White
  static const Color backgroundGradientEnd = Color(0xFFFAF8F4); // #faf8f4 (NewUI background)
  
  // NewUI specific colors
  static const Color textPrimary = Color(0xFF2D2733); // #2d2733
  static const Color textSecondary = Color(0xFF4A3F52); // #4a3f52
  static const Color textMuted = Color(0xFF6B5C75); // #6b5c75
  static const Color textLight = Color(0xFF8B7A95); // #8b7a95
  static const Color textLighter = Color(0xFF9D8FB5); // #9d8fb5
  static const Color textLightest = Color(0xFFA89CB5); // #a89cb5
  static const Color textBarelyVisible = Color(0xFFB5A8C2); // #b5a8c2
  
  // Border colors
  static const Color borderLight = Color(0xFFE8DFE8); // #e8dfe8
  static const Color borderLighter = Color(0xFFEDE7F3); // #ede7f3
  static const Color borderLightest = Color(0xFFF0E8F3); // #f0e8f3
  
  // Gradient colors
  static const Color gradientPurpleStart = Color(0xFF8B7AA8); // #8b7aa8
  static const Color gradientPurpleEnd = Color(0xFFB89FB5); // #b89fb5
  static const Color gradientBeigeStart = Color(0xFFD4C5E0); // #d4c5e0
  static const Color gradientBeigeEnd = Color(0xFFE0D5EB); // #e0d5eb
  static const Color gradientGoldStart = Color(0xFFE6D5B8); // #e6d5b8
  static const Color gradientGoldEnd = Color(0xFFD4A574); // #d4a574

  // Backwards-compatible names used in code
  static const Color _primary = brandPurple;
  static const Color _secondary = brandTurquoise;
  static const Color _accent = brandGold;
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
      scaffoldBackgroundColor: backgroundWarm, // Matching NewUI background
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundWarm,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Primary',
          fontSize: 20,
          fontWeight: FontWeight.w400, // Lighter weight matching NewUI
          color: textPrimary,
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
          backgroundColor: brandPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // rounded-[24px] matching NewUI
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400), // Lighter weight matching NewUI
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandPurple,
          side: const BorderSide(color: borderLight, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // rounded-[24px] matching NewUI
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400), // Lighter weight matching NewUI
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28), // rounded-[28px] matching NewUI
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: _primary.withOpacity(0.3), width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: brandWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // rounded-[28px] matching NewUI
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: brandPurple,
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
          backgroundColor: brandPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandTurquoise,
          side: BorderSide(color: brandTurquoise.withOpacity(0.7), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Spacing scale (used in widgets and screens)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;

  // Corner radii matching NewUI
  static const double radiusSmall = 18.0; // rounded-[18px]
  static const double radius = 20.0; // rounded-[20px]
  static const double radiusMedium = 24.0; // rounded-[24px]
  static const double radiusLarge = 28.0; // rounded-[28px]
  static const double radiusXLarge = 32.0; // rounded-[32px]

  // Common colors used across light UI
  // These map to the brand palette above for consistency.
  static const Color lightPrimary = brandPurple;
  static const Color lightSecondary = brandTurquoise;
  static const Color lightAccent = brandGold;
  static const Color lightForeground = textPrimary;
  static const Color lightBackground = backgroundWarm;
  static const Color lightMuted = Color(0xFFF1F5F9); // neutral surface tint
  static const Color error = Color(0xFFD4183D); // #d4183d (NewUI destructive)

  // Responsive text sizing based on screen width
  static double responsiveFontSize(BuildContext context, {
    double? baseSize,
    double? smallScreenMultiplier,
    double? largeScreenMultiplier,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final base = baseSize ?? 18.0;
    final small = smallScreenMultiplier ?? 0.85; // 15% smaller on small screens
    final large = largeScreenMultiplier ?? 1.15; // 15% larger on large screens
    
    if (screenWidth < 360) {
      // Small phones
      return base * small;
    } else if (screenWidth > 600) {
      // Tablets and large screens
      return base * large;
    }
    // Standard phones
    return base;
  }

  // Helper for responsive title text style
  static TextStyle responsiveTitleStyle(BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    String? fontFamily,
    double? baseSize,
  }) {
    return TextStyle(
      fontSize: responsiveFontSize(context, baseSize: baseSize ?? 20),
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? brandPurple,
      fontFamily: fontFamily ?? 'Primary',
    );
  }

  // Helper for responsive subtitle text style
  static TextStyle responsiveSubtitleStyle(BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? baseSize,
  }) {
    return TextStyle(
      fontSize: responsiveFontSize(context, baseSize: baseSize ?? 16),
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? brandBlack,
    );
  }
}
