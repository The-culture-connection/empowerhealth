import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../pregnancy_loss/pregnancy_loss_navigation.dart';
import '../resources/open_app_resource.dart';
import '../widgets/feature_session_scope.dart';
import 'emotional_support_constants.dart';
import 'emotional_support_navigation.dart';
import 'widgets/crisis_988_card.dart';

/// Kind, crisis-first support after the “I’m not doing okay” check-in.
class EmotionalSupportEmergencyHubScreen extends StatelessWidget {
  const EmotionalSupportEmergencyHubScreen({
    super.key,
    required this.selectedOptionIds,
    this.somethingElseText,
  });

  final Set<String> selectedOptionIds;
  final String? somethingElseText;

  @override
  Widget build(BuildContext context) {
    final showCrisis = emotionalSupportShowsCrisisCard(selectedOptionIds);

    return FeatureSessionScope(
      feature: 'emotional-support',
      entrySource: 'emergency_hub',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundWarm,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.chevron_left, color: AppTheme.textMuted),
                    ),
                    Expanded(
                      child: Text(
                        'Support for you',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ValidationBlock(),
                      const SizedBox(height: 20),
                      const Crisis988Card(),
                      const SizedBox(height: 28),
                      Text(
                        'Reach someone now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.brandPurple,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'These are free, confidential external resources — not counselors inside this app.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EmergencyResourceTile(
                        label: 'Maternal mental health hotline',
                        subtitle: 'Call or text for pregnancy & postpartum support',
                        onTap: () => openPregnancyLossMaternalMentalHealthHotline(
                          context,
                        ),
                      ),
                      _EmergencyResourceTile(
                        label: 'Postpartum Support International (PSI)',
                        subtitle: 'Peer support & provider directory',
                        onTap: () => openPregnancyLossPsi(context),
                      ),
                      _EmergencyResourceTile(
                        label: '211 — local help',
                        subtitle: 'Food, housing, transportation, and more',
                        onTap: () => openAppResourceById(context, '211'),
                      ),
                      _EmergencyResourceTile(
                        label: 'All helpful links',
                        subtitle: '988, WIC, SAMHSA, and other trusted resources',
                        onTap: () => openPregnancyLossHelpfulLinks(context),
                      ),
                      if (!showCrisis) ...[
                        const SizedBox(height: 12),
                        const Crisis988Card(compact: true),
                      ],
                      const SizedBox(height: 28),
                      Text(
                        'Take a gentle next step',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.brandPurple,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EmergencyResourceTile(
                        label: 'Private journal check-in',
                        subtitle: 'Write what you feel — only you can see it',
                        onTap: () async => openJournalTab(context),
                      ),
                      _EmergencyResourceTile(
                        label: 'Find mental health support near you',
                        subtitle: 'Counselors, social workers, and clinics',
                        onTap: () => openPostpartumMentalHealthProviders(context),
                      ),
                      if (selectedOptionIds.contains(
                        EmotionalSupportOptionId.somethingElse,
                      ) &&
                          (somethingElseText?.trim().isNotEmpty ?? false)) ...[
                        const SizedBox(height: 20),
                        _EmergencyResourceTile(
                          label: 'What you shared',
                          subtitle: somethingElseText!.trim(),
                          onTap: () {},
                        ),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Done for now',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValidationBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEBE4F3), Color(0xFFFAF8FC)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kEmotionalValidationTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You deserve support right now. These resources can connect you with someone who can listen.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyResourceTile extends StatelessWidget {
  const _EmergencyResourceTile({
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w300,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
