/**
 * Community Survey Banner
 * Dismissible banner on the community screen (encouragement / feedback — gold cues).
 */

import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../providers/share_provider_experience_screen.dart';
import 'qualitative_survey_dialog.dart';

class CommunitySurveyBanner extends StatefulWidget {
  const CommunitySurveyBanner({super.key});

  @override
  State<CommunitySurveyBanner> createState() => _CommunitySurveyBannerState();
}

class _CommunitySurveyBannerState extends State<CommunitySurveyBanner> {
  bool _isDismissed = false;

  void _showSurvey() {
    showDialog(
      context: context,
      builder: (context) => QualitativeSurveyDialog(
        feature: 'community',
        questions: [
          'This app helped me understand my care.',
          'This app helped me prepare for an appointment.',
          'I found information that was useful to me.',
          'I would recommend this app to another mother.',
        ],
        title: 'Community Feedback',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.borderLight.withOpacity(0.7),
          width: 1,
        ),
        boxShadow: AppTheme.shadowSoft(opacity: 0.07, blur: 18, y: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.feedback_outlined,
                color: AppTheme.brandGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help Another Mama Choose Care',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share your experience with a provider, hospital, doula, or birth team. Your feedback helps other mothers find care where they feel heard, respected, and supported.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                onPressed: () {
                  setState(() => _isDismissed = true);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _showSurvey,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textMuted,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Share app feedback',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openShareExperience,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppTheme.encouragementGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandGold.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(
                        '💜 Share Provider Experience',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openShareExperience() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ShareProviderExperienceScreen(),
      ),
    );
  }
}
