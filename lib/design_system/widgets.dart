import 'package:flutter/material.dart';
import 'theme.dart';

class DS {
  // Gap helpers
  static const gapS = SizedBox(height: AppTheme.spacingS);
  static const gapM = SizedBox(height: AppTheme.spacingM);
  static const gapL = SizedBox(height: AppTheme.spacingL);

  // Branded CTA
  static Widget cta(String label, {VoidCallback? onPressed, IconData? icon}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
    );
  }

  // Secondary button
  static Widget secondary(String label, {VoidCallback? onPressed}) =>
      OutlinedButton(onPressed: onPressed, child: Text(label));

  // Section card
  static Widget section({required String title, required Widget child, Widget? trailing}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: ThemeData.light().textTheme.titleMedium)),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            child,
          ],
        ),
      ),
    );
  }
}
