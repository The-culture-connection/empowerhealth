import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_router.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../birthplan/birth_plans_list_screen.dart';
import '../appointments/appointments_list_screen.dart';
import '../appointments/visit_summary_preview.dart';
import '../services/database_service.dart';
import '../services/firebase_functions_service.dart';
import '../utils/pregnancy_utils.dart';
import 'learning_todo_widget.dart';
import 'Learning Modules/learning_module_detail_screen.dart';
import 'Learning Modules/learning_modules_screen_v2.dart' show openTrimesterJourney;
import '../widgets/ai_disclaimer_banner.dart';
import '../models/user_profile.dart';
import 'widgets/home_milestone_bell.dart';
import '../assistant/assistant_screen.dart';
import '../immediate_support/immediate_support_navigation.dart';
import '../immediate_support/widgets/immediate_support_home_card.dart';
import '../support_stage/support_stage.dart';
import '../support_stage/support_stage_scope.dart';
import '../pregnancy_loss/pregnancy_loss_theme.dart';
import '../pregnancy_loss/widgets/pregnancy_loss_home_variant.dart';
import '../widgets/home_provider_search_entry.dart';

/// Starter prompts when opening the assistant from Understand Your Care cards.
const String _kAssistantPromptTestMeaning =
    "I have a test or result I don't understand. Can you explain it in simple terms?";
const String _kAssistantPromptIsThisNormal =
    "I'm wondering if something I'm feeling is normal. Can you help me understand?";

/// Non-breaking space: keeps short labels (e.g. "Second trimester") on one line.
final String _kNbsp = String.fromCharCode(0x00A0);

