import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';

/// Research recruitment (coded 1–7) with "Other, specify" when code is 6.
class RecruitmentSourceQuestion extends StatelessWidget {
  const RecruitmentSourceQuestion({
    super.key,
    required this.value,
    required this.onChanged,
    required this.otherController,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final TextEditingController otherController;

  static const _items = <DropdownMenuItem<int>>[
    DropdownMenuItem(value: 1, child: Text('Clinic / provider partner')),
    DropdownMenuItem(value: 2, child: Text('Community organization / CHW / doula / event')),
    DropdownMenuItem(value: 3, child: Text('Social media')),
    DropdownMenuItem(value: 4, child: Text('Research study referral')),
    DropdownMenuItem(value: 5, child: Text('Web search')),
    DropdownMenuItem(value: 6, child: Text('Other')),
    DropdownMenuItem(value: 7, child: Text('Prefer not to say')),
  ];

  static String _compactLabel(int code) {
    switch (code) {
      case 1:
        return 'Clinic / provider';
      case 2:
        return 'Community / CHW / event';
      case 3:
        return 'Social media';
      case 4:
        return 'Research referral';
      case 5:
        return 'Web search';
      case 6:
        return 'Other';
      case 7:
        return 'Prefer not to say';
      default:
        return 'Select';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How did you hear about EmpowerHealth Watch?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.brandPurple,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: value,
          decoration: const InputDecoration(
            labelText: 'Recruitment source',
            border: OutlineInputBorder(),
          ),
          selectedItemBuilder: (context) {
            return _items.map((item) {
              final code = item.value!;
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _compactLabel(code),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: _items,
          onChanged: onChanged,
        ),
        if (value == 6) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: otherController,
            decoration: const InputDecoration(
              labelText: 'Other (specify)',
              border: OutlineInputBorder(),
              helperText: 'Do not include names or email addresses',
            ),
            maxLength: 500,
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}
