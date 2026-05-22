import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../models/user_profile.dart';
import '../resources/open_app_resource.dart';
import 'pregnancy_loss_navigation.dart';
import 'pregnancy_loss_service.dart';
import 'widgets/pregnancy_loss_crisis_resources.dart';

/// Navigation-focused home when [UserProfile.isInPregnancyLossMode].
class PregnancyLossHomeContent extends StatefulWidget {
  const PregnancyLossHomeContent({
    super.key,
    required this.profile,
    this.showWelcome = true,
  });

  final UserProfile profile;
  final bool showWelcome;

  @override
  State<PregnancyLossHomeContent> createState() =>
      _PregnancyLossHomeContentState();
}

class _PregnancyLossHomeContentState extends State<PregnancyLossHomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PregnancyLossService.instance.logHomeViewed();
    });
  }

  Future<void> _onNavTap(PregnancyLossNavDestination dest) async {
    await PregnancyLossService.instance.logNavTapped(dest.id);
    await dest.onTap(context);
  }

  @override
  Widget build(BuildContext context) {
    final destinations = pregnancyLossNavDestinations(context);
    final quickLinks = pregnancyLossQuickExternalResources();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showWelcome) ...[
          Text(
            'Support after pregnancy loss',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary,
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Go to learning guides, your journal, community, provider search, and trusted external resources.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
        ],
        Text(
          'GO TO',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
            color: AppTheme.brandPurple,
          ),
        ),
        const SizedBox(height: 12),
        ...destinations.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NavTile(
              destination: d,
              onTap: () => _onNavTap(d),
              emphasized: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'QUICK EXTERNAL LINKS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
            color: AppTheme.brandPurple,
          ),
        ),
        const SizedBox(height: 12),
        ...quickLinks.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ExternalLinkTile(
              title: r.title,
              subtitle: r.phoneDisplay ?? r.description,
              onTap: () async {
                await PregnancyLossService.instance.logResourceOpened(r.id);
                if (r.phoneTelUri != null) {
                  await launchAppExternalPhone(context, r.phoneTelUri!);
                } else {
                  await launchAppExternalUrl(context, r.url);
                }
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ExternalLinkTile(
            title: 'All helpful links',
            subtitle: 'WIC, Medicaid, 211, CDC, and more',
            onTap: () => openPregnancyLossHelpfulLinks(context),
          ),
        ),
        const SizedBox(height: 20),
        const PregnancyLossCrisisResourcesCard(compact: true),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.destination,
    required this.onTap,
    required this.emphasized,
  });

  final PregnancyLossNavDestination destination;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: emphasized
                ? const Color(0xFFEBE4F3)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: emphasized
                  ? AppTheme.brandPurple.withValues(alpha: 0.3)
                  : const Color(0xFFE8E0F0).withValues(alpha: 0.55),
            ),
            boxShadow: emphasized
                ? AppTheme.shadowSoft(opacity: 0.1, blur: 16, y: 4)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE4F3).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  destination.icon,
                  color: AppTheme.brandPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.subtitle,
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
              Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExternalLinkTile extends StatelessWidget {
  const _ExternalLinkTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderLight.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppTheme.brandPurple.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
