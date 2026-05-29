import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEBE4F3),
            AppTheme.surfaceCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.brandPurple.withValues(alpha: 0.25),
        ),
        boxShadow: AppTheme.shadowSoft(opacity: 0.1, blur: 22, y: 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Talk to someone now',
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can connect with a trained counselor for free and confidential support. This is the 988 Suicide & Crisis Lifeline — not EmpowerHealth Watch.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _CrisisButton(
            label: 'Call 988',
            icon: Icons.phone_in_talk_outlined,
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
    return Material(
      color: outlined ? const Color(0xFFF5F0F8) : AppTheme.brandPurple,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: outlined ? AppTheme.brandPurple : AppTheme.brandWhite,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: outlined ? AppTheme.textPrimary : AppTheme.brandWhite,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: outlined ? AppTheme.textMuted : AppTheme.brandWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
