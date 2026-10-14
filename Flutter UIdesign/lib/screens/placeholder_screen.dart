import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (context.canPop())
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          if (context.canPop()) const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: fg,
              height: 1.25,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 15, color: muted, fontWeight: FontWeight.w300),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'This screen mirrors a route from the React app. Replace with full Flutter UI when you wire data and logic.',
            style: TextStyle(fontSize: 15, height: 1.5, color: muted, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
}
