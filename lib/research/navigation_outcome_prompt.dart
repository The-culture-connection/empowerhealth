import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'need_outcome_question_list.dart';

/// Wraps the per-need “Did you get what you needed?” research access step.
class NavigationOutcomePrompt extends StatelessWidget {
  const NavigationOutcomePrompt({
    super.key,
    required this.currentIndex,
    required this.totalNeeds,
    required this.needLabel,
    required this.accessOptions,
    required this.onSelectOption,
    required this.onBack,
    this.child,
  });

  final int currentIndex;
  final int totalNeeds;
  final String needLabel;
  final List<Map<String, String>> accessOptions;
  final void Function(String value) onSelectOption;
  final VoidCallback onBack;

  /// Defaults to [NeedOutcomeQuestionList] wiring when null; pass a custom child for tests.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: const ShapeDecoration(
            color: AppTheme.surface,
            shape: StadiumBorder(side: BorderSide(color: AppTheme.borderWarm)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.brandGold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Question ${currentIndex + 1} of $totalNeeds',
                style: hearthCaptionStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          needLabel,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Did you get what you needed?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        // The pill above already says "Question N of M", so the bar has no caption.
        HearthStepProgress(step: currentIndex + 1, total: totalNeeds),
        const SizedBox(height: 24),
        child ??
            NeedOutcomeQuestionList(
              options: accessOptions,
              onSelect: onSelectOption,
            ),
        const SizedBox(height: 24),
        HearthButton.secondary(
          label: 'Back',
          onPressed: onBack,
        ),
      ],
    );
  }
}
