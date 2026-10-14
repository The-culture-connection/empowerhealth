import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';
import '../emotional_support_navigation.dart';

/// Gentle 988 crisis support — external resources only.
class Crisis988Card extends StatelessWidget {
  const Crisis988Card({
    super.key,
    this.compact = false,
    this.on988Action,
  });

  final bool compact;
  final void Function(String action)? on988Action;

  Future<void> _launch(BuildContext context, String action) async {
    on988Action?.call(action);
    await launchCrisis988(context: context, action: action);
  }

  @override
  Widget build(BuildContext context) {
    // Purple outline marks this as the one place to reach a person; never red.
    return HearthCard(
      borderColor: AppTheme.brandPurple,
      borderWidth: 1.5,
      padding: EdgeInsets.all(compact ? 18 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Talk to someone now',
            style: hearthFeatureTitleStyle(),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can connect with a trained counselor for free and confidential support. This is the 988 Suicide & Crisis Lifeline, not EmpowerHealth Watch.',
            style: hearthCardBodyStyle,
          ),
          const SizedBox(height: 16),
          _CrisisButton(
            label: 'Call 988',
            icon: Icons.phone_outlined,
            onTap: () => _launch(context, 'call'),
          ),
          const SizedBox(height: 10),
          _CrisisButton(
            label: 'Text 988',
            icon: Icons.sms_outlined,
            outlined: true,
            onTap: () => _launch(context, 'text'),
          ),
          const SizedBox(height: 10),
          _CrisisButton(
            label: 'Chat with 988',
            icon: Icons.chat_bubble_outline,
            outlined: true,
            onTap: () => _launch(context, 'chat'),
          ),
        ],
      ),
    );
  }
}

class _CrisisButton extends StatelessWidget {
  const _CrisisButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    // Label sits left with an external-link mark on the right, so the row
    // reads as "leaves the app" rather than a centred action.
    final content = Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        const Icon(Icons.open_in_new, size: 16),
      ],
    );
    const padding = EdgeInsets.symmetric(horizontal: 20);
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(padding: padding),
              child: content,
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(padding: padding),
              child: content,
            ),
    );
  }
}
