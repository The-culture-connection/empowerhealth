import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../emotional_support/emotional_support_navigation.dart';
import '../immediate_support/immediate_support_navigation.dart';
import '../resources/open_app_resource.dart';
import 'assistant_safety.dart';

/// Action-first safety card shown right under a message that mentions
/// emergency warning signs or thoughts of self-harm. It appears before the
/// AI reply so the next step never depends on the model.
class AssistantSafetyCard extends StatelessWidget {
  const AssistantSafetyCard({super.key, required this.level});

  final AssistantSafetyLevel level;

  @override
  Widget build(BuildContext context) {
    final crisis = level == AssistantSafetyLevel.mentalHealthCrisis;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: HearthCard(
          borderColor: AppTheme.brandPurple,
          borderWidth: 1.5,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                crisis
                    ? 'You deserve support right now'
                    : 'These can be emergency warning signs',
                style: hearthCardTitleStyle,
              ),
              const SizedBox(height: 6),
              Text(
                crisis
                    ? 'If you are thinking about ending your life or hurting '
                        'yourself or your baby, please reach out now. You are '
                        'not alone, and help is free and confidential. If you '
                        'are in danger right now, call 911.'
                    : 'If you have these symptoms now, during pregnancy or '
                        'after birth, do not wait for your next appointment. '
                        'Call 911, or go to labor and delivery or the '
                        'emergency room now. Tell them if you are pregnant or '
                        'when you gave birth.',
                style: hearthCardBodyStyle.copyWith(color: AppTheme.ink),
              ),
              const SizedBox(height: 12),
              if (crisis) ...[
                HearthButton.primary(
                  label: 'Call 988',
                  icon: Icons.call_outlined,
                  onPressed: () =>
                      launchCrisis988(context: context, action: 'call'),
                ),
                const SizedBox(height: 8),
                HearthButton.secondary(
                  label: 'Text 988',
                  icon: Icons.sms_outlined,
                  onPressed: () =>
                      launchCrisis988(context: context, action: 'text'),
                ),
                const SizedBox(height: 8),
                HearthButton.secondary(
                  label: 'Maternal Mental Health Hotline',
                  icon: Icons.support_agent_outlined,
                  onPressed: () => launchAppExternalPhone(
                    context,
                    'tel:+18338526262',
                  ),
                ),
                const SizedBox(height: 8),
                HearthButton.emergency(
                  label: 'Call 911',
                  icon: Icons.emergency_outlined,
                  onPressed: () => launchAppExternalPhone(context, 'tel:911'),
                ),
              ] else ...[
                HearthButton.emergency(
                  label: 'Call 911',
                  icon: Icons.emergency_outlined,
                  onPressed: () => launchAppExternalPhone(context, 'tel:911'),
                ),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: HearthButton.text(
                  label: 'More support options',
                  chevron: true,
                  onPressed: () =>
                      openImmediateSupport(context, entrySource: 'assistant_safety'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
