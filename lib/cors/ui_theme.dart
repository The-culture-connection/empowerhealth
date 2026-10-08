import 'package:flutter/material.dart';

class AppTheme {
  // Hearth palette (design/hearth/THEME_SPEC.md §1). Older token names stay so
  // existing screens keep compiling; they point at the Hearth colour for their role.
  // - Purple: primary actions, links, icons, selected outlines.
  // - Gold: encouragement buttons, the active-tab bar, badges. Text on gold is ink.
  // - Red (emergency): reserved for a true emergency control only.

  // Hearth tokens
  /// Page ground.
  static const Color ground = Color(0xFFF5F1E8);
  /// Card and sheet surface.
  static const Color surface = Color(0xFFFAF8F4);
  /// Field inset inside a card.
  static const Color surfaceInset = Color(0xFFF5F1E8);
  /// Warm border for cards, fields and chips.
  static const Color borderWarm = Color(0xFFE6D5B8);
  /// Warm tint: icon chips, highlighted card, tags, selected fill.
  static const Color tintWarm = Color(0xFFEFE0C6);
  /// Outline of a filled star.
  static const Color starStroke = Color(0xFF8F5F33);
  /// Assistant bubbles and AI notes only.
  static const Color lavender = Color(0xFFEDE7F3);
  /// Headings and body text.
  static const Color ink = Color(0xFF2D2733);
  /// Text on purple.
  static const Color onPurple = Color(0xFFFFFFFF);
  static const Color onPurpleSecondary = Color(0xFFF5F1E8);
  /// True emergency control only.
  static const Color emergency = Color(0xFFD4183D);
  /// Bottom sheet drag handle.
  static const Color sheetHandle = Color(0xFFC9B8A0);
  /// Modal scrim: ink at 45%.
  static const Color scrim = Color(0x732D2733);

  // Brand palette (re-pointed to Hearth roles)
  static const Color brandPurple = Color(0xFF663399);
  static const Color brandPurpleMid = Color(0xFF7744AA);
  static const Color brandPurpleLight = Color(0xFF8855BB);
  static const Color brandBlack = ink;
  static const Color brandGold = Color(0xFFD4A574);
  static const Color brandGoldEnd = brandGold;
  /// Empty-star outline only.
  static const Color brandTerracotta = Color(0xFFC4956A);
  /// Text and icons on purple.
  static const Color brandWhite = onPurple;
  static const Color backgroundWarm = ground;
  static const Color surfaceCard = surface;
  /// Field on the page ground.
  static const Color surfaceInput = Color(0xFFFAF8F4);
  static const Color backgroundGradientStart = surface;
  static const Color backgroundGradientEnd = ground;