/// Opens a main tab (bottom tabs stay visible); pushes [route] only when the
/// app isn't inside the tab scaffold.
void _openTab(BuildContext context, int tab, String route) {
  if (!MainNavigationScope.goToTab(context, tab)) {
    Navigator.pushNamed(context, route);
  }
}

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

  Future<void> _openImmediateSupport() async {
    await openImmediateSupport(context, entrySource: 'home');
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
      barrierColor: AppTheme.scrim,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Learning Modules',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.ink),
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
        // Only show a real visit once data has actually arrived. While the
        // stream is still connecting, errored, or empty, fall back to the
        // helpful default card instead of a card that's stuck on "Loading...".
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return _buildLatestVisitCard(snapshot.data!.docs.first.data());
        }

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
      },
    );
  }

  UserProfile? get _effectiveProfile =>
      SupportStageScope.profileOf(context) ?? _userProfile;

  /// Pill that opens the assistant; it only looks like a search field.
  Widget _buildAssistantSearchField() {
    return Material(
      color: AppTheme.surface,
      shape: const StadiumBorder(side: BorderSide(color: AppTheme.borderWarm)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, Routes.assistant);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppTheme.brandPurple,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    enabled: false,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 22 / 15,
                      color: AppTheme.ink,
                    ),
                    // The theme's field box would draw a second outline
                    // inside the pill, so this field is bare.
                    decoration: const InputDecoration(
                      hintText: 'Search symptoms or topics',
                      hintMaxLines: 2,
                      hintStyle: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 15,
                        height: 22 / 15,
                      ),
                      filled: false,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _effectiveProfile;
    final inLossMode = profile?.isInPregnancyLossMode == true;
    final dueDate = profile?.dueDate;
    final weeksPregnant = PregnancyUtils.calculateWeeksPregnant(dueDate);
    final displayWeek = weeksPregnant > 0 ? weeksPregnant : 1;
    final trimester = PregnancyUtils.calculateTrimester(dueDate);
    final showWeekJourneyCard = !inLossMode &&
        dueDate != null &&
        !(profile?.hidePregnancyMilestones ?? false);
    const sectionGap = SizedBox(height: 28);
    const headingGap = SizedBox(height: 14);
    const cardGap = SizedBox(height: 12);
    return Scaffold(
      backgroundColor:
          inLossMode ? PregnancyLossTheme.background : Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Bottom inset keeps the last card clear of the floating support
              // button and bottom nav (SafeArea adds the nav/safe-area inset).
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Greeting + research milestone bell. Pregnancy-loss mode
                  // drops the decorative circle and underline.
                  HearthTabHeader(
                    warmCircle: !inLossMode,
                    titleWidget: _GreetingTitle(
                      text: inLossMode
                          ? 'We\'re here with you$_kNbsp'
                          : 'Welcome, Mama$_kNbsp',
                      underlineLastWord: !inLossMode,
                    ),
                    subtitle: inLossMode
                        ? 'Support is here when you\'re ready.'
                        : "You're supported, with clear answers and tools to speak up.",
                    trailing: inLossMode
                        ? null
                        : HomeMilestoneBell(
                            key: ValueKey<String>(
                              '${profile?.userId ?? 'none'}_${profile?.isResearchParticipant ?? false}',
                            ),
                            profile: profile,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  if (!inLossMode) ...[
                    _buildAssistantSearchField(),
                    sectionGap,
                  ],

                  if (inLossMode && profile != null) ...[
                    PregnancyLossHomeVariant(profile: profile),
                    const SizedBox(height: 24),
                    ImmediateSupportHomeCard(
                      entrySource: 'home_loss_mode',
                      compact: true,
                      quiet: true,
                    ),
                  ],

                  if (!inLossMode)
                  // Your space — Visits, Journal, Birth preferences, Next steps (NewUI order)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HearthSectionHeading('Your space'),
                      headingGap,
                      _CareToolPair(
                            first: _CareToolCard(
                              icon: Icons.article_outlined,
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
                            second: _CareToolCard(
                              icon: Icons.favorite_border,
                              title: "How I'm Feeling",
                              subtitle: 'Your private space',
                              onTap: () => _openTab(
                                  context, MainNavigationScope.tabJournal, Routes.journal),
                            ),
                      ),
                      cardGap,
                      if (inLossMode)
                        _CareToolCard(
                          icon: Icons.menu_book_outlined,
                          title: 'Learning guides',
                          subtitle: 'Recovery, visits, and follow-up care',
                          onTap: () => _openTab(
                            context,
                            MainNavigationScope.tabLearn,
                            Routes.learning,
                          ),
                        )
                      else
                        _CareToolPair(
                              first: _CareToolCard(
                                icon: Icons.description_outlined,
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
                              second: _CareToolCard(
                                icon: Icons.menu_book_outlined,
                                title: 'My Care Plan',
                                subtitle: 'Your personalized path',
                                onTap: () => _openTab(
                                  context,
                                  MainNavigationScope.tabLearn,
                                  Routes.learning,
                                ),
                              ),
                        ),
                    ],
                  ),
                  if (!inLossMode) sectionGap,

                  if (!inLossMode)
                  // Today's Guidance (primary hero + visit summary widget)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The no-break space is what is left of the removed
                        // emoji; trim keeps it from indenting the heading.
                        HearthSectionHeading(
                          "${_kNbsp}Today's guidance".trim(),
                        ),
                        headingGap,
                        ImmediateSupportHomeCard(
                          entrySource: 'home',
                          compact: true,
                          title:
                              'Understand your care, prepare questions, and find support.',
                          subtitle: '',
                          ctaLabel: 'See options',
                        ),
                        if (!inLossMode) ...[
                        cardGap,
                        HearthCard(
                          onTap: () {
                            Navigator.pushNamed(context, Routes.careSurvey);
                          },
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HearthIconChip(Icons.auto_awesome_outlined),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Care Check-In',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Tell us what you needed help with and whether you got it.',
                                          style: hearthCardBodyStyle,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const _HomeCta('Start check-in'),
                            ],
                          ),
                        ),
                        ],
                        cardGap,
                        _buildLatestVisitSection(),
                      ],
                    ),
                  ),

                  if (!inLossMode)
                  // Know your rights — the one purple card on Home.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: HearthFeatureCard(
                      tone: HearthTone.purple,
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.rights),
                      child: Row(
                        children: [
                          const HearthIconChip(
                            Icons.shield_outlined,
                            tone: HearthChipTone.gold,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Know your rights',
                                  style:
                                      hearthFeatureTitleStyle(onPurple: true),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Understand your options and feel confident speaking up.',
                                  style: hearthCardBodyStyle.copyWith(
                                    color: AppTheme.onPurpleSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppTheme.onPurple,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!inLossMode)
                  // Understand Your Care — quick paths to explanation features
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const HearthSectionHeading('Understand your care'),
                        headingGap,
                        HomeProviderSearchEntry(
                          title: 'Find your care team',
                          subtitle: 'Search providers by ZIP, city, and type of care',
                          onTap: () =>
                              Navigator.pushNamed(context, Routes.providers),
                        ),
                        cardGap,
                        _CareToolPair(
                              first: _CareToolCard(
                                icon: Icons.science_outlined,
                                title: 'What does this test mean?',
                                subtitle:
                                    'Labs and visit notes in plain language',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const AssistantScreen(
                                      initialPrompt: _kAssistantPromptTestMeaning,
                                    ),
                                  ),
                                ),
                              ),
                              second: _CareToolCard(
                                icon: Icons.help_outline,
                                title: 'Is this normal?',
                                subtitle:
                                    "What's typical, and when to reach out",
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
                  ),

                  if (!inLossMode) ...[
                  // Week / trimester journey card → the same trimester module the
                  // Learning Center banner opens (single source of truth). Tint,
                  // because "Know your rights" is the screen's purple card.
                  if (showWeekJourneyCard) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: HearthFeatureCard(
                        onTap: () => openTrimesterJourney(context),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const HearthIconChip(
                              Icons.menu_book_outlined,
                              tone: HearthChipTone.surface,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // Non-breaking spaces keep "Week N" and
                                    // the full trimester label together.
                                    'Week$_kNbsp$displayWeek • ${PregnancyUtils.trimesterDisplayTitle(trimester).replaceAll(' ', _kNbsp)}',
                                    style: hearthFeatureTitleStyle(),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'What to expect this week, what to ask, and when to call your provider.',
                                    style: hearthCardBodyStyle,
                                  ),
                                  const _HomeCta(
                                    'Open your trimester guide',
                                    icon: Icons.arrow_forward,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  ],
                  if (!inLossMode) ...[
                  // Community (NewUI: conversational header + belonging copy)
                  // Trimmed: a trailing no-break space makes web fall back to
                  // another serif for the whole heading.
                  HearthSectionHeading('From the community$_kNbsp'.trim()),
                  headingGap,
                  HearthCard(
                    // Switch to the Community tab so the bottom tab bar
                    // stays visible; push only outside the main shell.
                    onTap: () {
                      if (!MainNavigationScope.goToTab(
                          context, MainNavigationScope.tabCommunity)) {
                        Navigator.pushNamed(context, Routes.community);
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const HearthIconChip(Icons.favorite_border),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome to',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  // Product name kept on one line so
                                  // it never breaks mid-word at large
                                  // text sizes.
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'EmpowerHealth Watch',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "You're not alone here. Connect with other moms, share your journey, and find support from those who understand.",
                                    style: hearthCardBodyStyle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const _HomeCta('Explore community'),
                      ],
                    ),
                  ),
                  ],
                      ],
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

    return HearthCard(
      onTap: () {
        if (contentString.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LearningModuleDetailScreen(
                title: title,
                content: contentString,
                icon: '',
              ),
            ),
          );
        } else {
          _openTab(context, MainNavigationScope.tabLearn, Routes.learning);
        }
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip colours come from the caller's palette.
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors['bg'] ?? AppTheme.tintWarm,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colors['icon'] ?? AppTheme.brandPurple,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: hearthCardTitleStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description.isNotEmpty ? description : 'Learning module',
            style: hearthCaptionStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Tab-title greeting. On the regular Home the last word gets the gold
/// hand-drawn underline from the mockup.
class _GreetingTitle extends StatelessWidget {
  const _GreetingTitle({required this.text, required this.underlineLastWord});

  final String text;
  final bool underlineLastWord;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displayLarge;
    final trimmed = text.trim();
    final split = trimmed.lastIndexOf(' ');
    if (!underlineLastWord || split < 0) {
      return Text(trimmed, style: style);
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: trimmed.substring(0, split + 1)),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text(trimmed.substring(split + 1), style: style),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: -7,
                  height: 10,
                  child: CustomPaint(painter: _SquigglePainter()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold underline stroke (mockup path "M2 7c18-6 36-6 52-2s28 3 40-2" on 96×10).
class _SquigglePainter extends CustomPainter {
  const _SquigglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 96;
    final sy = size.height / 10;
    final path = Path()
      ..moveTo(2 * sx, 7 * sy)
      ..cubicTo(20 * sx, 1 * sy, 38 * sx, 1 * sy, 54 * sx, 5 * sy)
      ..cubicTo(70 * sx, 9 * sy, 82 * sx, 8 * sy, 94 * sx, 3 * sy);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.brandGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SquigglePainter oldDelegate) => false;
}

/// Purple "Start check-in ›" style link line at the foot of a card. The whole
/// card is the tap target, so this is only a visual cue.
class _HomeCta extends StatelessWidget {
  const _HomeCta(this.label, {this.icon = Icons.chevron_right});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.brandPurple,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: AppTheme.brandPurple),
        ],
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
    return HearthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          HearthIconChip(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: hearthCardTitleStyle),
                const SizedBox(height: 4),
                Text(subtitle, style: hearthCardBodyStyle),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(description!, style: hearthCaptionStyle),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.brandPurple, size: 20),
        ],
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
    return HearthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HearthIconChip(icon),
          const SizedBox(height: 12),
          Text(title, style: hearthCardTitleStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: hearthCaptionStyle),
        ],
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
    final hasDuration = durationLabel != null && durationLabel!.isNotEmpty;
    return HearthCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(18, 18, 18, hasDuration ? 8 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HearthIconChip(Icons.article_outlined),
          SizedBox(width: compact ? 14 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null && overline!.isNotEmpty) ...[
                  Text(overline!, style: hearthCaptionStyle),
                  const SizedBox(height: 4),
                ],
                Text(title, style: hearthCardTitleStyle),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: hearthCaptionStyle),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description, style: hearthCardBodyStyle),
                ],
                if (hasDuration) ...[
                  const SizedBox(height: 4),
                  _HomeCta(durationLabel!),
                ],
              ],
            ),
          ),
          if (!hasDuration)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.chevron_right,
                color: AppTheme.brandPurple,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

