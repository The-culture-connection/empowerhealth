/**
 * Community Survey Banner
 * Dismissible banner on the community screen (encouragement / feedback — gold cues).
 */

import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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

    // Compact, full-width, left-aligned invitation so the feed is visible in
    // the first viewport (even with Bold Text / larger Dynamic Type). The
    // primary CTA opens the provider-experience flow; app feedback is a
    // separate, clearly labeled secondary link.
    return HearthCard(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Help another mama choose care',
                  style: hearthCardTitleStyle,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                tooltip: 'Dismiss',
                onPressed: () {
                  setState(() => _isDismissed = true);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'Rate a provider, hospital, or doula you have seen.',
              style: hearthCardBodyStyle.copyWith(height: 20 / 14),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                // Compact gold pill: the banner is an invitation, so it stays
                // smaller than a full-width 52px action.
                ElevatedButton(
                  onPressed: _openShareExperience,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandGold,
                    foregroundColor: AppTheme.ink,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Share your experience'),
                ),
                TextButton(
                  onPressed: _showSurvey,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: const Text('Give app feedback'),
                ),
              ],
            ),
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
