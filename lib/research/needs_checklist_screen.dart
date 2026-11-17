import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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
                'Care check-in',
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
          'Did you get the care and support you needed?',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Let’s check if your care needs were met. Select anything you needed help with, even if you didn’t receive it.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        // Nine needs: plain rows in one card instead of a bordered card per
        // option, so the list fits with far less scrolling.
        HearthCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final need in kCareNeedsChecklistItems)
                _CompactCheckRow(
                  label: need['label']!,
                  selected: selectedNeedIds.contains(need['id']),
                  onTap: () => onToggleNeed(need['id']!),
                ),
              if (selectedNeedIds.contains('other')) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                  child: NeedOtherTextField(
                    controller: otherDetailController,
                    inCard: true,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
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
                onPressed: () async {
                  await onContinue();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One checklist row: checkbox icon + label, at least 48px tall so it stays
/// an easy tap target. Selected rows get the warm tint.
class _CompactCheckRow extends StatelessWidget {
  const _CompactCheckRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      child: Material(
        color: selected ? AppTheme.tintWarm : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 22,
                    color: selected ? AppTheme.brandPurple : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color:
                            selected ? AppTheme.ink : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
