import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';

class GoalsStep extends StatelessWidget {
  const GoalsStep({super.key});

  static const List<String> _pregnancyOptions = [
    'Nutrition guidance',
    'Exercise during pregnancy',
    'Mental wellness',
    'Healthy pregnancy tips',
    'Sleep management',
    'Stress management',
    'Birth preparation',
  ];
  
  static const List<String> _postpartumOptions = [
    'Postpartum recovery',
    'Infant care',
    'Sleep management',
    'Mental wellness',
    'Nutrition guidance',
    'Breastfeeding support',
    'Returning to exercise',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finally, let\'s set some goals for your maternal health journey.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Birth Preference
            _buildSectionHeader(context, 'Birth Preference'),
            const SizedBox(height: 14),
            
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

            const SizedBox(height: AppTheme.spacingM),

            // Breastfeeding Interest
            _buildSectionHeader(context, 'Breastfeeding'),
            const SizedBox(height: 14),
            
            HearthOptionRow(
              label: 'I am interested in breastfeeding support',
              subtitle: 'We\'ll connect you with lactation resources',
              selected: provider.interestedInBreastfeeding,
              control: HearthControl.checkbox,
              onTap: () {
                provider.updateGoals(
                  interestedInBreastfeeding: !provider.interestedInBreastfeeding,
                );
              },
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // Health Literacy Goals
            _buildSectionHeader(context, 'Health Literacy Goals'),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              'What topics would you like to learn more about?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),

            Builder(
              builder: (context) {
                // Show different options based on pregnancy/postpartum status
                final options = provider.isPregnant 
                    ? _pregnancyOptions 
                    : (provider.isPostpartum ? _postpartumOptions : _pregnancyOptions);
                
                return Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: options.map((goal) {
                final isSelected = provider.healthLiteracyGoals.contains(goal);
                // HearthChoiceChip keeps its label Flexible, so a long label
                // wraps instead of overflowing at large text sizes.
                return HearthChoiceChip(
                  label: goal,
                  selected: isSelected,
                  icon: isSelected ? Icons.check : null,
                  onSelected: () {
                    final updated = List<String>.from(provider.healthLiteracyGoals);
                    if (isSelected) {
                      updated.remove(goal);
                    } else {
                      updated.add(goal);
                    }
                    provider.updateGoals(healthLiteracyGoals: updated);
                  },
                );
                  }).toList(),
                );
              },
            ),

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

  Widget _buildRadioOption({
    required String title,
    required String value,
    required String? groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HearthOptionRow(
        label: title,
        selected: isSelected,
        // A radio only reports a change when an unselected option is tapped.
        onTap: () {
          if (!isSelected) onChanged(value);
        },
      ),
    );
  }
}






