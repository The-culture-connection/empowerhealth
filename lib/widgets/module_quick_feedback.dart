import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../services/qualitative_survey_service.dart';

/// A single tappable feedback option (emoji + label + numeric score).
class QuickFeedbackOption {
  final String emoji;
  final String label;

  /// 1–3 score stored alongside the response (higher = more positive).
  final int score;

  const QuickFeedbackOption({
    required this.emoji,
    required this.label,
    required this.score,
  });
}

/// Lightweight inline feedback prompt shown immediately after a learning module
/// or care-planning tool, so it isn't overlooked at the bottom of the page.
///
/// Use [ModuleQuickFeedback.didThisHelp] after learning modules, or
/// [ModuleQuickFeedback.howDoYouFeel] after care planning / birth planning /
/// checklists.
class ModuleQuickFeedback extends StatefulWidget {
  const ModuleQuickFeedback({
    super.key,
    required this.feature,
    required this.prompt,
    required this.options,
    this.sourceId,
  });

  /// Feature key used for storage/analytics (e.g. `learning-modules`).
  final String feature;
  final String prompt;
  final List<QuickFeedbackOption> options;
  final String? sourceId;

  /// "Did this help?" variant — for learning modules.
  factory ModuleQuickFeedback.didThisHelp({
    Key? key,
    required String feature,
    String? sourceId,
  }) {
    return ModuleQuickFeedback(
      key: key,
      feature: feature,
      sourceId: sourceId,
      prompt: 'Did this help?',
      options: const [
        QuickFeedbackOption(
          emoji: '💜',
          label: 'I understand it better now',
          score: 3,
        ),
        QuickFeedbackOption(
          emoji: '🙂',
          label: 'It helped a little',
          score: 2,
        ),
        QuickFeedbackOption(
          emoji: '😕',
          label: 'I still have questions',
          score: 1,
        ),
      ],
    );
  }

  /// "How do you feel now?" variant — for care planning, birth planning,
  /// or checklists.
  factory ModuleQuickFeedback.howDoYouFeel({
    Key? key,
    required String feature,
    String? sourceId,
  }) {
    return ModuleQuickFeedback(
      key: key,
      feature: feature,
      sourceId: sourceId,
      prompt: 'How do you feel now?',
      options: const [
        QuickFeedbackOption(
          emoji: '💪',
          label: 'I feel more prepared',
          score: 3,
        ),
        QuickFeedbackOption(
          emoji: '🙂',
          label: 'A little more prepared',
          score: 2,
        ),
        QuickFeedbackOption(
          emoji: '😕',
          label: 'Still unsure',
          score: 1,
        ),
      ],
    );
  }

  @override
  State<ModuleQuickFeedback> createState() => _ModuleQuickFeedbackState();
}

class _ModuleQuickFeedbackState extends State<ModuleQuickFeedback> {
  final QualitativeSurveyService _surveyService = QualitativeSurveyService();
  final DatabaseService _databaseService = DatabaseService();
  final AnalyticsService _analytics = AnalyticsService();

  int? _selectedScore;
  bool _submitting = false;

  Future<void> _select(QuickFeedbackOption option) async {
    if (_submitting || _selectedScore != null) return;
    setState(() {
      _selectedScore = option.score;
      _submitting = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final profile =
          userId == null ? null : await _databaseService.getUserProfile(userId);

      await _surveyService.saveQualitativeSurvey(
        feature: widget.feature,
        questions: [
          {
            'question': widget.prompt,
            'answer': option.score,
            'answerLabel': option.label,
          },
        ],
        userProfile: profile,
        sourceId: widget.sourceId,
      );

      if (widget.feature == 'learning-modules') {
        await _analytics.logLearningModuleSurveySubmitted(
          surveyContext: 'quick_feedback',
          moduleId: widget.sourceId ?? 'unknown',
          averageRating: option.score,
          userProfile: profile,
        );
      }
    } catch (_) {
      // Non-fatal — keep the thank-you state; feedback is best-effort.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEBE4F3), Color(0xFFF5F0FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.brandPurple.withValues(alpha: 0.18),
        ),
      ),
      child: _selectedScore != null
          ? Row(
              children: [
                const Text('💜', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thank you — your feedback helps us make this clearer.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.prompt,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.options
                      .map((o) => _OptionChip(option: o, onTap: () => _select(o)))
                      .toList(),
                ),
              ],
            ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.option, required this.onTap});

  final QuickFeedbackOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.brandWhite.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
