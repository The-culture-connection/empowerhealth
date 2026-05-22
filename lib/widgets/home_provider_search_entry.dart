import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';

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
    final iconSize = compact ? 36.0 : 44.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 18);
    final radius = compact ? 16.0 : 20.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: const Color(0xFFE8E0F0).withValues(alpha: 0.5),
            ),
            boxShadow: AppTheme.shadowSoft(
              opacity: compact ? 0.06 : 0.08,
              blur: compact ? 12 : 18,
              y: compact ? 3 : 4,
            ),
          ),
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8E0F0), Color(0xFFD8CFE5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(compact ? 12 : 14),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppTheme.brandPurple,
                    size: compact ? 18 : 22,
                  ),
                ),
                SizedBox(width: compact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: compact ? 18 : 20,
                  color: AppTheme.textMuted.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
