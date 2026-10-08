import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';

class PreferencesStep extends StatelessWidget {
  const PreferencesStep({super.key});

  static const List<String> _allPreferences = [
    'Cultural match',
    'Gender preference',
    'Trauma-informed care',
    'LGBTQ+ friendly',
    'Spanish-speaking',
    'Black-owned practice',
    'Holistic approach',
    'Evidence-based care',
    'Community-based care',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us about your provider preferences to help us match you with the right care.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingXL),

            _buildSectionHeader(context, 'Provider Characteristics'),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              'Select all that apply',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),

            ..._allPreferences.map((preference) {
              final isSelected = provider.providerPreferences.contains(preference);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HearthOptionRow(
                  label: preference,
                  selected: isSelected,
                  control: HearthControl.checkbox,
                  onTap: () {
                    final updated = List<String>.from(provider.providerPreferences);
                    if (isSelected) {
                      updated.remove(preference);
                    } else {
                      updated.add(preference);
                    }
                    provider.updatePreferences(updated);
                  },
                ),
              );
            }),

            const SizedBox(height: AppTheme.spacingXXL),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}






