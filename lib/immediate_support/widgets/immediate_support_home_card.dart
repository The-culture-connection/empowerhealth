import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
import '../immediate_support_navigation.dart';

/// Home entry for the universal immediate support pathway.
class ImmediateSupportHomeCard extends StatelessWidget {
  const ImmediateSupportHomeCard({
    super.key,
    required this.entrySource,
    this.compact = false,
  });

  final String entrySource;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openImmediateSupport(context, entrySource: entrySource),
        borderRadius: BorderRadius.circular(compact ? 20 : 22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 20 : 22),
            color: const Color(0xFFEBE4F3).withValues(alpha: 0.55),
            border: Border.all(
              color: AppTheme.brandPurple.withValues(alpha: 0.2),
            ),
            boxShadow: AppTheme.shadowSoft(opacity: 0.08, blur: 20, y: 6),
          ),
          padding: EdgeInsets.all(compact ? 18 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We\'re here with you 💜',
                style: TextStyle(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                'Support is available whenever you need it.',
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w300,
                  height: 1.45,
                  color: AppTheme.textMuted,
                ),
              ),
              SizedBox(height: compact ? 14 : 18),
              Text(
                'Need support right now?',
                style: TextStyle(
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Get emotional support, plain-language guidance, and help preparing questions or next steps.',
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w300,
                  height: 1.45,
                  color: AppTheme.textMuted,
                ),
              ),
              SizedBox(height: compact ? 14 : 16),
              Row(
                children: [
                  Text(
                    'See support options',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppTheme.brandPurple.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact list tile for settings, visits, assistant, and care check-in.
class ImmediateSupportEntryTile extends StatelessWidget {
  const ImmediateSupportEntryTile({
    super.key,
    required this.entrySource,
  });

  final String entrySource;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.volunteer_activism_outlined, color: AppTheme.brandPurple),
      title: Text(
        'I need support right now',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w400,
        ),
      ),
      subtitle: Text(
        'Emotional support, guidance, and external resources',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w300,
          fontSize: 13,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
      onTap: () => openImmediateSupport(context, entrySource: entrySource),
    );
  }
}
