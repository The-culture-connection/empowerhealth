/**
 * Community Survey Banner
 * Dismissible banner at the top of community screen that can be scrolled out of view
 */

import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
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
          'I feel supported by this community.',
          'I feel heard when I share something here.',
          'Reading others\' experiences helped me.',
        ],
        title: 'Community Feedback',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.brandPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.brandPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.feedback_outlined,
            color: AppTheme.brandPurple,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help us improve!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share your experience with the community',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _showSurvey,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.brandPurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Take Survey'),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: AppTheme.textMuted),
            onPressed: () {
              setState(() => _isDismissed = true);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
