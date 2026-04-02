import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';

/// Visible privacy / trust cue for screens that show sensitive health or identity data.
class TrustCueBanner extends StatelessWidget {
  final String message;
  final String? subMessage;
  final EdgeInsetsGeometry padding;

  const TrustCueBanner({
    super.key,
    this.message = 'Your information stays private and secure.',
    this.subMessage,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surfaceInput,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, size: 22, color: AppTheme.brandPurple.withOpacity(0.85)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (subMessage != null && subMessage!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
