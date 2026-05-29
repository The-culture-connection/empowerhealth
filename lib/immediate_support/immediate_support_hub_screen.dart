import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../emotional_support/widgets/crisis_988_card.dart';
import '../widgets/feature_session_scope.dart';
import 'immediate_support_constants.dart';
import 'immediate_support_content.dart';
import 'immediate_support_service.dart';

/// Personalized modular support hub — selections stay in-session only.
class ImmediateSupportHubScreen extends StatefulWidget {
  const ImmediateSupportHubScreen({
    super.key,
    required this.selectedOptionIds,
    this.somethingElseText,
  });

  final Set<String> selectedOptionIds;
  final String? somethingElseText;

  @override
  State<ImmediateSupportHubScreen> createState() =>
      _ImmediateSupportHubScreenState();
}

class _ImmediateSupportHubScreenState extends State<ImmediateSupportHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ImmediateSupportService.instance.logHubViewed(
        selectionCount: widget.selectedOptionIds.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = immediateSupportSectionsFor(widget.selectedOptionIds);
    final show988First = widget.selectedOptionIds.isEmpty ||
        widget.selectedOptionIds.contains(ImmediateSupportOptionId.emotional);

    return FeatureSessionScope(
      feature: 'immediate-support',
      entrySource: 'support_hub',
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4FA),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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
                      Text(
                        'We\'re here with you 💜',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        kImmediateSupportDisclaimer,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                          height: 1.5,
                        ),
                      ),
                      if (show988First) ...[
                        const SizedBox(height: 24),
                        _External988Block(),
                      ],
                      ...sections.map(
                        (section) => _SupportSection(
                          config: section,
                          somethingElseText: section.optionId ==
                                  ImmediateSupportOptionId.somethingElse
                              ? widget.somethingElseText
                              : null,
                          show988InSection: section.prioritize988 && !show988First,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SafetyBlock(),
                      const SizedBox(height: 16),
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

class _External988Block extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kImmediateSupport988Disclaimer,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Crisis988Card(
          on988Action: (action) =>
              ImmediateSupportService.instance.log988Tapped(action),
        ),
      ],
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection({
    required this.config,
    this.somethingElseText,
    this.show988InSection = false,
  });

  final ImmediateSupportSectionConfig config;
  final String? somethingElseText;
  final bool show988InSection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.headline,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.brandPurple,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEBE4F3).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              config.supportMessage,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w300,
                height: 1.45,
              ),
            ),
          ),
          if (show988InSection) ...[
            const SizedBox(height: 16),
            _External988Block(),
          ],
          const SizedBox(height: 14),
          ...config.bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.brandPurple.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (somethingElseText != null &&
              somethingElseText!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.borderLight.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                somethingElseText!.trim(),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w300,
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ...config.tiles.map(
            (tile) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () async {
                    await ImmediateSupportService.instance
                        .logResourceOpened(tile.id);
                    if (context.mounted) await tile.onTap(context);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tile.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tile.subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w300,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppTheme.textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kImmediateSupportSafetyGuidance,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            kImmediateSupportEmotionalSafetyGuidance,
            style: TextStyle(
              fontSize: 13,
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
