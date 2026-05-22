import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../widgets/feature_session_scope.dart';
import 'emotional_support_constants.dart';
import 'emotional_support_navigation.dart';
import 'widgets/crisis_988_card.dart';

class EmotionalSupportHubScreen extends StatelessWidget {
  const EmotionalSupportHubScreen({
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
      entrySource: 'support_hub',
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
                      if (showCrisis) ...[
                        const SizedBox(height: 20),
                        const Crisis988Card(),
                      ],
                      if (selectedOptionIds
                          .contains(EmotionalSupportOptionId.notMyself)) ...[
                        const SizedBox(height: 28),
                        _PathwaySection(
                          headline: 'You deserve support too 💜',
                          actions: [
                            _SupportTile(
                              label: 'Find postpartum mental health support',
                              subtitle:
                                  'Therapists, counselors, postpartum specialists, support groups',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'ppd_providers',
                                pathwayId: 'ppd',
                                action: () =>
                                    openPostpartumMentalHealthProviders(context),
                              ),
                            ),
                            _SupportTile(
                              label: 'Learn about postpartum emotional changes',
                              subtitle:
                                  'Non-diagnostic, supportive education',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'ppd_learning',
                                pathwayId: 'ppd',
                                action: () => openPpdLearningModule(context),
                              ),
                            ),
                            _SupportTile(
                              label: 'Prepare for a provider conversation',
                              subtitle:
                                  'Journal prompts: feelings, hardest parts, questions',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'ppd_journal',
                                pathwayId: 'ppd',
                                action: () async {
                                  openJournalTab(context);
                                },
                              ),
                            ),
                            _SupportTile(
                              label: 'Community support',
                              subtitle: 'Postpartum & emotional wellness groups',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'ppd_community',
                                pathwayId: 'ppd',
                                action: () async => openCommunityTab(context),
                              ),
                            ),
                            if (!showCrisis) ...[
                              const SizedBox(height: 12),
                              const Crisis988Card(compact: true),
                            ],
                          ],
                        ),
                      ],
                      if (selectedOptionIds
                          .contains(EmotionalSupportOptionId.healthWorry)) ...[
                        const SizedBox(height: 28),
                        _PathwaySection(
                          headline: 'Let’s help you figure out next steps 💜',
                          actions: [
                            _SupportTile(
                              label: 'When to contact a provider',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'health_rights',
                                pathwayId: 'health',
                                action: () async => openRights(context),
                              ),
                            ),
                            _SupportTile(
                              label: 'Prepare for your visit',
                              subtitle: 'Journal prompts for questions & notes',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'health_visit_prep',
                                pathwayId: 'health',
                                action: () async => openJournalTab(context),
                              ),
                            ),
                            _SupportTile(
                              label: 'Care navigation support',
                              subtitle: 'WIC, 211, transportation & helpful links',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'health_navigation',
                                pathwayId: 'health',
                                action: () async =>
                                    openCareNavigationResources(context),
                              ),
                            ),
                            _SupportTile(
                              label: 'Talk through a symptom',
                              subtitle: 'Assistant — educational framing only',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'health_assistant',
                                pathwayId: 'health',
                                action: () async {
                                  openAssistant(
                                    context,
                                    'Help me understand this symptom in plain language. What questions should I ask my provider? When should I seek care?',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (selectedOptionIds.contains(
                        EmotionalSupportOptionId.hardAdjusting,
                      )) ...[
                        const SizedBox(height: 28),
                        _PathwaySection(
                          headline:
                              'A lot of people feel overwhelmed during big life changes 💜',
                          subtext: 'You deserve support while adjusting too.',
                          actions: [
                            _SupportTile(
                              label: 'Emotional normalization & adjustment',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'adjust_learning',
                                pathwayId: 'adjustment',
                                action: () => openAdjustmentLearningModule(context),
                              ),
                            ),
                            _SupportTile(
                              label: 'Take a moment — journal check-in',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'adjust_journal',
                                pathwayId: 'adjustment',
                                action: () async => openJournalTab(context),
                              ),
                            ),
                            _SupportTile(
                              label: 'Support groups & community',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'adjust_community',
                                pathwayId: 'adjustment',
                                action: () async => openCommunityTab(context),
                              ),
                            ),
                            _SupportTile(
                              label: 'What’s normal right now?',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'adjust_journey',
                                pathwayId: 'adjustment',
                                action: () async => openPregnancyJourney(context),
                              ),
                            ),
                            _SupportTile(
                              label: 'Rest & self-care reminders',
                              subtitle: 'Gentle prompts in your journal',
                              onTap: () => openEmotionalSupportResource(
                                context,
                                resourceId: 'adjust_selfcare',
                                pathwayId: 'adjustment',
                                action: () async => openJournalTab(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (selectedOptionIds.contains(
                            EmotionalSupportOptionId.somethingElse,
                          ) &&
                          (somethingElseText?.trim().isNotEmpty ?? false)) ...[
                        const SizedBox(height: 28),
                        _PathwaySection(
                          headline: 'What you shared',
                          actions: [
                            _SupportTile(
                              label: somethingElseText!.trim(),
                              subtitle: 'Saved privately on your profile',
                              onTap: () {},
                            ),
                            _SupportTile(
                              label: 'Connect with community',
                              onTap: () => openCommunityTab(context),
                            ),
                          ],
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
            kEmotionalValidationBody,
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

class _PathwaySection extends StatelessWidget {
  const _PathwaySection({
    required this.headline,
    required this.actions,
    this.subtext,
  });

  final String headline;
  final String? subtext;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.brandPurple,
            height: 1.3,
          ),
        ),
        if (subtext != null) ...[
          const SizedBox(height: 6),
          Text(
            subtext!,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 14),
        ...actions,
      ],
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
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
                          fontWeight: FontWeight.w400,
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
                            height: 1.35,
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
