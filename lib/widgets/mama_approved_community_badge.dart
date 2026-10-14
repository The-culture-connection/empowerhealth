import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

/// Mama Approved™ — gold Hearth tag with ink text (no red, no clinical “verified” look).
class MamaApprovedCommunityBadge extends StatelessWidget {
  const MamaApprovedCommunityBadge({
    super.key,
    this.compact = false,
    this.onDarkBackground = false,
    this.showInfoAffordance = false,
  });

  final bool compact;

  /// Gold already reads on purple, so the tag looks the same on dark cards.
  final bool onDarkBackground;
  final bool showInfoAffordance;

  @override
  Widget build(BuildContext context) {
    const tag = HearthTag.mamaApproved('Mama Approved™');
    if (!showInfoAffordance) return tag;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        tag,
        const SizedBox(width: 4),
        Icon(
          Icons.info_outline,
          size: compact ? 14 : 16,
          color: onDarkBackground ? AppTheme.onPurple : AppTheme.textSecondary,
        ),
      ],
    );
  }
}
