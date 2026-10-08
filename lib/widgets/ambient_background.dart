import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';

/// Flat page ground behind tab content. The old gold and lavender washes made
/// Home, Journal and Community look different from Learn and You; Hearth uses
/// one flat ground everywhere. Kept as a widget so existing screens don't change.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, this.showRadialWashes = true});

  /// No longer draws anything; kept so existing call sites compile.
  final bool showRadialWashes;

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: ColoredBox(color: AppTheme.ground),
    );
  }
}
