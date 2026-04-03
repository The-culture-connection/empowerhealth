import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cors/ui_theme.dart';
import '../widgets/feature_session_scope.dart';

class CareNavigationSurveyScreen extends StatefulWidget {
  const CareNavigationSurveyScreen({super.key});

  @override
  State<CareNavigationSurveyScreen> createState() => _CareNavigationSurveyScreenState();
}

class _CareNavigationSurveyScreenState extends State<CareNavigationSurveyScreen> {
  String _step = 'intro'; // 'intro', 'needs', 'access', 'outcome', 'complete'
  List<String> _selectedNeeds = [];
  Map<String, String> _accessResponses = {};
  Map<String, String> _accessResponseTimestamps = {};
  int _currentNeedIndex = 0;
  String? _gotWhatNeeded;

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

  static const List<Map<String, String>> _outcomeOptions = [
    {'value': 'yes', 'label': 'Yes'},
    {'value': 'mostly', 'label': 'Mostly'},
    {'value': 'no', 'label': 'No'},
    {'value': 'unsure', 'label': 'Not sure yet'},
    {'value': 'skip', 'label': 'Prefer not to say'},
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
      _accessResponseTimestamps[currentNeed] =
          DateTime.now().toUtc().toIso8601String();
    });

    // Move to next need or complete
    if (_currentNeedIndex < _selectedNeeds.length - 1) {
      setState(() {
        _currentNeedIndex++;
      });
    } else {
      setState(() {
        _step = 'outcome';
      });
    }
  }

  Future<void> _submitGotWhatNeeded(String value) async {
    _gotWhatNeeded = value;
    await _saveSurveyResults();
    if (mounted) {
      setState(() {
        _step = 'complete';
      });
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
        'accessResponseTimestamps': _accessResponseTimestamps,
        'gotWhatNeeded': _gotWhatNeeded,
        if (_gotWhatNeeded != null)
          'gotWhatNeededRecordedAt':
              DateTime.now().toUtc().toIso8601String(),
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
    return FeatureSessionScope(
      feature: 'user-feedback',
      entrySource: 'care_navigation_survey',
      child: Scaffold(
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
                      } else if (_step == 'outcome') {
                        setState(() {
                          _step = 'access';
                          if (_selectedNeeds.isNotEmpty) {
                            final last =
                                _selectedNeeds[_selectedNeeds.length - 1];
                            _accessResponses.remove(last);
                            _accessResponseTimestamps.remove(last);
                            _currentNeedIndex = _selectedNeeds.length - 1;
                          }
                        });
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

              if (_step == 'outcome') _buildOutcomeStep(),

              // Complete Step
              if (_step == 'complete') _buildCompleteStep(),
            ],
          ),
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
          'Let’s check in on your care',
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
          'Sharing what you need helps us understand how to better support you. This takes about 2 minutes and is completely private.',
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.shadowSoft(opacity: 0.1, blur: 24, y: 8),
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
                      'This is just for you',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your answers are private and help us understand what support you might need. You can skip any question at any time.',
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
              foregroundColor: AppTheme.brandWhite,
              padding: const EdgeInsets.symmetric(vertical: 18),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
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
          'What support have you needed recently?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select any that apply — it’s okay if you don’t need any of these',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 24),

        // Needs List
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.shadowSoft(opacity: 0.1, blur: 24, y: 8),
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
                              ? Icon(Icons.check, color: AppTheme.brandWhite, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            need['label']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                              color: isSelected ? AppTheme.brandWhite : AppTheme.textPrimary,
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
                onPressed: () async {
                  if (_selectedNeeds.isEmpty) {
                    await _saveSurveyResults();
                    if (mounted) setState(() => _step = 'complete');
                  } else {
                    setState(() {
                      _step = 'access';
                      _currentNeedIndex = 0;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: AppTheme.brandWhite,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
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
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppTheme.shadowSoft(opacity: 0.08, blur: 20, y: 5),
                    border: Border.all(
                      color: AppTheme.borderLight.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    option['label']!,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
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

  Widget _buildOutcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
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
                decoration: const BoxDecoration(
                  color: Color(0xFFD4A574),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Almost done',
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
        Text(
          'Overall, did you get what you needed?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This is a big-picture check-in after the areas you picked.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        ..._outcomeOptions.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _submitGotWhatNeeded(opt['value']!),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.shadowSoft(opacity: 0.08, blur: 20, y: 5),
                  border: Border.all(
                    color: AppTheme.borderLight.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  opt['label']!,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }),
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
            'Thank you for trusting us',
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
            'Sharing what you need takes courage. Your voice helps us understand how to better support you and others.',
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
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5EEE0), Color(0xFFFAF8F4), Color(0xFFEBE0D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight.withOpacity(0.45)),
              boxShadow: AppTheme.shadowSoft(opacity: 0.1, blur: 24, y: 6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite_border_rounded, color: const Color(0xFFD4A574), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You’ve taken an important step. When you’re ready, you can explore providers, learning topics, or your visit summaries in the app — at your own pace.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: AppTheme.brandWhite,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 18,
              ),
              minimumSize: const Size(200, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}
