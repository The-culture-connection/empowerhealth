import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';

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
            const Text(
              'Tell us about your provider preferences to help us match you with the right care.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            _buildSectionHeader('Provider Characteristics'),
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'Select all that apply',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: AppTheme.spacingL),

            ..._allPreferences.map((preference) {
              final isSelected = provider.providerPreferences.contains(preference);
              return Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: InkWell(
                  onTap: () {
                    final updated = List<String>.from(provider.providerPreferences);
                    if (isSelected) {
                      updated.remove(preference);
                    } else {
                      updated.add(preference);
                    }
                    provider.updatePreferences(updated);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.brandPurple.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.brandPurple : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? AppTheme.brandPurple : Colors.grey[400],
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            preference,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppTheme.brandPurple : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: AppTheme.spacingXXL),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.brandPurple,
        fontFamily: 'Primary',
      ),
    );
  }
}


