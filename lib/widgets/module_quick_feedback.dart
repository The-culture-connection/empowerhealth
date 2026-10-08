import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../services/qualitative_survey_service.dart';

/// A single tappable feedback option (icon + label + numeric score).
class QuickFeedbackOption {
  final IconData icon;
  final String label;

  /// 1–3 score stored alongside the response (higher = more positive).
  final int score;

  const QuickFeedbackOption({
    required this.icon,
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
    this.moduleTitle,
    this.onSubmitted,
  });

  /// Feature key used for storage/analytics (e.g. `learning-modules`).
  final String feature;
  final String prompt;
  final List<QuickFeedbackOption> options;
  final String? sourceId;

  /// Human-readable title stored on the `ModuleFeedback` record so it is
  /// identifiable in the admin dashboard's module-feedback report.
  final String? moduleTitle;

  /// Called once the user picks an option and it saves — used to coordinate
  /// with the on-exit prompt so a user is never asked twice.
  final VoidCallback? onSubmitted;

  /// "Did this help?" variant — for learning modules.
  factory ModuleQuickFeedback.didThisHelp({
    Key? key,
    required String feature,
    String? sourceId,
    String? moduleTitle,
    VoidCallback? onSubmitted,
  }) {
    return ModuleQuickFeedback(
      key: key,
      feature: feature,
      sourceId: sourceId,
      moduleTitle: moduleTitle,
      onSubmitted: onSubmitted,
      prompt: 'Did this help?',
      options: const [
        QuickFeedbackOption(
          icon: Icons.favorite_border,
          label: 'I understand it better now',
          score: 3,
        ),
        QuickFeedbackOption(
          icon: Icons.eco_outlined,
          label: 'It helped a little',
          score: 2,
        ),
        QuickFeedbackOption(
          icon: Icons.cloud_outlined,
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
    String? moduleTitle,
    VoidCallback? onSubmitted,
  }) {
    return ModuleQuickFeedback(
      key: key,
      feature: feature,
      sourceId: sourceId,
      moduleTitle: moduleTitle,
      onSubmitted: onSubmitted,
      prompt: 'How do you feel now?',
      options: const [
        QuickFeedbackOption(
          icon: Icons.wb_sunny_outlined,
          label: 'I feel more prepared',
          score: 3,
        ),
        QuickFeedbackOption(
          icon: Icons.eco_outlined,
          label: 'A little more prepared',
          score: 2,
        ),
        QuickFeedbackOption(
          icon: Icons.cloud_outlined,
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

      // Also record in `ModuleFeedback` so the admin dashboard's module-feedback
      // report picks up this response (it reads understanding / next-steps /
      // confidence ratings from that collection).
      if (userId != null) {
        await FirebaseFirestore.instance.collection('ModuleFeedback').add({
          'userId': userId,
          'moduleTitle': widget.moduleTitle ?? widget.sourceId ?? widget.feature,
          'taskId': widget.sourceId,
          'understandingRating': option.score,
          'nextStepsRating': option.score,
          'confidenceRating': option.score,
          'feedbackType': 'quick_emoji',
          'promptVariant': widget.prompt,
          'selectedLabel': option.label,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

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
    widget.onSubmitted?.call();
  }

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      color: AppTheme.tintWarm,
      borderColor: null,
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        width: double.infinity,
        child: _selectedScore != null
            ? const Row(
                children: [
                  Icon(Icons.favorite_border, size: 20, color: AppTheme.brandPurple),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thank you! Your feedback helps us make this clearer.',
                      style: TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 14,
                        height: 21 / 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.prompt, style: hearthCardTitleStyle),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.options
                        .map((o) => _OptionChip(option: o, onTap: () => _select(o)))
                        .toList(),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Bottom sheet shown when a user leaves a learning module — asks BOTH quick
/// questions ("Did this help?" and "How do you feel now?"). Answers save to the
/// `ModuleFeedback` collection (admin dashboard report). The user can answer
/// either/both and tap Done, or Skip.
Future<void> showModuleExitFeedbackSheet(
  BuildContext context, {
  required String feature,
  String? sourceId,
  String? moduleTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;
      return Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: AppTheme.ground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          32 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: HearthSheetHandle()),
              const SizedBox(height: 16),
              Text(
                'Before you go, a quick check-in\u00A0',
                style: Theme.of(sheetContext).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              ModuleQuickFeedback.didThisHelp(
                feature: feature,
                sourceId: sourceId,
                moduleTitle: moduleTitle,
              ),
              const SizedBox(height: 16),
              ModuleQuickFeedback.howDoYouFeel(
                feature: feature,
                sourceId: sourceId,
                moduleTitle: moduleTitle,
              ),
              const SizedBox(height: 16),
              HearthButton.primary(
                label: 'Done',
                onPressed: () => Navigator.of(sheetContext).maybePop(),
              ),
              const SizedBox(height: 4),
              Center(
                child: HearthButton.text(
                  label: 'Skip',
                  onPressed: () => Navigator.of(sheetContext).maybePop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows the quick feedback as a bottom sheet — used to prompt the user right
/// as they leave a learning module / planning tool ("module completion").
/// Auto-dismisses shortly after a response so it never blocks navigation.
Future<void> showModuleFeedbackSheet(
  BuildContext context, {
  required String feature,
  String? sourceId,
  String? moduleTitle,
  bool planning = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      void closeSoon() {
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (Navigator.of(sheetContext).canPop()) {
            Navigator.of(sheetContext).pop();
          }
        });
      }

      final feedback = planning
          ? ModuleQuickFeedback.howDoYouFeel(
              feature: feature,
              sourceId: sourceId,
              moduleTitle: moduleTitle,
              onSubmitted: closeSoon,
            )
          : ModuleQuickFeedback.didThisHelp(
              feature: feature,
              sourceId: sourceId,
              moduleTitle: moduleTitle,
              onSubmitted: closeSoon,
            );

      return Container(
        decoration: const BoxDecoration(
          color: AppTheme.ground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          32 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: HearthSheetHandle()),
            const SizedBox(height: 16),
            feedback,
            const SizedBox(height: 8),
            Center(
              child: HearthButton.text(
                label: 'Not now',
                onPressed: () => Navigator.of(sheetContext).maybePop(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.option, required this.onTap});

  final QuickFeedbackOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      shape: const StadiumBorder(side: BorderSide(color: AppTheme.borderWarm)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(option.icon, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    option.label,
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
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
