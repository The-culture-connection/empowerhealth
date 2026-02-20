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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purple heart icon in white circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.brandPurple.withOpacity(0.3),
                width: 2,
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
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                if (subMessage.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subMessage,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                      height: 1.4,
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
