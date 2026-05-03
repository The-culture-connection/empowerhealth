import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';

/// Free text when the user selects **Other** on the needs checklist (research: `need_other_text`).
class NeedOtherTextField extends StatelessWidget {
  const NeedOtherTextField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What kind of support?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.brandPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A few words help the research team understand your “Other” need.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: 'e.g., housing, legal aid, dental…',
            filled: true,
            fillColor: AppTheme.backgroundWarm,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.borderLight.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.brandPurple, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
