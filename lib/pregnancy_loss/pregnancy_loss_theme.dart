import '../cors/ui_theme.dart';

/// Calm, low-clutter visuals for pregnancy-loss mode. Hearth uses the same
/// warm palette everywhere, so these now point at its tokens.
abstract final class PregnancyLossTheme {
  static const background = AppTheme.ground;
  static const cardFill = AppTheme.surface;
  static const accentSoft = AppTheme.tintWarm;
  static const borderSoft = AppTheme.borderWarm;
}