  // Text
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF4A3F52);
  /// Captions, placeholders, inactive nav.
  static const Color textMuted = Color(0xFF6B5C75);
  static const Color textLight = textMuted;
  static const Color textLighter = textMuted;
  static const Color textLightest = textMuted;
  static const Color textBarelyVisible = textMuted;

  // Borders
  static const Color borderLight = borderWarm;
  static const Color borderLighter = borderWarm;
  static const Color borderLightest = borderWarm;
  static const Color borderSubtlePurple = borderWarm;

  static const Color navInactiveLight = textMuted;
  static const Color navBarBgLight = surface;
  static const Color navBarBorderLight = borderWarm;

  /// Hearth card: surface fill, 1px warm border, radius 24, no shadow.
  static BoxDecoration cardDecoration({
    Color? color,
    double? radius,
    bool border = true,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radius ?? radiusMedium),
      border: border ? Border.all(color: borderWarm) : null,
      boxShadow: boxShadow,
    );
  }

  // Font families (bundled in assets/fonts/hearth so the app looks right offline).
  static const String serifFamily = 'YoungSerif';
  static const String sansFamily = 'Figtree';

  static TextStyle _serif(double size, double lineHeight, {Color color = ink}) => TextStyle(
        fontFamily: serifFamily,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle _sans(
    double size,
    double lineHeight,
    FontWeight weight, {
    Color color = ink,
  }) =>
      TextStyle(
        fontFamily: sansFamily,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        color: color,
      );

  /// Hearth text theme: Young Serif for display/headline, Figtree for the rest.
  static TextTheme textTheme() => TextTheme(
        // Tab-root title, pushed-screen title, section heading, feature-card title.
        displayLarge: _serif(34, 40),
        displayMedium: _serif(30, 36),
        displaySmall: _serif(26, 32),
        headlineLarge: _serif(26, 32),
        headlineMedium: _serif(20, 26),
        headlineSmall: _serif(19, 25),
        // Card and row titles, field labels.
        titleLarge: _sans(17, 24, FontWeight.w700),
        titleMedium: _sans(16, 22, FontWeight.w700),
        titleSmall: _sans(14, 20, FontWeight.w600),
        // Body and captions.
        bodyLarge: _sans(15, 22, FontWeight.w400, color: textSecondary),
        bodyMedium: _sans(14, 21, FontWeight.w400, color: textSecondary),
        bodySmall: _sans(13, 18, FontWeight.w400, color: textMuted),
        // Button, chip, tag.
        labelLarge: _sans(16, 22, FontWeight.w700),
        labelMedium: _sans(14, 20, FontWeight.w600, color: textSecondary),
        labelSmall: _sans(12, 18, FontWeight.w700, color: textSecondary),
      );

  static const double buttonHeight = 52;
  static const double fieldRadius = 18;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: sansFamily,
    );
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPurple,
      brightness: Brightness.light,
    ).copyWith(
      primary: brandPurple,
      onPrimary: onPurple,
      secondary: brandGold,
      onSecondary: ink,
      tertiary: brandPurpleMid,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: ground,
      surfaceTint: Colors.transparent,
      outline: borderWarm,
      outlineVariant: borderWarm,
      error: emergency,
      scrim: scrim,
    );
    final text = textTheme();
    const stadium = StadiumBorder();
    final buttonText = _sans(16, 22, FontWeight.w700);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: const BorderSide(color: borderWarm),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ground,
      canvasColor: ground,
      dividerColor: borderWarm,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: text,
      primaryTextTheme: text,
      iconTheme: const IconThemeData(color: ink),
      appBarTheme: AppBarTheme(
        backgroundColor: ground,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: _serif(20, 26),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPurple,
          foregroundColor: onPurple,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: stadium,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandPurple,
          foregroundColor: onPurple,
          minimumSize: const Size(64, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: stadium,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandPurple,
          side: const BorderSide(color: brandPurple, width: 1.5),
          minimumSize: const Size(64, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: stadium,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandPurple,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: brandPurple, width: 2),
        ),
        errorBorder: fieldBorder,
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: brandPurple, width: 2),
        ),
        hintStyle: _sans(15, 22, FontWeight.w400, color: textMuted),
        labelStyle: _sans(15, 22, FontWeight.w400, color: textMuted),
        floatingLabelStyle: _sans(14, 20, FontWeight.w600, color: brandPurple),
        helperStyle: _sans(13, 18, FontWeight.w400, color: textMuted),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: tintWarm,
        disabledColor: ground,
        checkmarkColor: brandPurple,
        side: const BorderSide(color: borderWarm),
        shape: stadium,
        labelStyle: _sans(14, 20, FontWeight.w600, color: textSecondary),
        secondaryLabelStyle: _sans(14, 20, FontWeight.w700, color: brandPurple),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 0,
        pressElevation: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? brandPurple : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(onPurple),
        side: const BorderSide(color: textMuted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? brandPurple : textMuted,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? onPurple : surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? brandPurple : borderWarm,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: borderWarm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: scrim,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        titleTextStyle: _serif(20, 26),
        contentTextStyle: _sans(15, 22, FontWeight.w400, color: textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ground,
        modalBackgroundColor: ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: scrim,
        dragHandleColor: sheetHandle,
        dragHandleSize: Size(40, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: brandPurple,
        unselectedItemColor: textMuted,
        backgroundColor: surface,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle: _sans(11, 14, FontWeight.w700),
        unselectedLabelStyle: _sans(11, 14, FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(color: borderWarm, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandPurple,
        linearTrackColor: borderWarm,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: brandPurple,
        selectionColor: brandPurple.withValues(alpha: 0.2),
        selectionHandleColor: brandPurple,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: borderWarm),
        ),
        textStyle: _sans(15, 22, FontWeight.w400),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: _sans(14, 20, FontWeight.w500, color: onPurpleSecondary),
        actionTextColor: brandGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPurple,
      primary: brandPurple,
      secondary: brandPurple,
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
          foregroundColor: brandPurple,
          side: BorderSide(color: brandPurple.withValues(alpha: 0.7), width: 1.5),
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

  /// Screen side padding (Hearth).
  static const double screenPadding = 20.0;

  // Corner radii
  static const double radiusSmall = 18.0;
  static const double radius = 20.0;
  static const double radiusMedium = 24.0;
  static const double radiusLarge = 28.0;
  static const double radiusXLarge = 32.0;

  // Older role names, re-pointed to Hearth colours.
  static const Color lightPrimary = brandPurple;
  static const Color lightAccent = brandGold;
  static const Color lightForeground = ink;
  static const Color lightBackground = ground;
  /// Emergency only (see [emergency]).
  static const Color error = emergency;

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

  /// Serif title in ink (Hearth headings).
  static TextStyle responsiveTitleStyle(BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    String? fontFamily,
    double? baseSize,
  }) {
    return TextStyle(
      fontSize: responsiveFontSize(context, baseSize: baseSize ?? 20),
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? ink,
      fontFamily: fontFamily ?? serifFamily,
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
      color: color ?? textSecondary,
      fontFamily: sansFamily,
    );
  }

  /// Plain app bar on the page ground with a serif title.
  static AppBar newUiAppBar(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      title: Text(
        title,
        style: _serif(20, 26),
      ),
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: ground,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      actions: actions,
      bottom: bottom,
    );
  }
}
