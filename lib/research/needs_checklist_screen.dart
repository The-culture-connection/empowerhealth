import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import 'need_other_text_field.dart';

/// Labels aligned with [CareNavigationSurveyScreen] care need ids (research `need_*` fields).
const List<Map<String, String>> kCareNeedsChecklistItems = [
  {'id': 'prenatal-postpartum', 'label': 'Doctor or midwife care for me'},
  {'id': 'labor-delivery', 'label': 'Getting ready for labor and birth'},
  {
    'id': 'blood-pressure',
    'label': 'Follow-up for a health concern (e.g., blood pressure, diabetes)',
  },
  {'id': 'mental-health', 'label': 'Emotional or mental health support'},
  {
    'id': 'lactation',
    'label': 'Help with feeding my baby (breastfeeding, pumping, or formula)',
  },
  {'id': 'infant-pediatric', 'label': 'Doctor visits or care for my baby'},
  {
    'id': 'benefits',
    'label': 'Help with benefits or essentials (WIC, Medicaid, diapers, crib, car seat)',
  },
  {
    'id': 'transportation',
    'label': 'Getting to appointments (rides, transportation, scheduling)',
  },
  {'id': 'other', 'label': 'Something else I need help with'},
];

/// Step 1 UI for the care navigation flow — need toggles + optional other text.
class NeedsChecklistScreen extends StatelessWidget {
  const NeedsChecklistScreen({
    super.key,
    required this.selectedNeedIds,
    required this.onToggleNeed,
    required this.otherDetailController,
    required this.onBack,
    required this.onContinue,
    this.isContinueBusy = false,
  });

  final List<String> selectedNeedIds;
  final void Function(String needId) onToggleNeed;
  final TextEditingController otherDetailController;
  final VoidCallback onBack;
  final Future<void> Function() onContinue;
  final bool isContinueBusy;

  @override
  Widget build(BuildContext context) {
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
                'Care check-in',
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
          'Did you get the care and support you needed?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let’s check if your care needs were met. Select anything you needed help with — even if you didn’t receive it.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.shadowSoft(opacity: 0.1, blur: 24, y: 8),
            border: Border.all(
              color: AppTheme.borderLight.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              ...kCareNeedsChecklistItems.map((need) {
                final id = need['id']!;
                final label = need['label']!;
                final isSelected = selectedNeedIds.contains(id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => onToggleNeed(id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  AppTheme.brandPurple,
                                  Color(0xFF7744AA),
                                ],
                              )
                            : null,
                        color: isSelected ? null : AppTheme.backgroundWarm,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.brandPurple.withValues(alpha: 0.2),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: AppTheme.brandPurple.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppTheme.brandWhite : AppTheme.brandPurple,
                                width: 2,
                              ),
                              color: isSelected ? AppTheme.brandWhite : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(Icons.check, size: 14, color: AppTheme.brandPurple)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.35,
                                fontWeight: FontWeight.w300,
                                color: isSelected ? AppTheme.brandWhite : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (selectedNeedIds.contains('other')) ...[
                const SizedBox(height: 8),
                NeedOtherTextField(controller: otherDetailController),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
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
                onPressed: isContinueBusy
                    ? null
                    : () async {
                        await onContinue();
                      },
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
      ],
    );
  }
}
