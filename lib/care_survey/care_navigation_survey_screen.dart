import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cors/ui_theme.dart';

class CareNavigationSurveyScreen extends StatefulWidget {
  const CareNavigationSurveyScreen({super.key});

  @override
  State<CareNavigationSurveyScreen> createState() => _CareNavigationSurveyScreenState();
}

class _CareNavigationSurveyScreenState extends State<CareNavigationSurveyScreen> {
  String _step = 'intro'; // 'intro', 'needs', 'access', 'complete'
  List<String> _selectedNeeds = [];
  Map<String, String> _accessResponses = {};
  int _currentNeedIndex = 0;

  final List<Map<String, String>> _careNeeds = [
    {'id': 'prenatal-postpartum', 'label': 'Prenatal or postpartum medical care'},
    {'id': 'labor-delivery', 'label': 'Labor & delivery preparation'},
    {'id': 'blood-pressure', 'label': 'Blood pressure or medical condition follow-up'},
    {'id': 'mental-health', 'label': 'Mental health support'},
    {'id': 'lactation', 'label': 'Lactation/feeding support'},
    {'id': 'infant-pediatric', 'label': 'Infant/pediatric care'},
    {'id': 'benefits', 'label': 'Benefits/resources (WIC, Medicaid, crib, car seat)'},
    {'id': 'transportation', 'label': 'Transportation/logistics'},
    {'id': 'other', 'label': 'Other'},
  ];

  final List<Map<String, String>> _accessOptions = [
    {'value': 'yes', 'label': 'Yes'},
    {'value': 'partly', 'label': 'Partly'},
    {'value': 'no', 'label': 'No'},
    {'value': 'didnt-try', 'label': "Didn't try"},
    {'value': 'didnt-know', 'label': "Didn't know how"},
    {'value': 'couldnt-access', 'label': "Couldn't access"},
  ];

  void _toggleNeed(String needId) {
    setState(() {
      if (_selectedNeeds.contains(needId)) {
        _selectedNeeds.remove(needId);
      } else {
        _selectedNeeds.add(needId);
      }
    });
  }

  Future<void> _handleAccessResponse(String response) async {
    final currentNeed = _selectedNeeds[_currentNeedIndex];
    setState(() {
      _accessResponses[currentNeed] = response;
    });

    // Move to next need or complete
    if (_currentNeedIndex < _selectedNeeds.length - 1) {
      setState(() {
        _currentNeedIndex++;
      });
    } else {
      // Save to Firestore
      await _saveSurveyResults();
      if (mounted) {
        setState(() {
          _step = 'complete';
        });
      }
    }
  }

  Future<void> _saveSurveyResults() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('⚠️ [CareSurvey] User not authenticated');
        return;
      }

      final surveyData = {
        'userId': userId,
        'selectedNeeds': _selectedNeeds,
        'accessResponses': _accessResponses,
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      };

      await FirebaseFirestore.instance
          .collection('CareSurvey')
          .add(surveyData);

      print('✅ [CareSurvey] Survey results saved to Firestore');
    } catch (e) {
      print('❌ [CareSurvey] Error saving survey results: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving survey: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Navigation (not on complete step)
              if (_step != 'complete')
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: InkWell(
                    onTap: () {
                      if (_step == 'needs') {
                        setState(() => _step = 'intro');
                      } else if (_step == 'access') {
                        if (_currentNeedIndex > 0) {
                          setState(() => _currentNeedIndex--);
                        } else {
                          setState(() => _step = 'needs');
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.chevron_left, color: AppTheme.textMuted, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _step == 'intro' ? 'Home' : 'Back',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Intro Step
              if (_step == 'intro') _buildIntroStep(),

              // Needs Selection Step
              if (_step == 'needs') _buildNeedsStep(),

              // Access Response Step
              if (_step == 'access') _buildAccessStep(),

              // Complete Step
              if (_step == 'complete') _buildCompleteStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF5EEE0),
                Color(0xFFEBE0D6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderLight.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD4A574)),
              const SizedBox(width: 8),
              Text(
                'Care check-in',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          'How can we support you?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),

        // Description
        Text(
          'Your responses help us understand what\'s working and where you might need more support. This takes about 2 minutes.',
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // Privacy Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandPurple.withOpacity(0.14),
                blurRadius: 48,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(
              color: AppTheme.borderLight.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF5EEE0),
                      Color(0xFFEBE0D6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.favorite, color: Color(0xFFD4A574), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your privacy matters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your answers are confidential and help improve care for everyone. You can skip any question.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Start Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _step = 'needs');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 8,
            ),
            child: Text(
              'Start check-in',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNeedsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderLight.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(0xFFD4A574),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Step 1 of 2',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          'In the past few weeks, did you need help with:',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 24),

        // Needs List
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandPurple.withOpacity(0.14),
                blurRadius: 48,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(
              color: AppTheme.borderLight.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Column(
            children: _careNeeds.map((need) {
              final isSelected = _selectedNeeds.contains(need['id']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _toggleNeed(need['id']!),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                AppTheme.brandPurple,
                                Color(0xFF7744AA),
                              ],
                            )
                          : null,
                      color: isSelected ? null : AppTheme.backgroundWarm,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.brandPurple.withOpacity(0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppTheme.brandPurple.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFFD4A574) : Colors.transparent,
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: AppTheme.textMuted,
                                    width: 2,
                                  ),
                            shape: BoxShape.circle,
                          ),
                          child: isSelected
                              ? Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            need['label']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Navigation Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _step = 'intro');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textMuted,
                  side: BorderSide(color: AppTheme.borderLight.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedNeeds.isEmpty) {
                    _saveSurveyResults();
                    setState(() => _step = 'complete');
                  } else {
                    setState(() {
                      _step = 'access';
                      _currentNeedIndex = 0;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _selectedNeeds.isEmpty ? 'Skip to finish' : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccessStep() {
    final currentNeed = _selectedNeeds[_currentNeedIndex];
    final currentNeedLabel = _careNeeds.firstWhere(
      (n) => n['id'] == currentNeed,
      orElse: () => {'id': '', 'label': ''},
    )['label'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderLight.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(0xFFD4A574),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Question ${_currentNeedIndex + 1} of ${_selectedNeeds.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          currentNeedLabel,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Did you get what you needed?',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 24),

        // Progress Bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.borderLight,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (_currentNeedIndex + 1) / _selectedNeeds.length,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.brandPurple,
                    Color(0xFFD4A574),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Access Options
        Column(
          children: _accessOptions.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _handleAccessResponse(option['value']!),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandPurple.withOpacity(0.1),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.borderLight.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    option['label']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Back Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              if (_currentNeedIndex > 0) {
                setState(() => _currentNeedIndex--);
              } else {
                setState(() => _step = 'needs');
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              side: BorderSide(color: AppTheme.borderLight.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Back'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF5EEE0),
                  Color(0xFFEBE0D6),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite,
              color: Color(0xFFD4A574),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Thank you for sharing',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            'Your responses help us understand how to better support you and others in your community.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandPurple,
                  Color(0xFF7744AA),
                  Color(0xFF8855BB),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandPurple.withOpacity(0.2),
                  blurRadius: 48,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Text(
              'If you need immediate help accessing any of these services, our care team is here for you. You can reach out anytime.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w300,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}
