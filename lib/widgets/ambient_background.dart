import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';

/// Diffuse gold + lavender wash and subtle dot texture — parity with `Flutter UIdesign`
/// (`ambient_background.dart`) / NewUI Layout. Base fill comes from the parent scaffold
/// ([AppTheme.backgroundWarm]); this layer is non-interactive.
///
/// Set [showRadialWashes] to false to drop the large soft circles (e.g. Learn tab) while
/// keeping the light dot texture.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, this.showRadialWashes = true});

  /// Large gold/lavender radial gradients behind content.
  final bool showRadialWashes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final layerStrength = isDark ? 0.78 : 1.0;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showRadialWashes) ...[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.72, -0.92),
                    radius: 1.35,
                    colors: [
                      AppTheme.brandGold.withValues(alpha: 0.42 * layerStrength),
                      AppTheme.brandGold.withValues(alpha: 0.14 * layerStrength),
                      AppTheme.brandGold.withValues(alpha: 0.04 * layerStrength),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.28, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.82, 0.78),
                    radius: 1.25,
                    colors: [
                      AppTheme.ambientPurpleBlur.withValues(alpha: 0.38 * layerStrength),
                      AppTheme.ambientPurpleBlur.withValues(alpha: 0.12 * layerStrength),
                      AppTheme.ambientPurpleBlur.withValues(alpha: 0.035 * layerStrength),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.52, 1.0],
                  ),
                ),
              ),
            ),
            if (isDark)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.5, -0.5),
                      radius: 1.5,
                      colors: [
                        AppTheme.brandGold.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
          ],
          Positioned.fill(
            child: CustomPaint(
              painter: _DotTexturePainter(
                color: AppTheme.brandPurple.withValues(alpha: 0.018),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotTexturePainter extends CustomPainter {
  _DotTexturePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const tile = 100.0;
    const r = 1.0;
    for (var y = 0.0; y < size.height + tile; y += tile) {
      for (var x = 0.0; x < size.width + tile; x += tile) {
        canvas.drawCircle(Offset(x + 2, y + 2), r, paint);
        canvas.drawCircle(Offset(x + 50, y + 50), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotTexturePainter oldDelegate) =>
      oldDelegate.color != color;
}
