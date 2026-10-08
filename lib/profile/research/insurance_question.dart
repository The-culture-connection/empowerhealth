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
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insurance', style: textTheme.headlineMedium),
        const SizedBox(height: 16),
        // Hearth puts field labels above the field rather than inside it.
        Text('Insurance type', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: insuranceType,
          icon: const Icon(Icons.expand_more, color: AppTheme.brandPurple),
          decoration: const InputDecoration(),
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
          Text('Other (specify)', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: otherController,
            decoration: const InputDecoration(
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