/// Two [_CareToolCard]s side by side; stacks them full-width when the user's
/// text size (Dynamic Type / Bold Text) or a narrow screen would leave too
/// little room for card copy and force mid-word line breaks.
class _CareToolPair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _CareToolPair({required this.first, required this.second});

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final boldText = MediaQuery.boldTextOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - _gap) / 2;
        // Usable copy width per card shrinks as text grows; stack when the
        // longest words ("personalized", "Summaries") would no longer fit.
        final effectiveScale = textScale * (boldText ? 1.08 : 1.0);
        final stack = effectiveScale >= 1.15 || cardWidth < 140;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              const SizedBox(height: _gap),
              second,
            ],
          );
        }
        // Equal heights, like the mockup's grid rows.
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: first),
              const SizedBox(width: _gap),
              Expanded(child: second),
            ],
          ),
        );
      },
    );
  }
}

class _CareToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CareToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HearthIconChip(icon),
          const SizedBox(height: 12),
          Text(title, style: hearthCardTitleStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: hearthCaptionStyle),
        ],
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
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HearthIconChip(Icons.auto_awesome_outlined),
            const SizedBox(height: 16),
            Text(
              'Creating Your Learning Plan',
              style: textTheme.headlineMedium,
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
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppTheme.borderWarm,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPurple),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentTask,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$_completedModules of $_totalModules modules generated',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
