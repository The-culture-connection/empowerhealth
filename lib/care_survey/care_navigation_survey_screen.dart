import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_router.dart';
import '../beta/beta_checklist_service.dart';
import '../birthplan/birth_plans_list_screen.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../research/navigation_outcome_prompt.dart';
import '../research/needs_checklist_screen.dart';
import '../resources/app_external_resources.dart';
import '../resources/open_app_resource.dart';
import 'care_checkin_learning_module.dart';
import 'care_checkin_navigation.dart';
import 'care_checkin_support_config.dart';
import 'care_checkin_support_screen.dart';
import '../services/database_service.dart';
import '../services/research/research_firestore_service.dart';
import '../services/research/research_navigation_outcome_service.dart';
import '../services/research/research_needs_checklist_service.dart';
import '../widgets/feature_session_scope.dart';
import '../widgets/step_scroll.dart';

class CareNavigationSurveyScreen extends StatefulWidget {
  const CareNavigationSurveyScreen({super.key});

  @override
  State<CareNavigationSurveyScreen> createState() => _CareNavigationSurveyScreenState();
}

class _CareNavigationSurveyScreenState extends State<CareNavigationSurveyScreen> {
  String _step = 'needs'; // 'needs', 'support', 'access', 'outcome', 'complete'
  List<String> _selectedNeeds = [];
  Map<String, String> _accessResponses = {};
  Map<String, String> _accessResponseTimestamps = {};
  int _currentNeedIndex = 0;
  String? _gotWhatNeeded;
  /// Set when a research participant leaves the needs step (Phase 3 row); used for Phase 4 outcome submit.
  String? _needsChecklistEventId;
  bool _submittingNeedsChecklist = false;
  bool _requiresResearchAccessStep = false;
  final List<String> _openedSupportActionIds = [];

  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _otherNeedDetailController = TextEditingController();
  final StepScrollController _scrollController = StepScrollController();

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
        if (_selectedNeeds.contains('other') && _otherNeedDetailController.text.trim().isNotEmpty)
          'otherNeedDetail': _otherNeedDetailController.text.trim(),
        'accessResponses': _accessResponses,
        'accessResponseTimestamps': _accessResponseTimestamps,
        'gotWhatNeeded': _gotWhatNeeded,
        if (_gotWhatNeeded != null)
          'gotWhatNeededRecordedAt':
              DateTime.now().toUtc().toIso8601String(),
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
        if (_openedSupportActionIds.isNotEmpty)
          'openedSupportActionIds': List<String>.from(_openedSupportActionIds),
      };

      await FirebaseFirestore.instance
          .collection('CareSurvey')
          .add(surveyData);

      // Submitting logs no analytics event, so tick the beta item directly.
      unawaited(BetaChecklistService.instance.markDone('care_checkin'));

      try {
        final profile = await _databaseService.getUserProfile(userId);
        if (profile != null && profile.isResearchParticipant) {
          final sid = await ResearchFirestoreService.instance.ensureStudyId(profile);
          final needsId = _needsChecklistEventId;
          final accessComplete =
              _selectedNeeds.every((id) => (_accessResponses[id] ?? '').isNotEmpty);
          if (sid != null && needsId != null && _selectedNeeds.isNotEmpty && accessComplete) {
            final payload = ResearchNavigationOutcomeService.buildOutcomePayload(
              studyId: sid,
              needsEventId: needsId,
              selectedCareNeedIds: List<String>.from(_selectedNeeds),
              accessResponsesByCareId: Map<String, String>.from(_accessResponses),
            );
            await ResearchNavigationOutcomeService.instance.submitNavigationOutcome(payload);
          }
        }
      } catch (e) {
        print('⚠️ [CareSurvey] Research navigation outcome: $e');
      }

      print('✅ [CareSurvey] Survey results saved to Firestore');
    } catch (e) {
      print('❌ [CareSurvey] Error saving survey results: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving survey: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Opens an in-app destination *in place of* the check-in: [open] pushes the
  /// destination (using the navigator's own context, which stays valid after
  /// this screen is gone), then the survey route is removed from underneath
  /// it. Closing the destination therefore returns to wherever the check-in
  /// was opened from (Home), not back into the survey. Only this survey's own
  /// route is removed, so nothing below it (the main tab scaffold, or the
  /// auth route under it after login) is ever popped.
  void _openInPlaceOfSurvey(void Function(BuildContext navContext) open) {
    final navigator = Navigator.of(context);
    final surveyRoute = ModalRoute.of(context);
    open(navigator.context);
    if (surveyRoute != null && surveyRoute.isActive && !surveyRoute.isFirst) {
      navigator.removeRoute(surveyRoute);
    }
  }

  /// Switches to a main tab when the tab scaffold is reachable; otherwise
  /// opens the standalone [fallbackRoute] in place of the survey.
  void _goToTabOrOpen(int tabIndex, String fallbackRoute) {
    if (MainNavigationScope.goToTab(context, tabIndex)) return;
    _openInPlaceOfSurvey(
      (nav) => Navigator.pushNamed(nav, fallbackRoute),
    );
  }

  void _openSupportAction(CareSupportAction action) {
    if (!_openedSupportActionIds.contains(action.id)) {
      _openedSupportActionIds.add(action.id);
    }
    final prompt = action.assistantPrompt;
    switch (action.destination) {
      case CareSupportDestination.providers:
        _openInPlaceOfSurvey(
          (nav) => Navigator.pushNamed(nav, Routes.providers),
        );
        break;
      case CareSupportDestination.visitSummaries:
        _openInPlaceOfSurvey((nav) {
          if (action.preferLatestVisitSummary) {
            unawaited(openActiveVisitSummaryForPrepare(nav));
          } else {
            unawaited(openVisitSummariesList(nav));
          }
        });
        break;
      case CareSupportDestination.assistant:
        _openInPlaceOfSurvey(
          (nav) =>
              Navigator.pushNamed(nav, Routes.assistant, arguments: prompt),
        );
        break;
      case CareSupportDestination.pregnancyJourney:
        _openInPlaceOfSurvey(
          (nav) => Navigator.pushNamed(nav, Routes.pregnancyJourney),
        );
        break;
      case CareSupportDestination.birthPlans:
        _openInPlaceOfSurvey(
          (nav) => Navigator.push(
            nav,
            MaterialPageRoute(builder: (_) => const BirthPlansListScreen()),
          ),
        );
        break;
      case CareSupportDestination.learnTab:
        _goToTabOrOpen(MainNavigationScope.tabLearn, Routes.learning);
        break;
      case CareSupportDestination.rights:
        _openInPlaceOfSurvey(
          (nav) => Navigator.pushNamed(nav, Routes.rights),
        );
        break;
      case CareSupportDestination.externalUrl:
        // Opens the browser; the check-in stays put so the user returns to it.
        final url = action.externalUrl;
        if (url != null && url.isNotEmpty) {
          unawaited(launchAppExternalUrl(context, url));
        }
        break;
      case CareSupportDestination.resources:
        _openInPlaceOfSurvey(
          (nav) => unawaited(
            openAppResourcesScreen(
              nav,
              highlightResourceId: action.resourceId,
              categoryFilter:
                  appResourceCategoryForResourceId(action.resourceId),
            ),
          ),
        );
        break;
      case CareSupportDestination.birthLaborTopic:
        _openInPlaceOfSurvey(
          (nav) => openBirthLaborTopicById(
            nav,
            action.birthLaborTopicId ?? 'labor-basics',
          ),
        );
        break;
      case CareSupportDestination.generateLearningModule:
        final topic = action.learningModuleTopic ?? action.label;
        final description =
            action.learningModuleDescription ?? 'Created from your care check-in.';
        _openInPlaceOfSurvey(
          (nav) => unawaited(
            generateAndOpenCareCheckinLearningModule(
              nav,
              topic: topic,
              description: description,
              sourceActionId: action.id,
            ),
          ),
        );
        break;
      case CareSupportDestination.journal:
        _goToTabOrOpen(MainNavigationScope.tabJournal, Routes.journal);
        break;
      case CareSupportDestination.community:
        _goToTabOrOpen(MainNavigationScope.tabCommunity, Routes.community);
        break;
    }
  }

  Future<void> _handleSupportContinue() async {
    if (_selectedNeeds.isEmpty) {
      await _saveSurveyResults();
      if (mounted) setState(() => _step = 'complete');
      return;
    }
    if (_requiresResearchAccessStep && _needsChecklistEventId != null) {
      setState(() {
        _step = 'access';
        _currentNeedIndex = 0;
        _accessResponses = {};
        _accessResponseTimestamps = {};
      });
      return;
    }
    setState(() => _step = 'outcome');
  }

  Future<void> _handleNeedsContinue() async {
    if (_selectedNeeds.contains('other') && _otherNeedDetailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add a few words for “Something else” or deselect it.',
          ),
        ),
      );
      return;
    }

    if (_selectedNeeds.isEmpty) {
      setState(() {
        _needsChecklistEventId = null;
        _requiresResearchAccessStep = false;
        _step = 'support';
      });
      return;
    }

    setState(() => _submittingNeedsChecklist = true);
    try {
      String? eventId;
      var researchAccess = false;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final profile = await _databaseService.getUserProfile(userId);
        if (profile != null && profile.isResearchParticipant) {
          researchAccess = true;
          final sid = await ResearchFirestoreService.instance.ensureStudyId(profile);
          if (sid != null) {
            eventId = await ResearchNeedsChecklistService.instance.submitNeedsChecklist(
              studyId: sid,
              selectedCareNeedIds: List<String>.from(_selectedNeeds),
              otherText: _selectedNeeds.contains('other')
                  ? _otherNeedDetailController.text.trim()
                  : null,
            );
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _submittingNeedsChecklist = false;
        _needsChecklistEventId = eventId;
        _requiresResearchAccessStep = researchAccess && eventId != null;
        _step = 'support';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _submittingNeedsChecklist = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not continue: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _leaveAccessStepBackToSupport() {
    setState(() {
      _step = 'support';
      _accessResponses.clear();
      _accessResponseTimestamps.clear();
      _currentNeedIndex = 0;
    });
  }

  @override
  void dispose() {
    _otherNeedDetailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Each step (and each need on the access step) starts at the top.
    _scrollController.syncStep(
      _step == 'access' ? 'access-$_currentNeedIndex' : _step,
    );
    return FeatureSessionScope(
      feature: 'user-feedback',
      entrySource: 'care_navigation_survey',
      child: Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Navigation (not on complete step)
              if (_step != 'complete')
                HearthPushedHeader(
                  padding: const EdgeInsets.only(bottom: 16),
                  backLabel: _step == 'needs' ? 'Home' : 'Back',
                  onBack: () {
                      if (_step == 'support') {
                        setState(() => _step = 'needs');
                      } else if (_step == 'outcome') {
                        if (_requiresResearchAccessStep &&
                            _selectedNeeds.isNotEmpty) {
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
                        } else {
                          setState(() => _step = 'support');
                        }
                      } else if (_step == 'access') {
                        if (_currentNeedIndex > 0) {
                          setState(() => _currentNeedIndex--);
                        } else {
                          _leaveAccessStepBackToSupport();
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
                ),

              if (_step == 'needs')
                NeedsChecklistScreen(
                  selectedNeedIds: _selectedNeeds,
                  onToggleNeed: _toggleNeed,
                  otherDetailController: _otherNeedDetailController,
                  onBack: () => Navigator.pop(context),
                  onContinue: _handleNeedsContinue,
                  isContinueBusy: _submittingNeedsChecklist,
                ),

              if (_step == 'support')
                CareCheckinSupportScreen(
                  selectedNeedIds: _selectedNeeds,
                  otherDetailController: _otherNeedDetailController,
                  onOpenAction: _openSupportAction,
                  onBack: () => setState(() => _step = 'needs'),
                  onContinue: () => _handleSupportContinue(),
                ),

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

  Widget _buildAccessStep() {
    final currentNeed = _selectedNeeds[_currentNeedIndex];
    final currentNeedLabel = kCareNeedsChecklistItems.firstWhere(
      (n) => n['id'] == currentNeed,
      orElse: () => {'id': '', 'label': ''},
    )['label'] ?? '';

    return NavigationOutcomePrompt(
      currentIndex: _currentNeedIndex,
      totalNeeds: _selectedNeeds.length,
      needLabel: currentNeedLabel,
      accessOptions: _accessOptions,
      onSelectOption: (v) => _handleAccessResponse(v),
      onBack: () {
        if (_currentNeedIndex > 0) {
          setState(() => _currentNeedIndex--);
        } else {
          _leaveAccessStepBackToSupport();
        }
      },
    );
  }

  Widget _buildOutcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: const ShapeDecoration(
            color: AppTheme.surface,
            shape: StadiumBorder(side: BorderSide(color: AppTheme.borderWarm)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.brandGold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Almost done',
                style: hearthCaptionStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Overall, did you get the care and support you needed?',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 6),
        Text(
          'A quick big-picture check-in after the areas you picked.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        ..._outcomeOptions.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HearthCard(
              onTap: () => _submitGotWhatNeeded(opt['value']!),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  opt['label']!,
                  style: const TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 15,
                    height: 22 / 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
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
          const SizedBox(height: 56),
          const HearthIconChip(Icons.favorite_border, size: 80, iconSize: 36),
          const SizedBox(height: 24),

          Text(
            'Thank you for trusting us',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            'Sharing what you need takes courage. Your voice helps us understand how to better support you and others.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          HearthNote(
            icon: Icons.favorite_border,
            padding: const EdgeInsets.all(18),
            child: Text(
              'You’ve taken an important step. When you’re ready, you can explore providers, learning topics, or your visit summaries in the app, at your own pace.',
              style: hearthCardBodyStyle.copyWith(color: AppTheme.ink),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 52),
              padding: const EdgeInsets.symmetric(horizontal: 32),
            ),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}
