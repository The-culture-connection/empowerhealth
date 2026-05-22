import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
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
        backgroundColor: AppTheme.backgroundWarm,
        body: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.chevron_left,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        'Helpful links',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: _ResourcesHeroCard(),
                ),
              ),
              for (final cat in categories) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Text(
                      cat.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.1,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      const AIDisclaimerBanner(
                        customMessage: 'These links connect you to trusted outside programs.',
                        customSubMessage:
                            'EmpowerHealth does not provide medical care, WIC enrollment, or crisis counseling directly.',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap a card to open the official website. Use Call when a phone line is listed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w300,
                          height: 1.45,
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

class _ResourcesHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEBE4F3),
            Color(0xFFE6D8ED),
            Color(0xFFFAF8F4),
          ],
        ),
        border: Border.all(color: const Color(0x80E0D3E8)),
        boxShadow: AppTheme.shadowSoft(opacity: 0.1, blur: 24, y: 8),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -24,
            right: -8,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandPurple.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.brandWhite.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.shadowSoft(opacity: 0.08, blur: 12, y: 4),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppTheme.brandPurple,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Support resources',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Trusted national programs for nutrition, local help, mental health, and maternal wellness — curated for your care journey.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                  height: 1.5,
                ),
              ),
            ],
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => launchAppExternalUrl(context, resource.url),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFFEBE4F3)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: highlighted
                  ? AppTheme.brandPurple.withValues(alpha: 0.35)
                  : const Color(0xFFE8E0F0).withValues(alpha: 0.55),
              width: highlighted ? 1.5 : 1,
            ),
            boxShadow: AppTheme.shadowSoft(
              opacity: highlighted ? 0.12 : 0.08,
              blur: highlighted ? 20 : 16,
              y: 4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8E0F0), Color(0xFFEDE7F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: AppTheme.brandPurple, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            resource.description,
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
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 20,
                      color: AppTheme.brandPurple.withValues(alpha: 0.65),
                    ),
                  ],
                ),
                if (hasPhone) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundWarm.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.borderLight.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_in_talk_rounded,
                          size: 18,
                          color: AppTheme.brandPurple.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            resource.phoneDisplay ?? 'Call now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Call'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
