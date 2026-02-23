import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_creation_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/firebase_functions_service.dart';
import '../privacy/consent_screen.dart';
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
        // Start async module generation in background
        _generateModulesAsync(profile);
        
        // Check if user has given consent
        final hasConsent = await _databaseService.userHasConsent(userId);
        
        if (hasConsent) {
          // If consent already given, go to main screen
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          // If no consent, show consent screen after onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ConsentScreen(isFirstRun: true),
            ),
          );
        }
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

  Future<void> _generateModulesAsync(dynamic profile) async {
    // Generate modules in background without blocking UI
    try {
      final FirebaseFunctionsService functionsService = FirebaseFunctionsService();
      final DatabaseService dbService = DatabaseService();
      final userId = profile.userId;
      final trimester = _calculateTrimester(profile.dueDate);

      // Prepare profile data
      final profileData = {
        'chronicConditions': profile.chronicConditions ?? [],
        'healthLiteracyGoals': profile.healthLiteracyGoals ?? [],
        'insuranceType': profile.insuranceType ?? '',
        'providerPreferences': profile.providerPreferences ?? [],
        'educationLevel': profile.educationLevel ?? '',
      };

      // Define modules to generate
      final modules = [
        {'title': 'Your $trimester Trimester Guide', 'description': 'Essential information for your stage'},
        {'title': 'Nutrition & Wellness', 'description': 'What to eat and how to stay healthy'},
        {'title': 'Know Your Rights', 'description': 'Patient advocacy in maternity care'},
        {'title': 'Preparing for Appointments', 'description': 'Making the most of your visits'},
        {'title': 'Hospital Admission Checklist', 'description': 'What to bring and prepare for your hospital stay'},
        {'title': 'Triage Education', 'description': 'Understanding the triage process and what to expect'},
        {'title': 'What to Expect During Delivery', 'description': 'A guide to the delivery process and stages'},
        {'title': 'When and How to Speak Up', 'description': 'Advocacy skills for communicating with your care team'},
      ];

      // Add condition-specific module if needed
      if (profile.chronicConditions != null && profile.chronicConditions.isNotEmpty) {
        modules.add({
          'title': 'Managing ${profile.chronicConditions.first}',
          'description': 'Special considerations during pregnancy',
        });
      }

      // Update generation status in user profile (using flat structure)
      await dbService.updateUserProfile(userId, {
        'moduleGen_isGenerating': true,
        'moduleGen_totalModules': modules.length,
        'moduleGen_completedModules': 0,
        'moduleGen_startedAt': FieldValue.serverTimestamp(),
      });

      // Generate modules one by one
      for (int i = 0; i < modules.length; i++) {
        final module = modules[i];
        
        try {
          final result = await functionsService.generateLearningContent(
            topic: module['title']!,
            trimester: trimester,
            moduleType: 'personalized',
            userProfile: profileData,
          );

          // Save to learning tasks
          await FirebaseFirestore.instance.collection('learning_tasks').add({
            'userId': userId,
            'title': module['title'],
            'description': module['description'],
            'trimester': trimester,
            'isGenerated': true,
            'content': result['content'],
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Update progress in user profile
          await dbService.updateUserProfile(userId, {
            'moduleGen_completedModules': i + 1,
          });

          // Small delay for better UX
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('Error generating module ${module['title']}: $e');
          // Continue with other modules even if one fails
        }
      }

      // Mark generation as complete in user profile
      await dbService.updateUserProfile(userId, {
        'moduleGen_isGenerating': false,
        'moduleGen_completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error in async module generation: $e');
      // Update status to show error in user profile
      try {
        final DatabaseService dbService = DatabaseService();
        await dbService.updateUserProfile(profile.userId, {
          'moduleGen_isGenerating': false,
          'moduleGen_error': e.toString(),
        });
      } catch (_) {}
    }
  }

  String _calculateTrimester(DateTime? dueDate) {
    if (dueDate == null) return 'First';
    
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    final weeksPregnant = 40 - (daysUntilDue / 7).floor();
    
    if (weeksPregnant <= 0) return 'First';
    if (weeksPregnant <= 13) return 'First';
    if (weeksPregnant <= 27) return 'Second';
    return 'Third';
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
                        style: AppTheme.responsiveTitleStyle(
                          context,
                          baseSize: 18,
                          color: AppTheme.brandPurple,
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



