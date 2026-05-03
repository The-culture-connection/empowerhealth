import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderLight.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4A574),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Question ${currentIndex + 1} of $totalNeeds',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          needLabel,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Did you get what you needed?',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.borderLight,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (currentIndex + 1) / totalNeeds,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.brandPurple,
                    Color(0xFFD4A574),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        child ??
            NeedOutcomeQuestionList(
              options: accessOptions,
              onSelect: onSelectOption,
            ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              side: BorderSide(color: AppTheme.borderLight.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Back'),
          ),
        ),
      ],
    );
  }
}
