import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_router.dart';
import '../cors/ui_theme.dart';
import '../birthplan/birth_plans_list_screen.dart';
import '../appointments/appointments_list_screen.dart';
import '../appointments/visit_summary_preview.dart';
import '../services/database_service.dart';
import '../services/firebase_functions_service.dart';
import '../utils/pregnancy_utils.dart';
import 'learning_todo_widget.dart';
import 'Learning Modules/learning_module_detail_screen.dart';
import '../widgets/ai_disclaimer_banner.dart';
import '../models/user_profile.dart';
import 'widgets/home_milestone_bell.dart';
import '../assistant/assistant_screen.dart';
import '../emotional_support/widgets/home_emotional_support_card.dart';
import '../support_stage/support_stage.dart';
import '../support_stage/support_stage_scope.dart';
import '../pregnancy_loss/widgets/pregnancy_loss_home_learning_hero_card.dart';
import '../widgets/home_provider_search_entry.dart';

/// Starter prompts when opening the assistant from Understand Your Care cards.
const String _kAssistantPromptTestMeaning =
    "I have a test or result I don't understand. Can you explain it in simple terms?";
const String _kAssistantPromptIsThisNormal =
    "I'm wondering if something I'm feeling is normal. Can you help me understand?";

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserProfile? _userProfile;
  StreamSubscription<UserProfile?>? _profileSubscription;
  String? _visitStreamUserId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _latestVisitStream;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenToProfile();
    _ensureLatestVisitStream();
  }

  /// One stream per signed-in user so profile rebuilds do not reset to "Loading…".
  void _ensureLatestVisitStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _visitStreamUserId = null;
      _latestVisitStream = null;
      return;
    }
    if (_visitStreamUserId == uid && _latestVisitStream != null) return;
    _visitStreamUserId = uid;
    _latestVisitStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('visit_summaries')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();
  }

  void _listenToProfile() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    _profileSubscription?.cancel();
    _profileSubscription =
        _databaseService.streamUserProfile(userId).listen((profile) {
      if (mounted) {
        setState(() => _userProfile = profile);
      }
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final profile = await _databaseService.getUserProfile(userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    }
  }

  Future<void> _openEmotionalSupportCheckIn() async {
    await Navigator.pushNamed(context, Routes.emotionalSupportCheckin);
    await _loadUserData();
  }

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
    
    if (mounted) {
      setState(() {});
    }
  }

  void _showTodoModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.shadowMedium(opacity: 0.14, blur: 28, y: 10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryActionGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Learning Modules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.brandWhite,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.brandWhite),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
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

  /// Short preview for the home “My Visits” card (matches list preview behavior).
  String? _previewLineFromVisitData(Map<String, dynamic> data) {
    return previewLineFromVisitSummary(data);
  }

  String _visitDateLabel(Map<String, dynamic> data) {
    final appointmentDate = data['appointmentDate'];
    if (appointmentDate == null) return 'Recent visit';
    if (appointmentDate is Timestamp) {
      return DateFormat('MMM d, yyyy').format(appointmentDate.toDate());
    }
    if (appointmentDate is String) {
      try {
        return DateFormat('MMM d, yyyy').format(DateTime.parse(appointmentDate));
      } catch (_) {
        return 'Recent visit';
      }
    }
    return 'Recent visit';
  }

  String _visitDescriptionFromData(Map<String, dynamic> data) {
    final preview = _previewLineFromVisitData(data);
    if (preview != null && preview.isNotEmpty) return preview;

    final providerName = data['providerName'] as String?;
    final practiceName = data['practiceName'] as String?;
    final provider = data['provider'] as String?;

    if (providerName != null && providerName.isNotEmpty) {
      if (practiceName != null && practiceName.isNotEmpty) {
        return '$providerName • $practiceName';
      }
      return providerName;
    }
    if (provider != null && provider.isNotEmpty) return provider;
    if (practiceName != null && practiceName.isNotEmpty) return practiceName;
    return '';
  }

  void _openAppointmentsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppointmentsListScreen(),
      ),
    );
  }

  Widget _buildLatestVisitCard(Map<String, dynamic> data) {
    return _AppointmentCard(
      overline: 'My Visits',
      title: _visitDateLabel(data),
      subtitle: 'Latest summarized visit',
      description: _visitDescriptionFromData(data),
      compact: true,
      onTap: _openAppointmentsList,
    );
  }

  Widget _buildLatestVisitSection() {
    _ensureLatestVisitStream();
    final stream = _latestVisitStream;
    if (stream == null) {
      return _AppointmentCard(
        overline: null,
        title: 'Know what to ask at your next visit',
        subtitle:
            "We'll help you understand your care and speak up with confidence.",
        description: '',
        durationLabel: '2 minutes',
        compact: true,
        onTap: _openAppointmentsList,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final waitingWithoutData = snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData;
        if (waitingWithoutData) {
          return _AppointmentCard(
            overline: 'My Visits',
            title: 'Loading...',
            subtitle: 'One moment',
            description: '',
            onTap: () {},
            compact: true,
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _AppointmentCard(
            overline: null,
            title: 'Know what to ask at your next visit',
            subtitle:
                "We'll help you understand your care and speak up with confidence.",
            description: '',
            durationLabel: '2 minutes',
            compact: true,
            onTap: _openAppointmentsList,
          );
        }

        final data = snapshot.data!.docs.first.data();
        return _buildLatestVisitCard(data);
      },
    );
  }

  UserProfile? get _effectiveProfile =>
      SupportStageScope.profileOf(context) ?? _userProfile;

  @override
  Widget build(BuildContext context) {
    final profile = _effectiveProfile;
    final inLossMode = profile?.isInPregnancyLossMode == true;
    final dueDate = profile?.dueDate;
    final weeksPregnant = PregnancyUtils.calculateWeeksPregnant(dueDate);
    final displayWeek = weeksPregnant > 0 ? weeksPregnant : 1;
    final trimester = PregnancyUtils.calculateTrimester(dueDate);
    final progress = (weeksPregnant > 0 ? weeksPregnant : 1) / 40.0;
    final showWeekJourneyCard = !inLossMode &&
        dueDate != null &&
        !(profile?.hidePregnancyMilestones ?? false);
    final showLossLearningHero = inLossMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting (NewUI Home.tsx) + research milestone bell
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inLossMode
                                    ? 'We\'re here for you 🤍'
                                    : 'Welcome, Mama 🤍',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                  letterSpacing: -0.32,
                                  color: Color(0xFF2D2235),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                inLossMode
                                    ? 'Clear guides, journal space, and community support — at your pace.'
                                    : "You're supported — with clear answers and tools to speak up.",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                  height: 1.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 24),
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.assistant);
                                },
                                borderRadius: BorderRadius.circular(28),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: const Color(0xFFE8DFE8),
                                    ),
                                    boxShadow: AppTheme.shadowSoft(),
                                  ),
                                  child: TextField(
                                    enabled: false,
                                    style: const TextStyle(
                                      color: Color(0xFF2D2733),
                                      fontWeight: FontWeight.w300,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search symptoms, tests, or what to ask your doctor',
                                      hintStyle: TextStyle(
                                        color: const Color(0xFFB5A8C2),
                                        fontWeight: FontWeight.w300,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Color(0xFF9D8FB5),
                                        size: 20,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        HomeMilestoneBell(
                          key: ValueKey<String>(
                            '${profile?.userId ?? 'none'}_${profile?.isResearchParticipant ?? false}',
                          ),
                          profile: profile,
                        ),
                      ],
                    ),
                  ),

                  // Loss mode: same hero card layout → “What to expect” learning guide
                  if (showLossLearningHero) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: PregnancyLossHomeLearningHeroCard(),
                    ),
                  ],

                  // Week / trimester journey card → Learn tab (trimester modules)
                  if (showWeekJourneyCard) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            Routes.learning,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF663399),
                                  Color(0xFF7744AA),
                                  Color(0xFF8855BB),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF663399).withOpacity(0.25),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.antiAlias,
                              children: [
                                Positioned(
                                  top: -20,
                                  left: MediaQuery.sizeOf(context).width * 0.2,
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFD4A574)
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -40,
                                  right: 20,
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFB899D4)
                                          .withOpacity(0.18),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandWhite.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color:
                                                AppTheme.brandWhite.withOpacity(0.2),
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
                                              'Week $displayWeek',
                                              style: TextStyle(
                                                color: const Color(0xFFF5F0F7),
                                                fontSize: 12,
                                                letterSpacing: 0.36,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        PregnancyUtils.trimesterDisplayTitle(
                                            trimester),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w400,
                                          height: 1.35,
                                          letterSpacing: -0.28,
                                          color: Color(0xFFF5F0F7),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Here's what's happening — and what to ask at your next visit.",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300,
                                          height: 1.5,
                                          color: Color(0xFFE8DFF0),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.brandWhite.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor:
                                              progress.clamp(0.0, 1.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFD4A574),
                                                  Color(0xFFE0B589),
                                                  Color(0xFFEDC799),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFD4A574)
                                                      .withOpacity(0.5),
                                                  blurRadius: 12,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '$displayWeek of 40 weeks',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: 0.5,
                                          color: const Color(0xFFE8DFF0)
                                              .withOpacity(0.95),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Today's Guidance (primary hero + visit summary widget)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "💜 TODAY'S GUIDANCE",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: AppTheme.brandPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        HomeEmotionalSupportCard(
                          onCheckIn: _openEmotionalSupportCheckIn,
                          compact: true,
                        ),
                        if (!inLossMode) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.careSurvey);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF5EEE0),
                                    Color(0xFFFAF8F4),
                                    Color(0xFFEBE0D6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE8E0F0)
                                      .withOpacity(0.4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.brandPurple.withOpacity(0.12),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFD4A574)
                                            .withOpacity(0.08),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                gradient:
                                                    const LinearGradient(
                                                  colors: [
                                                    Color(0xFFF5EEE0),
                                                    Color(0xFFEBE0D6),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.08),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.auto_awesome_rounded,
                                                color: Color(0xFFD4A574),
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Care Check In',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w400,
                                                      letterSpacing: -0.085,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Share what support you need — about 2 minutes.',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w300,
                                                      height: 1.45,
                                                      color: AppTheme.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Text(
                                              '2 minutes',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w300,
                                                color: AppTheme.textMuted
                                                    .withOpacity(0.85),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.chevron_right,
                                              size: 18,
                                              color: AppTheme.textMuted
                                                  .withOpacity(0.85),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ],
                        const SizedBox(height: 12),
                        _buildLatestVisitSection(),
                      ],
                    ),
                  ),

                  // Understand Your Care — quick paths to explanation features
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UNDERSTAND YOUR CARE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: AppTheme.brandPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        HomeProviderSearchEntry(
                          title: 'Find your care team',
                          subtitle: 'Search providers by ZIP, city, and type of care',
                          onTap: () =>
                              Navigator.pushNamed(context, Routes.providers),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _CareToolCard(
                                icon: Icons.science_outlined,
                                iconGradient: const [
                                  Color(0xFFE8E0F0),
                                  Color(0xFFD8CFE5),
                                ],
                                iconColor: AppTheme.brandPurple,
                                title: 'What does this test mean?',
                                subtitle:
                                    'Labs and visit notes—plain language',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const AssistantScreen(
                                      initialPrompt: _kAssistantPromptTestMeaning,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _CareToolCard(
                                icon: Icons.help_outline_rounded,
                                iconGradient: const [
                                  Color(0xFFF5EEE0),
                                  Color(0xFFEBE0D6),
                                ],
                                iconColor: const Color(0xFFD4A574),
                                title: 'Is this normal?',
                                subtitle:
                                    "What's typical—and when to reach out",
                                onTap: () {
                                  final due = profile?.dueDate;
                                  final weeks =
                                      PregnancyUtils.calculateWeeksPregnant(due);
                                  if (due != null && weeks > 0) {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.pregnancyJourney,
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => const AssistantScreen(
                                          initialPrompt: _kAssistantPromptIsThisNormal,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _CareToolCard(
                          icon: Icons.shield_outlined,
                          iconGradient: const [
                            Color(0xFFE8E0F0),
                            Color(0xFFEDE7F3),
                          ],
                          iconColor: const Color(0xFF8B7AA8),
                          title: 'Know your rights in care',
                          subtitle:
                              'Questions, consent, and respectful care',
                          onTap: () =>
                              Navigator.pushNamed(context, Routes.rights),
                        ),
                      ],
                    ),
                  ),

                  // Your space — Visits, Journal, Birth preferences, Next steps (NewUI order)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your space',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.04,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _CareToolCard(
                              icon: Icons.article_outlined,
                              iconGradient: const [
                                Color(0xFFE8E0F0),
                                Color(0xFFD8CFE5),
                              ],
                              iconColor: AppTheme.brandPurple,
                              title: 'My Visits & What It Means',
                              subtitle: 'Summaries & notes',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AppointmentsListScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CareToolCard(
                              icon: Icons.favorite_border,
                              iconGradient: const [
                                Color(0xFFF5EEE0),
                                Color(0xFFEBE0D6),
                              ],
                              iconColor: const Color(0xFFD4A574),
                              title: "How I'm Feeling",
                              subtitle: 'Your private space',
                              onTap: () => Navigator.pushNamed(
                                  context, Routes.journal),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (inLossMode)
                        _CareToolCard(
                          icon: Icons.menu_book_outlined,
                          iconGradient: const [
                            Color(0xFFE8E0F0),
                            Color(0xFFD8CFE5),
                          ],
                          iconColor: AppTheme.brandPurple,
                          title: 'Learning guides',
                          subtitle: 'Recovery, visits, and follow-up care',
                          onTap: () => Navigator.pushNamed(
                            context,
                            Routes.learning,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _CareToolCard(
                                icon: Icons.description_outlined,
                                iconGradient: const [
                                  Color(0xFFE8E0F0),
                                  Color(0xFFD8CFE5),
                                ],
                                iconColor: AppTheme.brandPurple,
                                title: 'My Birth Choices',
                                subtitle: "What's right for you",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BirthPlansListScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _CareToolCard(
                                icon: Icons.menu_book_outlined,
                                iconGradient: const [
                                  Color(0xFFE8E0F0),
                                  Color(0xFFD8CFE5),
                                ],
                                iconColor: AppTheme.brandPurple,
                                title: 'My Care Plan',
                                subtitle: 'Your personalized path',
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  Routes.learning,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Community (NewUI: conversational header + belonging copy)
                  Text(
                    'FROM THE COMMUNITY 💬',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.community),
                      borderRadius: BorderRadius.circular(24),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFAF7F3),
                              Color(0xFFF5F0EB),
                              Color(0xFFF0EAD8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE8DFC8).withOpacity(0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4A574).withOpacity(0.15),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFD4A574)
                                      .withOpacity(0.06),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFF5EEE0),
                                              Color(0xFFEBE0D6),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.06),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.favorite_border,
                                          color: Color(0xFFD4A574),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Welcome to EmpowerHealth Watch',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w400,
                                                letterSpacing: -0.085,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "You're not alone here. Connect with other moms, share your journey, and find support from those who understand.",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w300,
                                                height: 1.5,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Text(
                                        'Explore community',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w300,
                                          color: AppTheme.textMuted
                                              .withOpacity(0.85),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                        color: AppTheme.textMuted
                                            .withOpacity(0.85),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Helper functions for home screen
  Widget _buildModuleCardFromData(
    Map<String, dynamic> data,
    IconData Function(String) getIcon,
    Map<String, Color> Function(String) getColors,
    BuildContext context,
  ) {
    final title = (data['title'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final content = data['content'];
    final contentString = content is String 
        ? content 
        : (content is Map ? content.toString() : '');
    final colors = getColors(title);
    final icon = getIcon(title);

    return InkWell(
      onTap: () {
        if (contentString.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LearningModuleDetailScreen(
                title: title,
                content: contentString,
                icon: '📚',
              ),
            ),
          );
        } else {
          Navigator.pushNamed(context, Routes.learning);
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderLight.withOpacity(0.6)),
          boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 16, y: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors['bg']!,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: colors['icon']!, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description.isNotEmpty ? description : 'Learning module',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? description;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback onTap;

  const _SupportCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.description,
    this.gradient,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? AppTheme.surfaceCard : null,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: borderColor ?? AppTheme.borderLight,
            width: 1,
          ),
          boxShadow: gradient == null ? AppTheme.shadowSoft() : AppTheme.shadowSoft(opacity: 0.1, blur: 22, y: 5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient == null
                    ? LinearGradient(
                        colors: [
                          AppTheme.gradientBeigeStart.withOpacity(0.6),
                          AppTheme.gradientBeigeEnd.withOpacity(0.6),
                        ],
                      )
                    : null,
                color: gradient == null ? iconBg : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textBarelyVisible, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.shadowSoft(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.gradientBeigeStart.withOpacity(0.6),
                    AppTheme.gradientBeigeEnd.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.textLightest,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String? overline;
  final String title;
  final String subtitle;
  final String description;
  final String? durationLabel;
  final bool compact;
  final VoidCallback onTap;

  const _AppointmentCard({
    this.overline,
    required this.title,
    required this.subtitle,
    required this.description,
    this.durationLabel,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(compact ? 16 : 20),
            border: Border.all(
              color: const Color(0xFFE8E0F0).withOpacity(0.4),
            ),
            boxShadow: AppTheme.shadowSoft(
              opacity: compact ? 0.08 : 0.1,
              blur: compact ? 14 : 22,
              y: compact ? 4 : 6,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 40 : 48,
                  height: compact ? 40 : 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE8E0F0),
                        Color(0xFFD8CFE5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    color: AppTheme.brandPurple,
                    size: compact ? 18 : 20,
                  ),
                ),
                SizedBox(width: compact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (overline != null && overline!.isNotEmpty) ...[
                        Text(
                          overline!,
                          style: TextStyle(
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                            color: AppTheme.textMuted.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.12,
                          color: const Color(0xFF2D2235),
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: compact ? 12 : 14,
                            fontWeight: FontWeight.w300,
                            height: 1.45,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: compact ? 12 : 14,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.textMuted.withOpacity(0.85),
                          ),
                        ),
                      ],
                      if (durationLabel != null &&
                          durationLabel!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              durationLabel!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: AppTheme.textMuted.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppTheme.textMuted.withOpacity(0.85),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (durationLabel == null || durationLabel!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.chevron_right,
                      color: AppTheme.textMuted.withOpacity(0.7),
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CareToolCard extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? borderColor;
  final VoidCallback onTap;

  const _CareToolCard({
    required this.icon,
    required this.iconGradient,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: borderColor != null
              ? LinearGradient(
                  colors: iconGradient,
                )
              : null,
          color: borderColor == null ? AppTheme.surfaceCard : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor ?? const Color(0xFFE8E0F0).withOpacity(0.4),
          ),
          boxShadow: AppTheme.shadowSoft(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, // w-11
              height: 44, // h-11
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconGradient,
                ),
                borderRadius: BorderRadius.circular(18), // rounded-[18px]
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20, // w-5 h-5
              ),
            ),
            const SizedBox(height: 12), // mb-3
            Text(
              title,
              style: TextStyle(
                fontSize: 14, // text-sm
                fontWeight: FontWeight.w400, // font-normal
                color: Color(0xFF2D2733), // text-[#2d2733]
              ),
            ),
            const SizedBox(height: 4), // mb-1
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12, // text-xs
                color: Color(0xFF9D8FB5), // text-[#9d8fb5]
                fontWeight: FontWeight.w300, // font-light
              ),
            ),
          ],
        ),
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
  int _totalModules = 8;

  @override
  void initState() {
    super.initState();
    _generateModules();
  }

  Future<void> _generateModules() async {
    final trimester = PregnancyUtils.calculateTrimester(widget.profile.dueDate);
    final userId = widget.profile.userId;

    final profileData = {
      'chronicConditions': widget.profile.chronicConditions ?? [],
      'healthLiteracyGoals': widget.profile.healthLiteracyGoals ?? [],
      'insuranceType': widget.profile.insuranceType ?? '',
      'providerPreferences': widget.profile.providerPreferences ?? [],
      'educationLevel': widget.profile.educationLevel ?? '',
    };

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

    if (widget.profile.chronicConditions != null && widget.profile.chronicConditions.isNotEmpty) {
      modules.add({
        'title': 'Managing ${widget.profile.chronicConditions.first}',
        'description': 'Special considerations during pregnancy',
      });
      _totalModules = 9;
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

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Error generating module: $e');
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 48,
              color: Color(0xFF663399),
            ),
            const SizedBox(height: 16),
            const Text(
              'Creating Your Learning Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF663399),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // AI Disclaimer Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AIDisclaimerBanner(
                customMessage: 'This tool helps you understand your care.',
                customSubMessage: 'It does not replace your provider.',
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF663399)),
                minHeight: 8,
              ),
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
