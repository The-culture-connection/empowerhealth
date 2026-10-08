import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

/// Provider search entry — home Understand Your Care or compact Today's Guidance.
class HomeProviderSearchEntry extends StatelessWidget {
  const HomeProviderSearchEntry({
    super.key,
    required this.onTap,
    this.title = 'Find trusted providers near you',
    this.subtitle = 'Search by ZIP, city, and type of care',
    this.compact = false,
  });

  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Row(
        children: [
          HearthIconChip(
            Icons.search,
            size: compact ? 40 : 46,
            iconSize: compact ? 20 : 22,
          ),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: hearthCardTitleStyle),
                const SizedBox(height: 2),
                Text(subtitle, style: hearthCaptionStyle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppTheme.brandPurple,
          ),
        ],
      ),
    );
  }
}
