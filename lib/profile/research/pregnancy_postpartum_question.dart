import 'package:flutter/material.dart';
import '../../design_system/hearth.dart';

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

  // Like a radio, tapping the option that is already chosen changes nothing.
  void _select(int value) {
    if (ppStatus != value) onPpChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pregnancy or postpartum', style: textTheme.headlineMedium),
        const SizedBox(height: 16),
        HearthOptionRow(
          label: 'Currently pregnant',
          selected: ppStatus == 1,
          onTap: () => _select(1),
        ),
        const SizedBox(height: 12),
        HearthOptionRow(
          label: 'Postpartum',
          selected: ppStatus == 2,
          onTap: () => _select(2),
        ),
        if (ppStatus == 1 && gestWeekController != null) ...[
          const SizedBox(height: 16),
          Text('Gestational week (4–42)', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: gestWeekController,
            keyboardType: TextInputType.number,
          ),
        ],
        if (ppStatus == 2 && postpartumMonthController != null) ...[
          const SizedBox(height: 16),
          Text('Months since delivery (0–48)', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: postpartumMonthController,
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }
}
