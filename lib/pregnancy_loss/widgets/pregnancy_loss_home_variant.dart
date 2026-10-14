import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';
import '../../models/user_profile.dart';
import '../pregnancy_loss_constants.dart';
import '../pregnancy_loss_learning_topics.dart';
import '../pregnancy_loss_navigation.dart';
import '../pregnancy_loss_service.dart';
import '../pregnancy_loss_support_hub_screen.dart';
import 'pregnancy_loss_crisis_resources.dart';

/// Trauma-informed home cards when [UserProfile.isInPregnancyLossMode].
class PregnancyLossHomeVariant extends StatefulWidget {
  const PregnancyLossHomeVariant({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<PregnancyLossHomeVariant> createState() =>
      _PregnancyLossHomeVariantState();
}

class _PregnancyLossHomeVariantState extends State<PregnancyLossHomeVariant> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PregnancyLossService.instance.logHomeViewed();
    });
  }

  List<String> get _visibleCardIds => pregnancyLossVisibleHomeCards(
        widget.profile.pregnancyLossSupportPreferences,
      );

  bool _shows(String id) => _visibleCardIds.contains(id);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrimarySupportCard(
          onTap: () async {
            await PregnancyLossService.instance.logResourceOpened('primary_support');
            if (!context.mounted) return;
            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    PregnancyLossSupportHubScreen(profile: widget.profile),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        if (_shows('emotional')) ...[
          _SecondaryCard(
            title: 'Emotional support',
            subtitle: 'Grief and emotional care at your own pace',
            icon: Icons.favorite_outline,
            onTap: (ctx) => _openTopic(ctx, 'grief_support'),
          ),
          const SizedBox(height: 14),
        ],
        if (_shows('body_care')) ...[
          _SecondaryCard(
            title: 'Follow-up care for my body',
            subtitle: 'Recovery, warning signs, and follow-up visits',
            icon: Icons.healing_outlined,
            onTap: (ctx) => _openTopic(ctx, 'body_after_loss'),
          ),
          const SizedBox(height: 14),
        ],
        if (_shows('provider_questions')) ...[
          _SecondaryCard(
            title: 'Questions to ask my provider',
            subtitle: 'Visit prompts and journal space for your next appointment',
            icon: Icons.checklist_outlined,
            onTap: (ctx) => openPregnancyLossProviderQuestions(ctx),
          ),
          const SizedBox(height: 14),
        ],
        if (_shows('future')) ...[
          _SecondaryCard(
            title: 'Support when I\'m ready',
            subtitle: 'Future care questions, only if or when you want them',
            icon: Icons.schedule_outlined,
            onTap: (ctx) => _openTopic(ctx, 'future_when_ready'),
          ),
          const SizedBox(height: 14),
        ],
        if (_shows('learning')) ...[
          _SecondaryCard(
            title: 'Pregnancy loss learning modules',
            subtitle: 'Plain-language guides, no milestone content',
            icon: Icons.menu_book_outlined,
            onTap: (ctx) => openPregnancyLossLearn(ctx),
          ),
          const SizedBox(height: 14),
        ],
        if (_shows('community')) ...[
          _SecondaryCard(
            title: 'Pregnancy loss community',
            subtitle: 'A gentle space for support and connection',
            icon: Icons.people_outline_rounded,
            onTap: (ctx) async {
              openPregnancyLossCommunity(ctx);
            },
          ),
          const SizedBox(height: 14),
        ],
        if (_shows('crisis')) ...[
          const PregnancyLossCrisisResourcesCard(),
          const SizedBox(height: 14),
        ],
        if (_shows('resources')) ...[
          _SecondaryCard(
            title: 'Practical support and resources',
            subtitle: 'Helpful links and provider search',
            icon: Icons.link_rounded,
            onTap: (ctx) => openPregnancyLossHelpfulLinks(ctx),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _openTopic(BuildContext context, String topicId) async {
    final topic = pregnancyLossTopicById(topicId);
    if (topic == null) return;
    await PregnancyLossService.instance.logModuleOpened(topicId);
    if (context.mounted) {
      openPregnancyLossLearningTopic(context, topic);
    }
  }
}

class _PrimarySupportCard extends StatelessWidget {
  const _PrimarySupportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Warm tint, not purple: loss mode keeps its one feature card quiet.
    return HearthFeatureCard(
      onTap: onTap,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support after pregnancy loss',
            style: hearthFeatureTitleStyle(),
          ),
          const SizedBox(height: 10),
          const Text(
            'Find emotional support, follow-up care guidance, and questions to ask your provider.',
            style: TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 15,
              height: 22 / 15,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const SizedBox(
            height: 44,
            child: Row(
              children: [
                Text(
                  'See support options',
                  style: TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandPurple,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppTheme.brandPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryCard extends StatelessWidget {
  const _SecondaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Future<void> Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    return HearthRowCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onTap(context),
    );
  }
}
