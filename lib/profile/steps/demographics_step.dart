import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';

class DemographicsStep extends StatelessWidget {
  const DemographicsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        final textTheme = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us a bit more about yourself.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingXL),

            Text(
              'This information helps us connect you with culturally relevant resources and support.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              'These fields are optional.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Race/Ethnicity
            _buildFieldLabel(context, 'Race/Ethnicity'),
            DropdownButtonFormField<String>(
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              value: provider.raceEthnicity,
              icon: _dropdownIcon,
              dropdownColor: AppTheme.surface,
              borderRadius: hearthCardRadius,
              decoration: const InputDecoration(
                hintText: 'Select your race/ethnicity',
                prefixIcon: Icon(Icons.people_outline, color: AppTheme.brandPurple),
              ),
              items: const [
                DropdownMenuItem(value: 'American Indian or Alaska Native', child: Text('American Indian or Alaska Native')),
                DropdownMenuItem(value: 'Asian', child: Text('Asian')),
                DropdownMenuItem(value: 'Black or African American', child: Text('Black or African American')),
                DropdownMenuItem(value: 'Hispanic or Latino', child: Text('Hispanic or Latino')),
                DropdownMenuItem(value: 'Native Hawaiian or Pacific Islander', child: Text('Native Hawaiian or Pacific Islander')),
                DropdownMenuItem(value: 'White', child: Text('White')),
                DropdownMenuItem(value: 'Two or More Races', child: Text('Two or More Races')),
                DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
              ],
              onChanged: (value) {
                provider.updateDemographics(raceEthnicity: value);
              },
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Language Preference
            _buildFieldLabel(context, 'Preferred Language'),
            DropdownButtonFormField<String>(
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              value: provider.languagePreference,
              icon: _dropdownIcon,
              dropdownColor: AppTheme.surface,
              borderRadius: hearthCardRadius,
              decoration: const InputDecoration(
                hintText: 'Select your preferred language',
                prefixIcon: Icon(Icons.language, color: AppTheme.brandPurple),
              ),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                DropdownMenuItem(value: 'Chinese', child: Text('Chinese')),
                DropdownMenuItem(value: 'French', child: Text('French')),
                DropdownMenuItem(value: 'German', child: Text('German')),
                DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
                DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                DropdownMenuItem(value: 'Portuguese', child: Text('Portuguese')),
                DropdownMenuItem(value: 'Russian', child: Text('Russian')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                provider.updateDemographics(languagePreference: value);
              },
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Marital Status
            _buildFieldLabel(context, 'Marital Status'),
            DropdownButtonFormField<String>(
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              value: provider.maritalStatus,
              icon: _dropdownIcon,
              dropdownColor: AppTheme.surface,
              borderRadius: hearthCardRadius,
              decoration: const InputDecoration(
                hintText: 'Select your marital status',
                prefixIcon: Icon(Icons.favorite_outline, color: AppTheme.brandPurple),
              ),
              items: const [
                DropdownMenuItem(value: 'Single', child: Text('Single')),
                DropdownMenuItem(value: 'Married', child: Text('Married')),
                DropdownMenuItem(value: 'Partnered', child: Text('Partnered')),
                DropdownMenuItem(value: 'Divorced', child: Text('Divorced')),
                DropdownMenuItem(value: 'Widowed', child: Text('Widowed')),
                DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
              ],
              onChanged: (value) {
                provider.updateDemographics(maritalStatus: value);
              },
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Education Level
            _buildFieldLabel(context, 'Education Level'),
            DropdownButtonFormField<String>(
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              value: provider.educationLevel,
              icon: _dropdownIcon,
              dropdownColor: AppTheme.surface,
              borderRadius: hearthCardRadius,
              decoration: const InputDecoration(
                hintText: 'Select your education level',
                prefixIcon: Icon(Icons.school_outlined, color: AppTheme.brandPurple),
              ),
              items: const [
                DropdownMenuItem(value: 'Less than high school', child: Text('Less than high school')),
                DropdownMenuItem(value: 'High school or GED', child: Text('High school or GED')),
                DropdownMenuItem(value: 'Some college', child: Text('Some college')),
                DropdownMenuItem(value: 'Associate degree', child: Text('Associate degree')),
                DropdownMenuItem(value: 'Bachelor\'s degree', child: Text('Bachelor\'s degree')),
                DropdownMenuItem(value: 'Graduate degree', child: Text('Graduate degree')),
                DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
              ],
              onChanged: (value) {
                provider.updateDemographics(educationLevel: value);
              },
            ),
            const SizedBox(height: AppTheme.spacingXXL),
          ],
        );
      },
    );
  }

  static const Widget _dropdownIcon = Icon(Icons.expand_more, color: AppTheme.brandPurple);

  // Labels sit above the field, as in the Hearth forms.
  Widget _buildFieldLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.ink),
      ),
    );
  }
}
