import 'package:flutter/material.dart';

class AppTheme {
  // Color roles (mobile UI):
  // - Purple: primary actions only (submit, save, main navigation CTAs).
  // - Gold / terracotta: encouragement and community cues (survey prompts, FAB compose, filters on community).
  // - Red: reserve for true safety / emergency only (not validation or likes).
  // - SnackBars: validation → brandGold; success → brandTurquoise; generic errors → brandPurple.

  // Brand palette matching NewUI design system
  static const Color brandTurquoise = Color(0xFF23C0C2); // Secondary accent (not primary CTAs)
  static const Color brandPurple = Color(0xFF663399); // #663399 — primary actions only
  static const Color brandPurpleMid = Color(0xFF7744AA);
  static const Color brandPurpleLight = Color(0xFF8855BB); // #8855BB (gradient end)
  static const Color brandBlack = Color(0xFF2D2733); // #2d2733 (NewUI foreground)
  static const Color brandGold = Color(0xFFD4A574); // #d4a574 — encouragement / community cues
  static const Color brandGoldEnd = Color(0xFFE0B589);
  static const Color brandTerracotta = Color(0xFFC4956A);
  /// Stark white — use only for text/icons on purple or gold buttons
  static const Color brandWhite = Color(0xFFFFFFFF);
  /// Gold-tinted off-white — default page / scaffold background (not stark white)
  static const Color backgroundWarm = Color(0xFFF5F1E8);
  /// Warm card / sheet / panel surface
  static const Color surfaceCard = Color(0xFFFAF7F0);
  /// Input / inset fields (NewUI --input-background)
  static const Color surfaceInput = Color(0xFFF3F3F5);
  static const Color backgroundGradientStart = Color(0xFFFAF7F0);
  static const Color backgroundGradientEnd = Color(0xFFF5F1E8);
  
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
  /// Subtle purple-tinted border (NewUI --border)
  static Color borderSubtlePurple = brandPurple.withOpacity(0.12);
  
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
  static const Color _surface = surfaceCard;
  static const Color _text = brandBlack;

  /// Primary CTA gradient (purple only)
  static const LinearGradient primaryActionGradient = LinearGradient(
    colors: [Color(0xFF663399), Color(0xFF7744AA), Color(0xFF8855BB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Encouragement / community / supportive actions (not primary navigation)
  static const LinearGradient encouragementGradient = LinearGradient(
    colors: [Color(0xFFD4A574), Color(0xFFE0B589)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft purple shadow — NewUI shadow-[0_4px_20px_rgba(102,51,153,0.08)]
  static List<BoxShadow> shadowSoft({double opacity = 0.08, double blur = 20, double y = 4}) => [
        BoxShadow(
          color: brandPurple.withOpacity(opacity),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];

  /// Medium lift — NewUI shadow-[0_8px_32px_rgba(102,51,153,0.12)]
  static List<BoxShadow> shadowMedium({double opacity = 0.12, double blur = 32, double y = 8}) => [
        BoxShadow(
          color: brandPurple.withOpacity(opacity),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];

  static BoxDecoration cardDecoration({
    Color? color,
    double? radius,
    bool border = true,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? surfaceCard,
      borderRadius: BorderRadius.circular(radius ?? radiusMedium),
      border: border ? Border.all(color: borderLight.withOpacity(0.5)) : null,
      boxShadow: boxShadow ?? shadowSoft(),
    );
  }

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
      error: error,
      brightness: Brightness.light,
    );

    final relaxedBody = base.textTheme.bodyMedium?.copyWith(
      height: 1.5,
      fontWeight: FontWeight.w300,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundWarm,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundWarm,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Primary',
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
      ),
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
            bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5, fontWeight: FontWeight.w300),
            bodyMedium: relaxedBody,
            bodySmall: base.textTheme.bodySmall?.copyWith(height: 1.45, fontWeight: FontWeight.w300),
            labelLarge: base.textTheme.labelLarge?.copyWith(height: 1.35),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPurple,
          foregroundColor: brandWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandPurple,
          foregroundColor: brandWhite,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandPurple,
          side: BorderSide(color: brandPurple.withOpacity(0.38), width: 1.5),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandPurple,
          minimumSize: const Size(48, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: _primary.withOpacity(0.35), width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: brandPurple,
        unselectedItemColor: textLightest,
        backgroundColor: surfaceCard,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
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
          foregroundColor: brandWhite,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandTurquoise,
          side: BorderSide(color: brandTurquoise.withOpacity(0.7), width: 1.5),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
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
