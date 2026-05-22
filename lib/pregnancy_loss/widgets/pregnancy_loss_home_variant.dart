import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
import '../../models/user_profile.dart';
import '../pregnancy_loss_constants.dart';
import '../pregnancy_loss_learning_topics.dart';
import '../pregnancy_loss_navigation.dart';
import '../pregnancy_loss_service.dart';
import '../pregnancy_loss_support_hub_screen.dart';
import '../pregnancy_loss_theme.dart';
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
            subtitle: 'Future care questions — only if or when you want them',
            icon: Icons.schedule_outlined,
            onTap: (ctx) => _openTopic(ctx, 'future_when_ready'),
          ),
          const SizedBox(height: 14),
        ],
        if (_shows('learning')) ...[
          _SecondaryCard(
            title: 'Pregnancy loss learning modules',
            subtitle: 'Plain-language guides — no milestone content',
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: PregnancyLossTheme.accentSoft.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: PregnancyLossTheme.borderSoft.withValues(alpha: 0.65),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support after pregnancy loss',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Find emotional support, follow-up care guidance, and questions to ask your provider.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(context),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: PregnancyLossTheme.cardFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: PregnancyLossTheme.borderSoft.withValues(alpha: 0.5),
            ),
            boxShadow: AppTheme.shadowSoft(opacity: 0.05, blur: 14, y: 4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PregnancyLossTheme.accentSoft.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.brandPurple, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
