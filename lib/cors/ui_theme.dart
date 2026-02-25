import 'package:flutter/material.dart';

class AppTheme {
  // Brand palette from brand guidelines
  static const Color brandTurquoise = Color(0xFF23C0C2); // #23C0C2
  static const Color brandPurple = Color(0xFF663398); // #663398
  static const Color brandBlack = Color(0xFF0C0A0A); // #0C0A0A
  static const Color brandGold = Color(0xFFDCB85E); // #DCB85E
  static const Color brandWhite = Color(0xFFF4F4F4); // #F4F4F4

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
          backgroundColor: brandPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandPurple,
          side: const BorderSide(color: brandPurple, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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

  // Corner radii
  static const double radiusSmall = 8.0;
  static const double radius = 12.0;

  // Common colors used across light UI
  // These map to the brand palette above for consistency.
  static const Color lightPrimary = brandPurple;
  static const Color lightSecondary = brandTurquoise;
  static const Color lightAccent = brandGold;
  static const Color lightForeground = brandBlack;
  static const Color lightBackground = brandWhite;
  static const Color lightMuted = Color(0xFFF1F5F9); // neutral surface tint
  static const Color error = Color(0xFFE11D48);

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

  // Helper for responsive body text style
  static TextStyle responsiveBodyStyle(BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? baseSize,
  }) {
    return TextStyle(
      fontSize: responsiveFontSize(context, baseSize: baseSize ?? 14),
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? brandBlack,
    );
  }

  // Helper for responsive button text style
  static TextStyle responsiveButtonStyle(BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? baseSize,
  }) {
    return TextStyle(
      fontSize: responsiveFontSize(context, baseSize: baseSize ?? 16),
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? Colors.white,
    );
  }

  // Helper for responsive caption/small text style
  static TextStyle responsiveCaptionStyle(BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? baseSize,
  }) {
    return TextStyle(
      fontSize: responsiveFontSize(context, baseSize: baseSize ?? 12),
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? Colors.grey.shade600,
    );
  }

  // Safe text widget that prevents overflow
  static Widget safeText(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextAlign? textAlign,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.ellipsis,
      softWrap: true,
    );
  }

  // Responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context, {
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final multiplier = screenWidth < 360 ? 0.75 : (screenWidth > 600 ? 1.25 : 1.0);
    
    if (all != null) {
      return EdgeInsets.all(all * multiplier);
    }
    return EdgeInsets.symmetric(
      horizontal: (horizontal ?? 16) * multiplier,
      vertical: (vertical ?? 16) * multiplier,
    );
  }
}
