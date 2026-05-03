import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';
import '../../research/research_codes.dart';

class InsuranceQuestion extends StatelessWidget {
  const InsuranceQuestion({
    super.key,
    required this.insuranceType,
    required this.onInsuranceChanged,
    required this.otherController,
    this.showOtherField = true,
  });

  final int? insuranceType;
  final ValueChanged<int?> onInsuranceChanged;
  final TextEditingController otherController;
  final bool showOtherField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insurance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.brandPurple,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: insuranceType,
          decoration: const InputDecoration(
            labelText: 'Insurance type',
            border: OutlineInputBorder(),
          ),
          selectedItemBuilder: (context) {
            return kInsuranceTypeOptions.map((e) {
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  e.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: kInsuranceTypeOptions
              .map(
                (e) => DropdownMenuItem<int>(
                  value: e.key,
                  child: Text(e.value),
                ),
              )
              .toList(),
          onChanged: onInsuranceChanged,
        ),
        if (showOtherField && insuranceType == 5) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: otherController,
            decoration: const InputDecoration(
              labelText: 'Other (specify)',
              border: OutlineInputBorder(),
              helperText: 'No names or email addresses',
            ),
            maxLength: 500,
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}
