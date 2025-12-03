import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_creation_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../cors/ui_theme.dart';
import 'steps/basic_info_step.dart';
import 'steps/demographics_step.dart';
import 'steps/health_info_step.dart';
import 'steps/support_network_step.dart';
import 'steps/wellness_access_step.dart';
import 'steps/preferences_step.dart';
import 'steps/goals_step.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  final List<Widget> _steps = [
    const BasicInfoStep(),
    const DemographicsStep(),
    const HealthInfoStep(),
    const SupportNetworkStep(),
    const WellnessAccessStep(),
    const PreferencesStep(),
    const GoalsStep(),
  ];

  final List<String> _stepTitles = [
    'Basic Information',
    'Demographics',
    'Health Information',
    'Support Network',
    'Wellness & Access',
    'Preferences',
    'Your Goals',
  ];

  Future<void> _saveProfile() async {
    final provider = Provider.of<ProfileCreationProvider>(context, listen: false);
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = provider.toUserProfile(userId);
      await _databaseService.saveUserProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully!')),
        );
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppTheme.brandWhite,
          appBar: AppBar(
            title: const Text('Create Your Profile'),
            elevation: 0,
            backgroundColor: Colors.white,
          ),
          body: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (provider.currentStep + 1) / provider.totalSteps,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.brandPurple,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Text(
                          'Step ${provider.currentStep + 1} of ${provider.totalSteps}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brandBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _stepTitles[provider.currentStep],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brandPurple,
                          fontFamily: 'Primary',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Step content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: _steps[provider.currentStep],
                ),
              ),

              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      if (provider.currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: provider.previousStep,
                            child: const Text('Back'),
                          ),
                        ),
                      if (provider.currentStep > 0)
                        const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (provider.currentStep < provider.totalSteps - 1) {
                                    provider.nextStep();
                                  } else {
                                    _saveProfile();
                                  }
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  provider.currentStep < provider.totalSteps - 1
                                      ? 'Next'
                                      : 'Complete Profile',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}






