import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_router.dart';
import '../cors/ui_theme.dart';
import '../birthplan/birth_plans_list_screen.dart';
import '../appointments/appointments_list_screen.dart';
import '../services/database_service.dart';
import '../services/firebase_functions_service.dart';
import 'learning_todo_widget.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _showGenerateModulesDialog(BuildContext context) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final profile = await _databaseService.getUserProfile(userId);
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first')),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModuleGenerationDialog(profile: profile),
    );
    
    // Refresh the learning widget after generation
    if (mounted) {
      setState(() {});
    }
  }
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final profile = await _databaseService.getUserProfile(userId);
      if (mounted) {
        setState(() {
          _userName = profile?.name;
          // Debug: print to see what we're getting
          if (_userName == null || _userName!.isEmpty) {
            print('User name is null or empty. Profile: ${profile?.name}');
          }
        });
      }
    }
  }

  void _showTodoModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5), // Grey overlay
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Learning Modules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: const LearningTodoWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E2F6), // #e8e2f6
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome and User Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontFamily: 'Primary',
                          fontSize: MediaQuery.of(context).size.width * 0.12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userName ?? 'User',
                        style: TextStyle(
                          fontFamily: 'Primary',
                          fontSize: MediaQuery.of(context).size.width * 0.08,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Square Buttons Section
              Row(
                children: [
                  Expanded(
                    child: _SquareButton(
                      icon: Icons.calendar_today,
                      label: 'Appointments',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentsListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SquareButton(
                      icon: Icons.favorite,
                      label: 'Birthplan',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BirthPlansListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SquareButton(
                      icon: Icons.book,
                      label: 'Journal',
                      onTap: () => Navigator.pushNamed(context, Routes.journal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SquareButton(
                      icon: Icons.checklist,
                      label: 'Todo',
                      onTap: () => _showTodoModal(context),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Community Notifications Section
              Text(
                'Community Notifications',
                style: TextStyle(
                  fontFamily: 'Primary',
                  fontSize: MediaQuery.of(context).size.width * 0.06,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brandPurple,
                ),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: _CommunityNotificationsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Primary',
        color: AppTheme.brandGold,
        fontSize: 30,
        fontWeight: FontWeight.w600,
      ),
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
      'chronicConditions': widget.profile.chronicConditions ?? [],
      'healthLiteracyGoals': widget.profile.healthLiteracyGoals ?? [],
      'insuranceType': widget.profile.insuranceType ?? '',
      'providerPreferences': widget.profile.providerPreferences ?? [],
      'educationLevel': widget.profile.educationLevel ?? '',
    };

    // Define modules to generate
    final modules = [
      {'title': 'Your $trimester Trimester Guide', 'description': 'Essential information for your stage'},
      {'title': 'Nutrition & Wellness', 'description': 'What to eat and how to stay healthy'},
      {'title': 'Know Your Rights', 'description': 'Patient advocacy in maternity care'},
      {'title': 'Preparing for Appointments', 'description': 'Making the most of your visits'},
    ];

    // Add condition-specific module if needed
    if (widget.profile.chronicConditions != null && widget.profile.chronicConditions.isNotEmpty) {
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
            Text(
              'Creating Your Learning Plan',
              style: AppTheme.responsiveTitleStyle(
                context,
                baseSize: 20,
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

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: MediaQuery.of(context).size.width * 0.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppTheme.brandPurple,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.brandPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityNotificationsList extends StatelessWidget {
  final List<Map<String, String>> _mockNotifications = [
    {
      'title': 'New Community Event',
      'message': 'Join us for a virtual support group meeting this Friday at 6 PM',
      'time': '2 hours ago',
    },
    {
      'title': 'Resource Update',
      'message': 'New prenatal care resources are now available in your area',
      'time': '1 day ago',
    },
    {
      'title': 'Community Tip',
      'message': 'Remember to stay hydrated and take breaks throughout the day',
      'time': '2 days ago',
    },
    {
      'title': 'Welcome Message',
      'message': 'Welcome to the EmpowerHealth Watch community!',
      'time': '3 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _mockNotifications.length,
      itemBuilder: (context, index) {
        final notification = _mockNotifications[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                  ),
                  Text(
                    notification['time']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification['message']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

