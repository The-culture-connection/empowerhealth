import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';

/// Warm, reassuring AI disclaimer banner matching the design spec
/// Shows: "This tool helps you understand your care. It does not replace your provider."
class AIDisclaimerBanner extends StatelessWidget {
  final String? customMessage;
  final String? customSubMessage;
  
  const AIDisclaimerBanner({
    super.key,
    this.customMessage,
    this.customSubMessage,
  });

  @override
  Widget build(BuildContext context) {
    final message = customMessage ?? 'This tool helps you understand your care.';
    final subMessage = customSubMessage ?? 'It does not replace your provider.';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
        boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 16, y: 3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceInput,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.brandPurple.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.favorite,
              color: AppTheme.brandPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (subMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subMessage,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.textMuted,
                      height: 1.5,
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
