import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft ambient wash matching NEWUI (`Layout.tsx` / `Home.tsx`): base screen color
/// comes from [ThemeData.scaffoldBackgroundColor]; this layer adds diffuse gold
/// (upper-right) and lavender (lower-left) plus the 1.5% purple dot texture.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Home.tsx: opacity-40 light / opacity-30 dark on the glow layer
    final layerStrength = isDark ? 0.78 : 1.0;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gold wash — React: top-0 right-1/3, #d4a574 blur ~140px
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.72, -0.92),
                  radius: 1.35,
                  colors: [
                    AppColors.goldBlur.withValues(alpha: 0.42 * layerStrength),
                    AppColors.goldBlur.withValues(alpha: 0.14 * layerStrength),
                    AppColors.goldBlur.withValues(alpha: 0.04 * layerStrength),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.28, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // Lavender wash — React: bottom-1/4 left-1/4, #b899d4 blur ~120px
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.82, 0.78),
                  radius: 1.25,
                  colors: [
                    AppColors.purpleBlur.withValues(alpha: 0.38 * layerStrength),
                    AppColors.purpleBlur.withValues(alpha: 0.12 * layerStrength),
                    AppColors.purpleBlur.withValues(alpha: 0.035 * layerStrength),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.52, 1.0],
                ),
              ),
            ),
          ),
          // Layout.tsx dark-only extra glow (subtle); keeps dark mode from feeling flat
          if (isDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.5, -0.5),
                    radius: 1.5,
                    colors: [
                      AppColors.goldBlur.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          // Subtle fabric weave — same SVG idea as Layout/Home, opacity ~0.015
          Positioned.fill(
            child: CustomPaint(
              painter: _DotTexturePainter(
                color: AppColors.primary.withValues(alpha: 0.018),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Repeating 100×100 tile with dots at (2,2) and (50,50) like the web SVG.
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
