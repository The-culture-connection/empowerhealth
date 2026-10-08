import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

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
          padding: const EdgeInsets.only(bottom: 10),
          // A tap answers and moves on, so the rows carry no radio control.
          child: HearthCard(
            onTap: () => onSelect(option['value']!),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                option['label']!,
                style: const TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 15,
                  height: 22 / 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
