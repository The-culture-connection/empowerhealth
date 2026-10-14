import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../widgets/ai_disclaimer_banner.dart';
import '../widgets/feature_session_scope.dart';
import 'app_external_resources.dart';
import 'open_app_resource.dart';

/// Directory of trusted external links (WIC, 211, maternal mental health, CDC, etc.).
class AppResourcesScreen extends StatelessWidget {
  const AppResourcesScreen({
    super.key,
    this.highlightResourceId,
    this.categoryFilter,
  });

  final String? highlightResourceId;
  final String? categoryFilter;

  @override
  Widget build(BuildContext context) {
    final categories = categoryFilter != null
        ? [categoryFilter!]
        : AppResourceCategory.all;

    return FeatureSessionScope(
      feature: 'app-resources',
      entrySource: 'resources_screen',
      child: Scaffold(
        backgroundColor: AppTheme.ground,
        body: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: HearthPushedHeader(
                  backLabel: 'Helpful links',
                  onBack: () => Navigator.pop(context),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: _ResourcesHeroCard(),
                ),
              ),
              for (final cat in categories) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: HearthSectionHeading(cat),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final resources = appExternalResourcesInCategory(cat);
                        if (index >= resources.length) return null;
                        final resource = resources[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ResourceLinkCard(
                            resource: resource,
                            highlighted: resource.id == highlightResourceId,
                          ),
                        );
                      },
                      childCount: appExternalResourcesInCategory(cat).length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    children: [
                      const AIDisclaimerBanner(
                        customMessage: 'These links connect you to trusted outside programs.',
                        customSubMessage:
                            'EmpowerHealth does not provide medical care, WIC enrollment, or crisis counseling directly.',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap a card to open the official website. Use Call when a phone line is listed.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
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

class _ResourcesHeroCard extends StatelessWidget {
  const _ResourcesHeroCard();

  @override
  Widget build(BuildContext context) {
    return HearthFeatureCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HearthIconChip(Icons.link_rounded, tone: HearthChipTone.surface),
          const SizedBox(height: 16),
          Text(
            'Support resources',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Trusted national programs for nutrition, local help, mental health, and maternal wellness, curated for your care journey.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ResourceLinkCard extends StatelessWidget {
  const _ResourceLinkCard({
    required this.resource,
    required this.highlighted,
  });

  final AppExternalResource resource;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final icon = appResourceIcon(resource);
    final hasPhone =
        resource.phoneTelUri != null && resource.phoneTelUri!.isNotEmpty;

    // A highlighted card (opened from a deep link) uses the selected style.
    return HearthCard(
      onTap: () => launchAppExternalUrl(context, resource.url),
      color: highlighted ? AppTheme.tintWarm : AppTheme.surface,
      borderColor: highlighted ? AppTheme.brandPurple : AppTheme.borderWarm,
      borderWidth: highlighted ? 2 : 1,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HearthIconChip(
                icon,
                tone: highlighted ? HearthChipTone.surface : HearthChipTone.tint,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.title, style: hearthCardTitleStyle),
                    const SizedBox(height: 4),
                    Text(resource.description, style: hearthCaptionStyle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.open_in_new,
                  size: 20,
                  color: AppTheme.brandPurple,
                ),
              ),
            ],
          ),
          if (hasPhone) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.fromLTRB(14, 2, 6, 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceInset,
                borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                border: Border.all(color: AppTheme.borderWarm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: AppTheme.brandPurple,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      resource.phoneDisplay ?? 'Call now',
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      launchAppExternalPhone(
                        context,
                        resource.phoneTelUri!,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.brandPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(44, 44),
                      textStyle: const TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Call'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
