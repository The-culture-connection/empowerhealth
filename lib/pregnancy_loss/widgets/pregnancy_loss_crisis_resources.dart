import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';
import '../../emotional_support/emotional_support_navigation.dart';
import '../../resources/open_app_resource.dart';
import '../pregnancy_loss_service.dart';

/// External 988 + PSI resources — gentle, not alarming.
class PregnancyLossCrisisResourcesCard extends StatelessWidget {
  const PregnancyLossCrisisResourcesCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: HearthCard(
        padding: EdgeInsets.all(compact ? 18 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Talk to someone now',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'You can connect with a trained counselor for free and confidential support. These are external resources, not counselors inside this app.',
              style: hearthCardBodyStyle,
            ),
            const SizedBox(height: 16),
            _CrisisButton(
              label: 'Call 988',
              icon: Icons.phone_outlined,
              onTap: () async {
                await PregnancyLossService.instance.log988Tapped('call');
                await launchCrisis988(context: context, action: 'call');
              },
            ),
            const SizedBox(height: 10),
            _CrisisButton(
              label: 'Text 988',
              icon: Icons.sms_outlined,
              onTap: () async {
                await PregnancyLossService.instance.log988Tapped('text');
                await launchCrisis988(context: context, action: 'text');
              },
            ),
            const SizedBox(height: 10),
            _CrisisButton(
              label: 'Chat with 988',
              icon: Icons.chat_bubble_outline,
              onTap: () async {
                await PregnancyLossService.instance.log988Tapped('chat');
                await launchCrisis988(context: context, action: 'chat');
              },
            ),
            const SizedBox(height: 8),
            HearthButton.text(
              label: 'Postpartum Support International resources',
              onPressed: () async {
                await PregnancyLossService.instance
                    .logResourceOpened('postpartum_psi');
                await openAppResourceById(context, 'postpartum_psi');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft cream row: loss mode keeps 988 calm, never red.
class _CrisisButton extends StatelessWidget {
  const _CrisisButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      onTap: onTap,
      color: AppTheme.ground,
      radius: BorderRadius.circular(AppTheme.fieldRadius),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.brandPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
            ),
            const Icon(Icons.open_in_new, size: 16, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
