import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';

class GoalsStep extends StatelessWidget {
  const GoalsStep({super.key});

  static const List<String> _healthLiteracyOptions = [
    'Nutrition guidance',
    'Exercise during pregnancy',
    'Mental wellness',
    'Healthy pregnancy tips',
    'Postpartum recovery',
    'Infant care',
    'Sleep management',
    'Stress management',
    'Birth preparation',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Finally, let\'s set some goals for your maternal health journey.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Birth Preference
            _buildSectionHeader('Birth Preference'),
            const SizedBox(height: AppTheme.spacingL),
            
            _buildRadioOption(
              title: 'Hospital Birth',
              value: 'Hospital',
              groupValue: provider.birthPreference,
              onChanged: (value) {
                provider.updateGoals(birthPreference: value);
              },
            ),
            _buildRadioOption(
              title: 'Home Birth',
              value: 'Home',
              groupValue: provider.birthPreference,
              onChanged: (value) {
                provider.updateGoals(birthPreference: value);
              },
            ),
            _buildRadioOption(
              title: 'Birth Center',
              value: 'Birth Center',
              groupValue: provider.birthPreference,
              onChanged: (value) {
                provider.updateGoals(birthPreference: value);
              },
            ),
            _buildRadioOption(
              title: 'Undecided',
              value: 'Undecided',
              groupValue: provider.birthPreference,
              onChanged: (value) {
                provider.updateGoals(birthPreference: value);
              },
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // Breastfeeding Interest
            _buildSectionHeader('Breastfeeding'),
            const SizedBox(height: AppTheme.spacingL),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: provider.interestedInBreastfeeding 
                      ? AppTheme.brandTurquoise 
                      : Colors.grey[300]!,
                  width: provider.interestedInBreastfeeding ? 2 : 1,
                ),
              ),
              child: CheckboxListTile(
                title: const Text(
                  'I am interested in breastfeeding support',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'We\'ll connect you with lactation resources',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                value: provider.interestedInBreastfeeding,
                activeColor: AppTheme.brandTurquoise,
                onChanged: (value) {
                  provider.updateGoals(interestedInBreastfeeding: value ?? false);
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingS,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // Health Literacy Goals
            _buildSectionHeader('Health Literacy Goals'),
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'What topics would you like to learn more about?',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: AppTheme.spacingL),

            Wrap(
              spacing: AppTheme.spacingM,
              runSpacing: AppTheme.spacingM,
              children: _healthLiteracyOptions.map((goal) {
                final isSelected = provider.healthLiteracyGoals.contains(goal);
                return InkWell(
                  onTap: () {
                    final updated = List<String>.from(provider.healthLiteracyGoals);
                    if (isSelected) {
                      updated.remove(goal);
                    } else {
                      updated.add(goal);
                    }
                    provider.updateGoals(healthLiteracyGoals: updated);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingM,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.brandGold.withOpacity(0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.brandGold : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: AppTheme.brandGold,
                          ),
                        if (isSelected) const SizedBox(width: AppTheme.spacingS),
                        Text(
                          goal,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppTheme.brandGold : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

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

  Widget _buildRadioOption({
    required String title,
    required String value,
    required String? groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.brandPurple.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.brandPurple : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        value: value,
        groupValue: groupValue,
        activeColor: AppTheme.brandPurple,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingXS,
        ),
      ),
    );
  }
}


