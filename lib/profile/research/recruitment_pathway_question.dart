import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';

/// Research recruitment pathway (admin-configured numeric codes).
class RecruitmentPathwayQuestion extends StatelessWidget {
  const RecruitmentPathwayQuestion({
    super.key,
    required this.value,
    required this.onChanged,
    required this.pathways,
    this.loading = false,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final List<MapEntry<int, String>> pathways;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pathways.isEmpty) {
      return const Text(
        'Recruitment pathways are not available right now. Please try again later.',
        style: TextStyle(color: Colors.red),
      );
    }

    final items = pathways
        .map(
          (e) => DropdownMenuItem<int>(
            value: e.key,
            child: Text(e.value, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();

    String compactLabel(int code) {
      for (final e in pathways) {
        if (e.key == code) return e.value;
      }
      return 'Select';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which recruitment pathway applies to you?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.brandPurple,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps the research team compare cohorts. Choose the option that best matches how you are using the app.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: value,
          decoration: const InputDecoration(
            labelText: 'Recruitment pathway',
            border: OutlineInputBorder(),
          ),
          selectedItemBuilder: (context) {
            return items.map((item) {
              final code = item.value!;
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  compactLabel(code),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
