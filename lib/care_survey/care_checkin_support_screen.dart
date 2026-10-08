import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../research/need_other_text_field.dart';
import '../immediate_support/widgets/immediate_support_home_card.dart';
import 'care_checkin_support_config.dart';

/// Step 2 — personalized support options grouped by selected care needs.
class CareCheckinSupportScreen extends StatelessWidget {
  const CareCheckinSupportScreen({
    super.key,
    required this.selectedNeedIds,
    required this.otherDetailController,
    required this.onOpenAction,
    required this.onBack,
    required this.onContinue,
    this.isContinueBusy = false,
  });

  final List<String> selectedNeedIds;
  final TextEditingController otherDetailController;
  final void Function(CareSupportAction action) onOpenAction;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool isContinueBusy;

  @override
  Widget build(BuildContext context) {
    final hasNeeds = selectedNeedIds.isNotEmpty;
    final showOtherField = selectedNeedIds.contains('other');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: const ShapeDecoration(
            color: AppTheme.surface,
            shape: StadiumBorder(side: BorderSide(color: AppTheme.borderWarm)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.brandGold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Your support options',
                style: hearthCaptionStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Here’s support based on what you shared',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 24),
        HearthFeatureCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              kCareCheckinReinforcementMessage,
              style: hearthCardBodyStyle.copyWith(color: AppTheme.ink),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!hasNeeds) ...[
          Text(
            'You can explore community, providers, or learning topics anytime from home.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          _SupportTile(
            label: 'Connect with community',
            onTap: () => onOpenAction(
              const CareSupportAction(
                id: 'general_community',
                label: 'Connect with community',
                destination: CareSupportDestination.community,
              ),
            ),
          ),
        ] else
          ...selectedNeedIds.map((needId) {
            final sectionTitle = careCheckinSectionTitleForNeedId(needId);
            final actions = kCareCheckinSupportByNeedId[needId] ?? const [];
            if (sectionTitle == null || actions.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HearthSectionHeading(sectionTitle),
                  const SizedBox(height: 12),
                  if (needId == 'other') ...[
                    NeedOtherTextField(controller: otherDetailController),
                    const SizedBox(height: 10),
                  ],
                  ...actions.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SupportTile(
                        label: action.label,
                        onTap: () => onOpenAction(action),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
        const ImmediateSupportHomeCard(
          entrySource: 'care_checkin',
          compact: true,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: HearthButton.secondary(
                label: 'Back',
                onPressed: onBack,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HearthButton.primary(
                label: 'Continue',
                loading: isContinueBusy,
                onPressed: onContinue,
              ),
            ),
          ],
        ),
        if (showOtherField && !hasNeeds) const SizedBox.shrink(),
      ],
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 15,
                  height: 22 / 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: AppTheme.brandPurple, size: 22),
          ],
        ),
      ),
    );
  }
}
