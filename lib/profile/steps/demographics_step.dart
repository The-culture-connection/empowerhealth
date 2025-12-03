import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';

class DemographicsStep extends StatefulWidget {
  const DemographicsStep({super.key});

  @override
  State<DemographicsStep> createState() => _DemographicsStepState();
}

class _DemographicsStepState extends State<DemographicsStep> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProfileCreationProvider>(context, listen: false);
    _nameController.text = provider.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us a bit more about yourself.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Full Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onChanged: (value) {
                provider.updateBasicInfo(name: value);
              },
            ),
            const SizedBox(height: AppTheme.spacingL),

            const Text(
              'The following demographic information helps us connect you with culturally relevant resources and support.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const Text(
              'These fields are optional.',
              style: TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Race/Ethnicity
            DropdownButtonFormField<String>(
              value: provider.raceEthnicity,
              decoration: const InputDecoration(
                labelText: 'Race/Ethnicity',
                hintText: 'Select your race/ethnicity',
                prefixIcon: Icon(Icons.people_outline),
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
            const SizedBox(height: AppTheme.spacingL),

            // Language Preference
            DropdownButtonFormField<String>(
              value: provider.languagePreference,
              decoration: const InputDecoration(
                labelText: 'Preferred Language',
                hintText: 'Select your preferred language',
                prefixIcon: Icon(Icons.language),
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
            const SizedBox(height: AppTheme.spacingL),

            // Marital Status
            DropdownButtonFormField<String>(
              value: provider.maritalStatus,
              decoration: const InputDecoration(
                labelText: 'Marital Status',
                hintText: 'Select your marital status',
                prefixIcon: Icon(Icons.favorite_outline),
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
            const SizedBox(height: AppTheme.spacingL),

            // Education Level
            DropdownButtonFormField<String>(
              value: provider.educationLevel,
              decoration: const InputDecoration(
                labelText: 'Education Level',
                hintText: 'Select your education level',
                prefixIcon: Icon(Icons.school_outlined),
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
}






