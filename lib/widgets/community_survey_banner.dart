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

    // Compact, full-width, left-aligned invitation so the feed is visible in
    // the first viewport (even with Bold Text / larger Dynamic Type). The
    // primary CTA opens the provider-experience flow; app feedback is a
    // separate, clearly labeled secondary link.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Help another mama choose care',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                tooltip: 'Dismiss',
                onPressed: () {
                  setState(() => _isDismissed = true);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              'Rate a provider, hospital, or doula you have seen.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w300,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openShareExperience,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppTheme.encouragementGradient,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
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
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          'Share your experience',
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
                TextButton(
                  onPressed: _showSurvey,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Give app feedback',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
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
