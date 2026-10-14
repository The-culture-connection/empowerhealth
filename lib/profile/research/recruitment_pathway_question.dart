import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';
import '../../research/research_codes.dart';

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
    final options = pathways.isNotEmpty ? pathways : kDefaultRecruitmentPathways;

    final items = options
        .map(
          (e) => DropdownMenuItem<int>(
            value: e.key,
            child: Text(e.value, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();

    String compactLabel(int code) {
      for (final e in options) {
        if (e.key == code) return e.value;
      }
      return 'Select';
    }

    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which recruitment pathway applies to you?',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'This helps the research team compare cohorts. Choose the option that best matches how you are using the app.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        // Hearth puts field labels above the field rather than inside it.
        Text('Recruitment pathway', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.expand_more, color: AppTheme.brandPurple),
          decoration: const InputDecoration(),
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
