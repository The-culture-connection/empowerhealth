import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../widgets/feature_session_scope.dart';
import 'emotional_support_constants.dart';
import 'emotional_support_hub_screen.dart';
import 'emotional_support_service.dart';

/// Placeholder pregnancy-loss pathway — saves status for future home personalization.
class EmotionalSupportPregnancyLossScreen extends StatelessWidget {
  const EmotionalSupportPregnancyLossScreen({
    super.key,
    required this.selectedOptionIds,
    this.somethingElseText,
  });

  final Set<String> selectedOptionIds;
  final String? somethingElseText;

  @override
  Widget build(BuildContext context) {
    return FeatureSessionScope(
      feature: 'emotional-support',
      entrySource: 'pregnancy_loss',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundWarm,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.chevron_left, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  'We’re so sorry for your loss 💜',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You’re not alone. We’ll adjust your support experience so it feels more supportive and relevant to where you are right now.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.borderLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coming soon',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...kPregnancyLossFutureTodos.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w300,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await EmotionalSupportService.instance
                          .acknowledgePregnancyLoss();
                      if (!context.mounted) return;
                      final remaining = Set<String>.from(selectedOptionIds)
                        ..remove(EmotionalSupportOptionId.pregnancyLoss);
                      if (remaining.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }
                      Navigator.pushReplacement<void, void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EmotionalSupportHubScreen(
                            selectedOptionIds: remaining,
                            somethingElseText: somethingElseText,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: AppTheme.brandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Continue to support options'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'I’ll come back later',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
