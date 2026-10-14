import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';
import '../immediate_support_navigation.dart';

/// Home entry for the universal immediate support pathway.
class ImmediateSupportHomeCard extends StatelessWidget {
  const ImmediateSupportHomeCard({
    super.key,
    required this.entrySource,
    this.compact = false,
    this.title,
    this.subtitle,
    this.ctaLabel,
    this.quiet = false,
  });

  final String entrySource;
  final bool compact;

  /// Optional copy overrides (e.g. the home "Today's Guidance" card). When
  /// [subtitle] is an empty string the secondary line is hidden to reduce height.
  final String? title;
  final String? subtitle;
  final String? ctaLabel;

  /// Plain surface card with a sans title, for screens that already have a
  /// tint feature card above it (pregnancy-loss Home).
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final titleText = title ?? 'We\'re here with you';
    final subtitleText = subtitle ??
        'Emotional support, guidance, and help with next steps, whenever you need it.';
    final ctaText = ctaLabel ?? 'See support options';
    // The serif title is set looser when it is a long sentence (Home's
    // "Understand your care…" line) so it doesn't feel cramped.
    final titleStyle = quiet
        ? Theme.of(context).textTheme.titleLarge
        : hearthFeatureTitleStyle().copyWith(
            height: subtitleText.isEmpty ? 27 / 19 : 25 / 19,
          );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titleText, style: titleStyle),
        if (subtitleText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(subtitleText, style: hearthCardBodyStyle),
        ],
        SizedBox(height: subtitleText.isEmpty ? 6 : 2),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  ctaText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandPurple,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppTheme.brandPurple,
              ),
            ],
          ),
        ),
      ],
    );
    void open() => openImmediateSupport(context, entrySource: entrySource);
    final padding = EdgeInsets.fromLTRB(
      compact ? 20 : 22,
      compact ? 18 : 22,
      compact ? 20 : 22,
      8,
    );
    if (quiet) {
      return HearthCard(onTap: open, padding: padding, child: content);
    }
    return HearthFeatureCard(onTap: open, padding: padding, child: content);
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
      minVerticalPadding: 12,
      leading: const HearthIconChip(Icons.volunteer_activism_outlined),
      title: const Text(
        'I need support right now',
        style: hearthCardTitleStyle,
      ),
      subtitle: const Text(
        'Emotional support, guidance, and external resources',
        style: hearthCaptionStyle,
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.brandPurple),
      onTap: () => openImmediateSupport(context, entrySource: entrySource),
    );
  }
}
