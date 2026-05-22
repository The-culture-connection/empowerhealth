import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
import '../../emotional_support/emotional_support_navigation.dart';
import '../../resources/open_app_resource.dart';
import '../pregnancy_loss_service.dart';

/// External 988 + PSI resources — gentle, not alarming.
class PregnancyLossCrisisResourcesCard extends StatelessWidget {
  const PregnancyLossCrisisResourcesCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE8E0F0).withValues(alpha: 0.55),
        ),
        boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 18, y: 5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Talk to someone now',
            style: TextStyle(
              fontSize: compact ? 16 : 17,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can connect with a trained counselor for free and confidential support. These are external resources — not counselors inside this app.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _CrisisButton(
            label: 'Call 988',
            icon: Icons.phone_in_talk_outlined,
            onTap: () async {
              await PregnancyLossService.instance.log988Tapped('call');
              await launchCrisis988(context: context, action: 'call');
            },
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () async {
              await PregnancyLossService.instance
                  .logResourceOpened('postpartum_psi');
              await openAppResourceById(context, 'postpartum_psi');
            },
            child: Text(
              'Postpartum Support International resources',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.brandPurple,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Material(
      color: const Color(0xFFF5F0F8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.brandPurple),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(Icons.open_in_new_rounded,
                  size: 16, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
