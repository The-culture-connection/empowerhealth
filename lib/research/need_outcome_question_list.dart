import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';

/// Answer options for “Did you get what you needed?” (care access step).
class NeedOutcomeQuestionList extends StatelessWidget {
  const NeedOutcomeQuestionList({
    super.key,
    required this.options,
    required this.onSelect,
  });

  final List<Map<String, String>> options;
  final void Function(String value) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onSelect(option['value']!),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.shadowSoft(opacity: 0.08, blur: 20, y: 5),
                border: Border.all(
                  color: AppTheme.borderLight.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                option['label']!,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
