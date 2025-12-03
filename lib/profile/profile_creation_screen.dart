import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/profile_creation_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/firebase_functions_service.dart';
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
        // Show progress dialog and generate learning modules
        await _showModuleGenerationProgress(profile);
        
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

  Future<void> _showModuleGenerationProgress(dynamic profile) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModuleGenerationDialog(profile: profile),
    );
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

class _ModuleGenerationDialog extends StatefulWidget {
  final dynamic profile;

  const _ModuleGenerationDialog({required this.profile});

  @override
  State<_ModuleGenerationDialog> createState() => _ModuleGenerationDialogState();
}

class _ModuleGenerationDialogState extends State<_ModuleGenerationDialog> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  double _progress = 0.0;
  String _currentTask = 'Preparing your personalized learning plan...';
  int _completedModules = 0;
  int _totalModules = 4;

  @override
  void initState() {
    super.initState();
    _generateModules();
  }

  Future<void> _generateModules() async {
    final trimester = _calculateTrimester(widget.profile.dueDate);
    final userId = widget.profile.userId;

    // Prepare profile data
    final profileData = {
      'chronicConditions': widget.profile.chronicConditions,
      'healthLiteracyGoals': widget.profile.healthLiteracyGoals,
      'insuranceType': widget.profile.insuranceType,
      'providerPreferences': widget.profile.providerPreferences,
      'educationLevel': widget.profile.educationLevel,
    };

    // Define modules to generate
    final modules = [
      {'title': 'Your $trimester Trimester Guide', 'description': 'Essential information for your stage'},
      {'title': 'Nutrition & Wellness', 'description': 'What to eat and how to stay healthy'},
      {'title': 'Know Your Rights', 'description': 'Patient advocacy in maternity care'},
      {'title': 'Preparing for Appointments', 'description': 'Making the most of your visits'},
    ];

    // Add condition-specific module if needed
    if (widget.profile.chronicConditions.isNotEmpty) {
      modules.add({
        'title': 'Managing ${widget.profile.chronicConditions.first}',
        'description': 'Special considerations during pregnancy',
      });
      _totalModules = 5;
    }

    for (int i = 0; i < modules.length; i++) {
      final module = modules[i];
      
      setState(() {
        _currentTask = 'Generating: ${module['title']}...';
        _progress = (i / modules.length);
      });

      try {
        final result = await _functionsService.generateLearningContent(
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

        setState(() {
          _completedModules = i + 1;
          _progress = ((i + 1) / modules.length);
        });

        // Small delay for better UX
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Error generating module: $e');
        // Continue with other modules even if one fails
      }
    }

    setState(() {
      _currentTask = 'Complete! Your learning plan is ready.';
      _progress = 1.0;
    });

    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      Navigator.of(context).pop();
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 48,
              color: AppTheme.brandPurple,
            ),
            const SizedBox(height: 16),
            const Text(
              'Creating Your Learning Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPurple),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Text(
              _currentTask,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$_completedModules of $_totalModules modules generated',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}


