import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../research/need_other_text_field.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderLight.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4A574),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Your support options',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Here’s support based on what you shared',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF5EEE0), Color(0xFFFAF8F4), Color(0xFFEBE0D6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.45)),
          ),
          child: Text(
            kCareCheckinReinforcementMessage,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!hasNeeds) ...[
          Text(
            'You can explore community, providers, or learning topics anytime from home.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
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
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sectionTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textMuted,
                  side: BorderSide(color: AppTheme.borderLight.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isContinueBusy ? null : onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: AppTheme.brandWhite,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: isContinueBusy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.brandWhite,
                        ),
                      )
                    : const Text('Continue'),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.shadowSoft(opacity: 0.08, blur: 20, y: 5),
          border: Border.all(
            color: AppTheme.borderLight.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}
