import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

/// Free text when the user selects **Other** on the needs checklist (research: `need_other_text`).
class NeedOtherTextField extends StatelessWidget {
  const NeedOtherTextField({
    super.key,
    required this.controller,
    this.inCard = false,
  });

  final TextEditingController controller;

  /// Inside a card the field takes the inset fill; on the page it keeps the theme fill.
  final bool inCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What kind of support?',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'A few words help the research team understand your “Other” need.',
          style: hearthCaptionStyle,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: 'e.g., housing, legal aid, dental…',
            fillColor: inCard ? AppTheme.surfaceInset : null,
          ),
        ),
      ],
    );
  }
}
