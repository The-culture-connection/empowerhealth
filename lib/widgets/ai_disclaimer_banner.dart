import 'package:flutter/material.dart';

import '../design_system/hearth.dart';

/// AI disclaimer note. Lavender marks AI content in Hearth.
/// Shows: "This tool helps you understand your care. It does not replace your provider."
class AIDisclaimerBanner extends StatelessWidget {
  final String? customMessage;
  final String? customSubMessage;

  const AIDisclaimerBanner({
    super.key,
    this.customMessage,
    this.customSubMessage,
  });

  @override
  Widget build(BuildContext context) {
    final message = customMessage ?? 'This tool helps you understand your care.';
    final subMessage = customSubMessage ?? 'It does not replace your provider.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: HearthNote(
        tone: HearthNoteTone.lavender,
        icon: Icons.info_outline,
        title: message,
        text: subMessage,
      ),
    );
  }
}
