import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';

/// Pregnancy vs postpartum with skip-safe gest_week / postpartum_month.
class PregnancyPostpartumQuestion extends StatelessWidget {
  const PregnancyPostpartumQuestion({
    super.key,
    required this.ppStatus,
    required this.onPpChanged,
    this.gestWeekController,
    this.postpartumMonthController,
  });

  /// 1 = pregnant, 2 = postpartum
  final int? ppStatus;
  final ValueChanged<int?> onPpChanged;
  final TextEditingController? gestWeekController;
  final TextEditingController? postpartumMonthController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pregnancy or postpartum',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.brandPurple,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        RadioListTile<int>(
          title: const Text('Currently pregnant'),
          value: 1,
          groupValue: ppStatus,
          activeColor: AppTheme.brandPurple,
          contentPadding: EdgeInsets.zero,
          onChanged: onPpChanged,
        ),
        RadioListTile<int>(
          title: const Text('Postpartum'),
          value: 2,
          groupValue: ppStatus,
          activeColor: AppTheme.brandPurple,
          contentPadding: EdgeInsets.zero,
          onChanged: onPpChanged,
        ),
        if (ppStatus == 1 && gestWeekController != null) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: gestWeekController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Gestational week (4–42)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        if (ppStatus == 2 && postpartumMonthController != null) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: postpartumMonthController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Months since delivery (0–48)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}
