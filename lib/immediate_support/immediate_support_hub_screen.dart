import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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
        backgroundColor: AppTheme.ground,
        body: SafeArea(
          child: Column(
            children: [
              HearthPushedHeader(
                onBack: () => Navigator.pop(context),
                backLabel: 'Support for you',
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We\'re here with you',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      _DisclaimerText(),
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
                      const SizedBox(height: 18),
                      _SafetyBlock(),
                      const SizedBox(height: 16),
                      Center(
                        child: HearthButton.text(
                          label: 'Done for now',
                          onPressed: () => Navigator.pop(context),
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

/// The disclaimer with its "does not provide" sentence in bold, so the limit
/// of the service is the part that stands out.
class _DisclaimerText extends StatelessWidget {
  static const _emphasis = 'EmpowerHealth Watch does not provide';

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge;
    const text = kImmediateSupportDisclaimer;
    final start = text.indexOf(_emphasis);
    if (start < 0) return Text(text, style: base);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ],
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
        const Text(
          kImmediateSupport988Disclaimer,
          style: hearthCardBodyStyle,
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
          HearthSectionHeading(config.headline),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: HearthFeatureCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Text(
                config.supportMessage,
                style: hearthFeatureTitleStyle().copyWith(height: 26 / 19),
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
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.brandPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(b, style: hearthCardBodyStyle),
                  ),
                ],
              ),
            ),
          ),
          if (somethingElseText != null &&
              somethingElseText!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            HearthCard(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  somethingElseText!.trim(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppTheme.ink),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          ...config.tiles.map(
            (tile) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HearthCard(
                onTap: () async {
                  await ImmediateSupportService.instance
                      .logResourceOpened(tile.id);
                  if (context.mounted) await tile.onTap(context);
                },
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
                          Text(tile.label, style: hearthCardTitleStyle),
                          const SizedBox(height: 4),
                          Text(tile.subtitle, style: hearthCaptionStyle),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.brandPurple,
                      size: 20,
                    ),
                  ],
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
    final style = hearthCardBodyStyle.copyWith(color: AppTheme.ink);
    return SizedBox(
      width: double.infinity,
      child: HearthNote(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kImmediateSupportSafetyGuidance, style: style),
            const SizedBox(height: 10),
            Text(kImmediateSupportEmotionalSafetyGuidance, style: style),
          ],
        ),
      ),
    );
  }
}
