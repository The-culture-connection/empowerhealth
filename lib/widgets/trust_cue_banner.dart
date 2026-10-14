import 'package:flutter/material.dart';

import '../design_system/hearth.dart';

/// Visible privacy / trust cue for screens that show sensitive health or identity data.
class TrustCueBanner extends StatelessWidget {
  final String message;
  final String? subMessage;
  final EdgeInsetsGeometry padding;

  const TrustCueBanner({
    super.key,
    this.message = 'Your information stays private and secure.',
    this.subMessage,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final hasSub = subMessage != null && subMessage!.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: HearthNote(
        icon: Icons.lock_outline,
        padding: padding,
        // A lone line reads as body text; with a second line it becomes the title.
        title: hasSub ? message : null,
        text: hasSub ? subMessage : message,
      ),
    );
  }
}
