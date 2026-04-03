import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';

/// Mama Approved™ — warm, peer-to-peer styling (no red, no clinical “verified” look).
class MamaApprovedCommunityBadge extends StatelessWidget {
  const MamaApprovedCommunityBadge({
    super.key,
    this.compact = false,
    this.onDarkBackground = false,
    this.showInfoAffordance = false,
  });

  final bool compact;
  final bool onDarkBackground;
  final bool showInfoAffordance;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 14.0 : 15.0;
    final fontSize = compact ? 11.0 : 12.0;
    final padH = compact ? 10.0 : 12.0;
    final padV = compact ? 5.0 : 7.0;

    if (onDarkBackground) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0).withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFFE0C2).withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded,
              size: iconSize,
              color: const Color(0xFFFFF2E8),
            ),
            SizedBox(width: compact ? 4 : 5),
            Text(
              'Mama Approved™',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.brandWhite.withOpacity(0.95),
                letterSpacing: 0.15,
              ),
            ),
            if (showInfoAffordance) ...[
              SizedBox(width: compact ? 3 : 4),
              Icon(
                Icons.info_outline,
                size: compact ? 12 : 14,
                color: AppTheme.brandWhite.withOpacity(0.88),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF6ED),
            Color(0xFFF3E8FF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8D4C0).withOpacity(0.95),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B6914).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_rounded,
            size: iconSize,
            color: const Color(0xFF7D4E9E),
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            'Mama Approved™',
            style: TextStyle(
              fontSize: fontSize,
              color: const Color(0xFF5C3D6E),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
