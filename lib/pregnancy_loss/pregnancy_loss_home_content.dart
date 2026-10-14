import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showWelcome) ...[
          Text(
            'Support after pregnancy loss',
            style: textTheme.displayLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Go to learning guides, your journal, community, provider search, and trusted external resources.',
            style: textTheme.bodyLarge?.copyWith(fontSize: 16, height: 23 / 16),
          ),
          const SizedBox(height: 28),
        ],
        const HearthSectionHeading('Go to'),
        const SizedBox(height: 12),
        ...destinations.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HearthRowCard(
              icon: d.icon,
              title: d.title,
              subtitle: d.subtitle,
              onTap: () => _onNavTap(d),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const HearthSectionHeading('Quick external links'),
        const SizedBox(height: 12),
        ...quickLinks.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
          padding: const EdgeInsets.only(bottom: 12),
          child: _ExternalLinkTile(
            title: 'All helpful links',
            subtitle: 'WIC, Medicaid, 211, CDC, and more',
            onTap: () => openPregnancyLossHelpfulLinks(context),
          ),
        ),
        const SizedBox(height: 16),
        const PregnancyLossCrisisResourcesCard(compact: true),
        const SizedBox(height: 40),
      ],
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
    return HearthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.open_in_new,
              size: 20,
              color: AppTheme.brandPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: hearthCardTitleStyle.copyWith(
                    fontSize: 15,
                    height: 22 / 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: hearthCaptionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
