// Hearth theme foundation: one palette and one type pairing for the whole app
// (design/hearth/THEME_SPEC.md §1-§3).
import 'package:empowerhealth/cors/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('colour tokens (THEME_SPEC §1)', () {
    const tokens = <String, (Color, int)>{
      'ground': (AppTheme.ground, 0xFFF5F1E8),
      'backgroundWarm': (AppTheme.backgroundWarm, 0xFFF5F1E8),
      'lightBackground': (AppTheme.lightBackground, 0xFFF5F1E8),
      'backgroundGradientEnd': (AppTheme.backgroundGradientEnd, 0xFFF5F1E8),
      'surface': (AppTheme.surface, 0xFFFAF8F4),
      'surfaceCard': (AppTheme.surfaceCard, 0xFFFAF8F4),
      'backgroundGradientStart': (AppTheme.backgroundGradientStart, 0xFFFAF8F4),
      'navBarBgLight': (AppTheme.navBarBgLight, 0xFFFAF8F4),
      'surfaceInset': (AppTheme.surfaceInset, 0xFFF5F1E8),
      'surfaceInput': (AppTheme.surfaceInput, 0xFFFAF8F4),
      'borderWarm': (AppTheme.borderWarm, 0xFFE6D5B8),
      'borderLight': (AppTheme.borderLight, 0xFFE6D5B8),
      'borderLighter': (AppTheme.borderLighter, 0xFFE6D5B8),
      'borderLightest': (AppTheme.borderLightest, 0xFFE6D5B8),
      'navBarBorderLight': (AppTheme.navBarBorderLight, 0xFFE6D5B8),
      'borderSubtlePurple': (AppTheme.borderSubtlePurple, 0xFFE6D5B8),
      'tintWarm': (AppTheme.tintWarm, 0xFFEFE0C6),
      'brandGold': (AppTheme.brandGold, 0xFFD4A574),
      'brandGoldEnd': (AppTheme.brandGoldEnd, 0xFFD4A574),
      'lightAccent': (AppTheme.lightAccent, 0xFFD4A574),
      'brandTerracotta': (AppTheme.brandTerracotta, 0xFFC4956A),
      'starStroke': (AppTheme.starStroke, 0xFF8F5F33),
      'brandPurple': (AppTheme.brandPurple, 0xFF663399),
      'lightPrimary': (AppTheme.lightPrimary, 0xFF663399),
      'brandPurpleMid': (AppTheme.brandPurpleMid, 0xFF7744AA),
      'lavender': (AppTheme.lavender, 0xFFEDE7F3),
      'ink': (AppTheme.ink, 0xFF2D2733),
      'brandBlack': (AppTheme.brandBlack, 0xFF2D2733),
      'textPrimary': (AppTheme.textPrimary, 0xFF2D2733),
      'lightForeground': (AppTheme.lightForeground, 0xFF2D2733),
      'textSecondary': (AppTheme.textSecondary, 0xFF4A3F52),
      'textMuted': (AppTheme.textMuted, 0xFF6B5C75),
      'textLight': (AppTheme.textLight, 0xFF6B5C75),
      'textLighter': (AppTheme.textLighter, 0xFF6B5C75),
      'textLightest': (AppTheme.textLightest, 0xFF6B5C75),
      'textBarelyVisible': (AppTheme.textBarelyVisible, 0xFF6B5C75),
      'navInactiveLight': (AppTheme.navInactiveLight, 0xFF6B5C75),
      'onPurple': (AppTheme.onPurple, 0xFFFFFFFF),
      'brandWhite': (AppTheme.brandWhite, 0xFFFFFFFF),
      'onPurpleSecondary': (AppTheme.onPurpleSecondary, 0xFFF5F1E8),
      'emergency': (AppTheme.emergency, 0xFFD4183D),
      'error': (AppTheme.error, 0xFFD4183D),
      'sheetHandle': (AppTheme.sheetHandle, 0xFFC9B8A0),
      'scrim': (AppTheme.scrim, 0x732D2733),
    };
    tokens.forEach((name, pair) {
      test(name, () => expect(pair.$1.toARGB32(), pair.$2));
    });

    test('retired tokens point at Hearth colours and draw no shadow', () {
      // ignore: deprecated_member_use_from_same_package
      expect(AppTheme.brandTurquoise, AppTheme.brandPurple);
      // ignore: deprecated_member_use_from_same_package
      expect(AppTheme.lightSecondary, AppTheme.brandPurple);
      // ignore: deprecated_member_use_from_same_package
      expect(AppTheme.ambientPurpleBlur, AppTheme.lavender);
      // ignore: deprecated_member_use_from_same_package
      expect(AppTheme.primaryActionGradient.colors.toSet(), {AppTheme.brandPurple});
      // ignore: deprecated_member_use_from_same_package
      expect(AppTheme.encouragementGradient.colors.toSet(), {AppTheme.brandGold});
      // ignore: deprecated_member_use_from_same_package
      expect(AppTheme.shadowSoft(), isEmpty);
      // ignore: deprecated_member_use_from_same_package
      expect(AppTheme.shadowMedium(), isEmpty);
      expect(AppTheme.cardDecoration().boxShadow, isNull);
    });
  });

  group('light theme', () {
    final theme = AppTheme.light();

    test('page ground and surfaces', () {
      expect(theme.scaffoldBackgroundColor, AppTheme.ground);
      expect(theme.colorScheme.primary, AppTheme.brandPurple);
      expect(theme.cardTheme.color, AppTheme.surface);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.dialogTheme.backgroundColor, AppTheme.ground);
      expect(theme.bottomSheetTheme.backgroundColor, AppTheme.ground);
      expect(theme.appBarTheme.backgroundColor, AppTheme.ground);
    });

    test('Young Serif for display and headlines', () {
      final t = theme.textTheme;
      for (final style in [
        t.displayLarge,
        t.displayMedium,
        t.displaySmall,
        t.headlineLarge,
        t.headlineMedium,
        t.headlineSmall,
      ]) {
        expect(style?.fontFamily, 'YoungSerif');
      }
      expect(t.displayLarge?.fontSize, 34);
      expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'YoungSerif');
    });

    test('Figtree for titles, body and labels', () {
      final t = theme.textTheme;
      for (final style in [
        t.titleLarge,
        t.titleMedium,
        t.titleSmall,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
        t.labelSmall,
      ]) {
        expect(style?.fontFamily, 'Figtree');
      }
      expect(t.bodyLarge?.fontSize, 15);
    });

    test('buttons are stadium-shaped and 52 high', () {
      for (final style in [
        theme.elevatedButtonTheme.style,
        theme.filledButtonTheme.style,
        theme.outlinedButtonTheme.style,
      ]) {
        expect(style?.shape?.resolve({}), isA<StadiumBorder>());
        expect(style?.minimumSize?.resolve({})?.height, 52);
        expect(style?.textStyle?.resolve({})?.fontWeight, FontWeight.w700);
      }
      expect(
        theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
        AppTheme.brandPurple,
      );
    });

    testWidgets('an ElevatedButton renders 52 high with the theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: ElevatedButton(onPressed: () {}, child: const Text('Save')),
          ),
        ),
      ));
      // The tap target is padded to 48; the visible button is the 52 minimum.
      expect(tester.getSize(find.byType(ElevatedButton)).height, 52);
    });

    test('fields: radius 18, warm border, 2px purple when focused', () {
      final input = theme.inputDecorationTheme;
      final enabled = input.enabledBorder as OutlineInputBorder;
      final focused = input.focusedBorder as OutlineInputBorder;
      expect(enabled.borderRadius, BorderRadius.circular(18));
      expect(enabled.borderSide.color, AppTheme.borderWarm);
      expect(focused.borderSide.color, AppTheme.brandPurple);
      expect(focused.borderSide.width, 2);
    });

    test('bottom nav: purple active, muted inactive, 11px labels', () {
      final nav = theme.bottomNavigationBarTheme;
      expect(nav.selectedItemColor, AppTheme.brandPurple);
      expect(nav.unselectedItemColor, AppTheme.textMuted);
      expect(nav.selectedLabelStyle?.fontSize, 11);
      expect(nav.selectedLabelStyle?.fontWeight, FontWeight.w700);
    });
  });
}
