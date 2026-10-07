import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_router.dart';
import '../../models/user_profile.dart';
import '../../research/post_module_rating_modal.dart';
import '../../services/analytics_service.dart';
import '../../services/database_service.dart';
import '../../services/research/research_firestore_service.dart';
import '../../cors/ui_theme.dart';
import '../../widgets/drag_scroll_behavior.dart';
import '../../utils/pregnancy_utils.dart';
import '../../utils/second_person.dart';
import 'learning_module_detail_screen.dart';
import 'module_survey_dialog.dart';
import 'rights_screen.dart';
import 'birth_labor_education_topics.dart';
import '../../pregnancy_loss/pregnancy_loss_learning_screen.dart';
import '../../support_stage/support_stage.dart';

/// Single entry point for the user's current-trimester content.
///
/// Both the Learning Center trimester card and Home's trimester banner should
/// call this so they always open the same screen ([Routes.pregnancyJourney]).
void openTrimesterJourney(BuildContext context) {
  Navigator.pushNamed(context, Routes.pregnancyJourney);
}

class LearningModulesScreenV2 extends StatefulWidget {
  const LearningModulesScreenV2({super.key});

  @override
  State<LearningModulesScreenV2> createState() => _LearningModulesScreenV2State();
}

class _LearningModulesScreenV2State extends State<LearningModulesScreenV2> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  String _filterType = 'all'; // 'all', 'todos', 'modules', or 'archived'
  dynamic _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final profile = await _databaseService.getUserProfile(uid);
    if (mounted) setState(() => _userProfile = profile);
  }

  Future<void> _logLearningModuleCompleted({
    required String moduleId,
    required String moduleTitle,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Best-effort profile hydration; event still logs if profile read fails.
      final userProfile = await _databaseService.getUserProfile(userId);
      await _analytics.logLearningModuleCompleted(
        moduleId: moduleId,
        moduleTopic: moduleTitle,
        completionStatus: 'archived_from_list',
        userProfile: userProfile,
      );
    } catch (e) {
      try {
        await _analytics.logLearningModuleCompleted(
          moduleId: moduleId,
          moduleTopic: moduleTitle,
          completionStatus: 'archived_from_list',
          userProfile: null,
        );
      } catch (_) {
        // Swallow analytics-only failures to avoid blocking UX.
      }
    }
  }

  /// When the archive path did not open [ModuleSurveyDialog], research participants still get a Likert prompt.
  Future<void> _maybePromptPostModuleMicroMeasure({
    required BuildContext context,
    required String? taskId,
    required String moduleTitle,
  }) async {
    if (taskId == null || taskId.isEmpty) return;
    final p = _userProfile;
    if (p is! UserProfile || !p.isResearchParticipant) return;
    final sid = await ResearchFirestoreService.instance.ensureStudyId(p);
    if (!mounted || sid == null) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PostModuleRatingModal(
        studyId: sid,
        contentId: taskId,
        moduleTitle: moduleTitle,
      ),
    );
  }

  // Helper to get icon for module
  IconData _getModuleIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('right') || lowerTitle.contains('advocacy')) return Icons.favorite_border_rounded;
    if (lowerTitle.contains('nutrition') || lowerTitle.contains('food') || lowerTitle.contains('eat')) return Icons.restaurant;
    if (lowerTitle.contains('medication') || lowerTitle.contains('medicine')) return Icons.medication;
    if (lowerTitle.contains('mental') || lowerTitle.contains('emotional') || lowerTitle.contains('wellbeing')) return Icons.favorite;
    if (lowerTitle.contains('birth') || lowerTitle.contains('labor') || lowerTitle.contains('delivery')) return Icons.child_care;
    if (lowerTitle.contains('risk') || lowerTitle.contains('prenatal')) return Icons.shield;
    return Icons.book_outlined;
  }

  // Helper to get color for module
  Map<String, Color> _getModuleColors(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('right') || lowerTitle.contains('advocacy')) {
      return {'bg': const Color(0xFFE8E0F0).withOpacity(0.65), 'icon': const Color(0xFF8B7AA8)};
    }
    if (lowerTitle.contains('nutrition') || lowerTitle.contains('food')) {
      return {'bg': Colors.green.shade50, 'icon': Colors.green.shade600};
    }
    if (lowerTitle.contains('medication')) {
      return {'bg': Colors.green.shade50, 'icon': Colors.green.shade600};
    }
    if (lowerTitle.contains('mental') || lowerTitle.contains('emotional')) {
      return {'bg': Colors.purple.shade50, 'icon': const Color(0xFF663399)};
    }
    if (lowerTitle.contains('risk') || lowerTitle.contains('prenatal')) {
      return {'bg': Colors.amber.shade50, 'icon': Colors.amber.shade600};
    }
    return {'bg': Colors.blue.shade50, 'icon': Colors.blue.shade500};
  }

  String _formatMapContentToMarkdown(Map<String, dynamic> contentMap) {
    final buffer = StringBuffer();
    final sections = [
      {'key': 'whatThisIs', 'title': 'What This Is'},
      {'key': 'whyItMatters', 'title': 'Why It Matters for Your Health'},
      {'key': 'whatToExpect', 'title': 'What to Expect'},
      {'key': 'whatYouCanAsk', 'title': 'What You Can Ask or Say'},
      {'key': 'risksOptionsAlternatives', 'title': 'Risks, Options, and Alternatives'},
      {'key': 'whenToSeekHelp', 'title': 'When to Seek Medical Help'},
      {'key': 'empowermentConnection', 'title': 'How This Connects to Your Empowerment'},
      {'key': 'keyPoints', 'title': 'Key Points'},
      {'key': 'yourRights', 'title': 'Your Rights'},
      {'key': 'insuranceNotes', 'title': 'Insurance Notes'},
    ];

    for (final section in sections) {
      final key = section['key']!;
      final title = section['title']!;
      final value = contentMap[key];
      
      if (value != null) {
        String valueStr = '';
        if (value is String) {
          valueStr = value;
        } else if (value is List) {
          valueStr = value.map((e) => e.toString()).join('\n• ');
          if (valueStr.isNotEmpty) valueStr = '• $valueStr';
        } else {
          valueStr = value.toString();
        }
        
        if (valueStr.trim().isNotEmpty) {
          buffer.writeln('## $title');
          buffer.writeln(valueStr);
          buffer.writeln();
        }
      }
    }

    return buffer.toString().isEmpty ? contentMap.toString() : buffer.toString();
  }

  /// Buckets a module into a content-first topic section (doc's Learning Center grouping).
  static const List<String> _topicSectionOrder = [
    'Birth & hospital basics',
    'Know your rights & advocacy',
    'Emotional wellbeing',
    'Postpartum preparation',
    'Health made simple',
  ];

  String _topicSectionFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('right') ||
        t.contains('advoca') ||
        t.contains('consent') ||
        t.contains('speak')) {
      return 'Know your rights & advocacy';
    }
    if (t.contains('birth') ||
        t.contains('labor') ||
        t.contains('delivery') ||
        t.contains('hospital') ||
        t.contains('admission') ||
        t.contains('triage')) {
      return 'Birth & hospital basics';
    }
    if (t.contains('mental') ||
        t.contains('emotional') ||
        t.contains('wellbeing') ||
        t.contains('well-being') ||
        t.contains('stress') ||
        t.contains('mood') ||
        t.contains('anxiety') ||
        t.contains('depression')) {
      return 'Emotional wellbeing';
    }
    if (t.contains('postpartum') ||
        t.contains('recovery') ||
        t.contains('feeding') ||
        t.contains('breastfeed') ||
        t.contains('pumping') ||
        t.contains('newborn') ||
        t.contains('baby')) {
      return 'Postpartum preparation';
    }
    return 'Health made simple';
  }

  Widget _sectionHeader(String label, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: AppTheme.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w300,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Returns an interleaved list of section-header strings and task docs,
  /// grouping modules into topic sections (with todos under "Your next steps").
  List<Object> _buildGroupedRows(List<QueryDocumentSnapshot> tasks) {
    final rows = <Object>[];
    if (_filterType == 'archived') {
      rows.addAll(tasks); // flat list, no section headers
      return rows;
    }

    final todos = <QueryDocumentSnapshot>[];
    final sections = <String, List<QueryDocumentSnapshot>>{};
    for (final doc in tasks) {
      final data = doc.data() as Map<String, dynamic>;
      final content = data['content'];
      final hasContent = content != null &&
          content.toString().trim().isNotEmpty &&
          content.toString() != 'null';
      final category = data['category'];
      final isTodo = !hasContent ||
          category != null ||
          data['birthPlanId'] != null ||
          (data['moduleType'] == null && !hasContent);
      if (isTodo) {
        todos.add(doc);
      } else {
        final title = (data['title'] ?? '').toString();
        sections.putIfAbsent(_topicSectionFor(title), () => []).add(doc);
      }
    }

    if (todos.isNotEmpty) {
      final hasBirthPlanTodos = todos.any(
        (d) => (d.data() as Map<String, dynamic>)['birthPlanId'] != null,
      );
      final hasVisitTodos = todos.any(
        (d) => (d.data() as Map<String, dynamic>)['birthPlanId'] == null,
      );
      final source = hasBirthPlanTodos && hasVisitTodos
          ? 'From your visit summaries and birth preferences'
          : hasBirthPlanTodos
              ? 'From your birth preferences'
              : 'From your visit summaries';
      rows.add(_SectionHeading('Your next steps', subtitle: source));
      rows.addAll(todos);
    }
    for (final section in _topicSectionOrder) {
      final items = sections[section];
      if (items != null && items.isNotEmpty) {
        rows.add(section);
        rows.addAll(items);
      }
    }
    return rows;
  }

  /// Pushed from Home uses an opaque page without main-shell ambient — avoid transparent → black.
  Color get _scaffoldFill =>
      Navigator.canPop(context) ? AppTheme.backgroundWarm : Colors.transparent;

  bool get _inPregnancyLossMode {
    final p = _userProfile;
    return p is UserProfile && p.isInPregnancyLossMode;
  }

  List<Widget> _learningScrollHeaderSlivers() {
    // Long titles (up to 3 lines) + 2-line subtitle need room; derive the strip
    // height from the actual text metrics so it grows with Dynamic Type.
    final textScale =
        MediaQuery.textScalerOf(context).scale(14) / 14.0;
    // 24 vertical padding + 22 icon + 12 min gap, then scaled text:
    // title 3 × (14 × 1.2) + 4 gap + subtitle 2 × (12 × 1.25).
    final birthStripHeight =
        (58.0 + textScale * (3 * 14 * 1.2 + 4 + 2 * 12 * 1.25) + 8)
            .clamp(148.0, 260.0);
    // Deliberate carousel: card is ~80% of the content width so the next card
    // peeks in from the screen edge (strip is full-bleed, not clipped at the
    // 24pt gutter).
    final contentWidth = MediaQuery.sizeOf(context).width - 48;
    final birthCardWidth = (contentWidth * 0.8).clamp(216.0, 340.0);
    // Archived shows only archived items — hide static modules/cards.
    final showStaticContent = _filterType != 'archived';

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Learning center',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Knowledge that empowers your choices',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: _LearningWeekContinueCard(userProfile: _userProfile),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: HorizontalDragScroll(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _filterType == 'all',
                    onTap: () => setState(() => _filterType = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Modules',
                    isSelected: _filterType == 'modules',
                    onTap: () => setState(() => _filterType = 'modules'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Archived',
                    isSelected: _filterType == 'archived',
                    onTap: () => setState(() => _filterType = 'archived'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
      if (showStaticContent) ...[
      SliverToBoxAdapter(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Birth & hospital basics',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: birthStripHeight,
                child: HorizontalDragScroll(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: birthLaborEducationTopics.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final t = birthLaborEducationTopics[i];
                      return SizedBox(
                        width: birthCardWidth,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => openBirthLaborTopic(context, t),
                            borderRadius: BorderRadius.circular(20),
                            child: Ink(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.borderLight.withOpacity(0.5),
                                ),
                                boxShadow: AppTheme.shadowSoft(
                                  opacity: 0.05,
                                  blur: 14,
                                  y: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.local_hospital_outlined,
                                    size: 22,
                                    color: AppTheme.brandPurple.withOpacity(0.85),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          t.title,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.25,
                                            color: AppTheme.textMuted,
                                            fontWeight: FontWeight.w300,
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
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RightsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderLight.withOpacity(0.45)),
                  boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 20, y: 4),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8E0F0), Color(0xFFF0E8F6)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.favorite_border_rounded, color: Color(0xFF9D8FB5), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Know your rights',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Understand your options and feel confident speaking up.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_inPregnancyLossMode) {
      return const PregnancyLossLearningScreen();
    }

    final userId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: _scaffoldFill,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
                  stream: userId != null
                      ? FirebaseFirestore.instance
                          .collection('learning_tasks')
                          .where('userId', isEqualTo: userId)
                          .where('isGenerated', isEqualTo: true)
                          .orderBy('createdAt', descending: true)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CustomScrollView(
                        slivers: [
                          ..._learningScrollHeaderSlivers(),
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      );
                    }

                    final noDocs =
                        !snapshot.hasData || snapshot.data!.docs.isEmpty;
                    if (noDocs && _filterType != 'archived') {
                      return CustomScrollView(
                        slivers: [
                          ..._learningScrollHeaderSlivers(),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF663399), Color(0xFF8855BB)],
                                      ),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: const Icon(
                                      Icons.book_outlined,
                                      size: 40,
                                      color: AppTheme.brandWhite,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No Learning Modules Yet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Generate personalized learning modules from the Home screen',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final tasks = (snapshot.data?.docs ??
                            const <QueryDocumentSnapshot>[])
                        .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isArchived = data['isArchived'] ?? false;
                      final content = data['content'];
                      final hasContent = content != null && 
                                       content.toString().trim().isNotEmpty && 
                                       content.toString() != 'null';
                      final category = data['category'];
                      final moduleType = data['moduleType'];
                      
                      // Determine if it's a todo (no content, has category, or from birth plan)
                      final isTodo = !hasContent || 
                                    category != null || 
                                    data['birthPlanId'] != null ||
                                    (moduleType == null && !hasContent);
                      
                      // A learning module is anything with content that is not a todo.
                      // Must mirror _buildGroupedRows so "Modules" shows exactly the
                      // module cards that "All" groups into topic sections.
                      final isModule = hasContent && !isTodo;

                      // Apply filters
                      if (_filterType == 'archived') {
                        return isArchived == true;
                      } else if (_filterType == 'todos') {
                        return isArchived != true && isTodo;
                      } else if (_filterType == 'modules') {
                        return isArchived != true && isModule;
                      } else {
                        // 'all' - show everything that's not archived
                        return isArchived != true;
                      }
                    }).toList();

                    if (tasks.isEmpty) {
                      return CustomScrollView(
                        slivers: [
                          ..._learningScrollHeaderSlivers(),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  _filterType == 'archived'
                                      ? 'No archived items'
                                      : _filterType == 'todos'
                                          ? 'No todos yet'
                                          : _filterType == 'modules'
                                              ? 'No learning modules yet'
                                              : 'No items yet',
                                  style: TextStyle(color: AppTheme.textMuted),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final rows = _buildGroupedRows(tasks);

                    return CustomScrollView(
                      slivers: [
                        ..._learningScrollHeaderSlivers(),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == rows.length) {
                          if (_filterType == 'archived') {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: _LearningApproachCard(),
                          );
                        }
                        final row = rows[index];
                        if (row is String) {
                          return _sectionHeader(row);
                        }
                        if (row is _SectionHeading) {
                          return _sectionHeader(row.label, subtitle: row.subtitle);
                        }
                        final doc = row as QueryDocumentSnapshot;
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '').toString();
                        final description = (data['description'] ?? '').toString();
                        final content = data['content'];
                        final contentString = content is String ? content : (content is Map ? content.toString() : '');
                        final colors = _getModuleColors(title);
                        final icon = _getModuleIcon(title);

                        // Check if completed and archived
                        final isCompleted = data['isCompleted'] ?? false;
                        final isArchived = data['isArchived'] ?? false;
                        final taskId = doc.id;
                        
                        // Determine if it's a todo or module
                        final hasContent = content != null && 
                                         content.toString().trim().isNotEmpty && 
                                         content.toString() != 'null';
                        final category = data['category'];
                        final isTodo = !hasContent || 
                                      category != null || 
                                      data['birthPlanId'] != null ||
                                      (data['moduleType'] == null && !hasContent);
                        final isBirthPlanTodo = data['birthPlanId'] != null;

                        // Display-only: convert stored "The patient…" phrasing to second person.
                        final displayTitle = SecondPerson.convert(title);
                        final displayDescription = description.isNotEmpty
                            ? SecondPerson.convert(description)
                            : (isTodo ? 'Next step on your path' : 'Learning module');

                        Future<void> onCheckboxChanged(bool? value) async {
                          if (value == true) {
                            // For learning modules (not todos), check if survey is completed
                            if (!isTodo) {
                              final userId = _auth.currentUser?.uid;
                              if (userId != null) {
                                final surveyQuery = await FirebaseFirestore.instance
                                    .collection('ModuleFeedback')
                                    .where('userId', isEqualTo: userId)
                                    .where('taskId', isEqualTo: taskId)
                                    .limit(1)
                                    .get();

                                if (surveyQuery.docs.isEmpty) {
                                  // Survey not completed, show popup
                                  if (mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => ModuleSurveyDialog(
                                        moduleTitle: title,
                                        taskId: taskId,
                                        onSurveyCompleted: () async {
                                          // After survey is completed, archive the module
                                          await doc.reference.update({
                                            'isCompleted': true,
                                            'isArchived': true,
                                          });
                                          await _logLearningModuleCompleted(
                                            moduleId: taskId,
                                            moduleTitle: title,
                                          );
                                        },
                                      ),
                                    );
                                  }
                                  return; // Don't archive yet
                                }
                              }
                            }
                            // Survey completed or it's a todo, proceed with archiving
                            await doc.reference.update({
                              'isCompleted': true,
                              'isArchived': true,
                            });
                            if (!isTodo) {
                              await _logLearningModuleCompleted(
                                moduleId: taskId,
                                moduleTitle: title,
                              );
                              await _maybePromptPostModuleMicroMeasure(
                                context: context,
                                taskId: taskId,
                                moduleTitle: title,
                              );
                            }
                          } else {
                            // When unchecked, unmark as completed and unarchive
                            await doc.reference.update({
                              'isCompleted': false,
                              'isArchived': false,
                            });
                          }
                        }

                        Future<void> onMarkDoneAndArchive() async {
                          // For learning modules (not todos), check if survey is completed
                          if (!isTodo) {
                            final userId = _auth.currentUser?.uid;
                            if (userId != null) {
                              final surveyQuery = await FirebaseFirestore.instance
                                  .collection('module_surveys')
                                  .where('userId', isEqualTo: userId)
                                  .where('taskId', isEqualTo: taskId)
                                  .limit(1)
                                  .get();

                              if (surveyQuery.docs.isEmpty) {
                                // Survey not completed, show popup
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ModuleSurveyDialog(
                                      moduleTitle: title,
                                      taskId: taskId,
                                      onSurveyCompleted: () async {
                                        // After survey is completed, archive the module
                                        await doc.reference.update({
                                          'isCompleted': true,
                                          'isArchived': true,
                                        });
                                        await _logLearningModuleCompleted(
                                          moduleId: taskId,
                                          moduleTitle: title,
                                        );
                                      },
                                    ),
                                  );
                                }
                                return; // Don't archive yet
                              }
                            }
                          }
                          // Survey completed or it's a todo, proceed with archiving
                          await doc.reference.update({
                            'isCompleted': true,
                            'isArchived': true,
                          });
                          if (!isTodo) {
                            await _logLearningModuleCompleted(
                              moduleId: taskId,
                              moduleTitle: title,
                            );
                            await _maybePromptPostModuleMicroMeasure(
                              context: context,
                              taskId: taskId,
                              moduleTitle: title,
                            );
                          }
                        }

                        Future<void> onArchiveCompleted() async {
                          // For learning modules (not todos), check if survey is completed
                          if (!isTodo) {
                            final userId = _auth.currentUser?.uid;
                            if (userId != null) {
                              final surveyQuery = await FirebaseFirestore.instance
                                  .collection('module_surveys')
                                  .where('userId', isEqualTo: userId)
                                  .where('taskId', isEqualTo: taskId)
                                  .limit(1)
                                  .get();

                              if (surveyQuery.docs.isEmpty) {
                                // Survey not completed, show popup
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ModuleSurveyDialog(
                                      moduleTitle: title,
                                      taskId: taskId,
                                      onSurveyCompleted: () async {
                                        // After survey is completed, archive the module
                                        await doc.reference.update({
                                          'isArchived': true,
                                        });
                                        await _logLearningModuleCompleted(
                                          moduleId: taskId,
                                          moduleTitle: title,
                                        );
                                      },
                                    ),
                                  );
                                }
                                return; // Don't archive yet
                              }
                            }
                          }
                          // Survey completed or it's a todo, proceed with archiving
                          await doc.reference.update({'isArchived': true});
                          if (!isTodo) {
                            await _logLearningModuleCompleted(
                              moduleId: taskId,
                              moduleTitle: title,
                            );
                            await _maybePromptPostModuleMicroMeasure(
                              context: context,
                              taskId: taskId,
                              moduleTitle: title,
                            );
                          }
                        }

                        // Reverses "Mark Done & Archive" / checkbox completion:
                        // the item goes back to its active list.
                        Future<void> onRestore() async {
                          // Captured first: this card leaves the Archived list
                          // as soon as the update lands.
                          final messenger = ScaffoldMessenger.of(context);
                          await doc.reference.update({
                            'isCompleted': false,
                            'isArchived': false,
                          });
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                isTodo
                                    ? 'Moved back to your next steps'
                                    : 'Moved back to your modules',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isArchived ? AppTheme.borderLighter : AppTheme.borderLight,
                            ),
                            boxShadow: AppTheme.shadowSoft(opacity: 0.05, blur: 12, y: 2),
                          ),
                          child: Opacity(
                            opacity: isArchived ? 0.6 : 1.0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                // Only navigate to detail screen if it has content (learning modules)
                                if (contentString.isNotEmpty && !isTodo) {
                                  // Convert Map content to formatted string if needed
                                  String formattedContent = contentString;
                                  if (content is Map) {
                                    formattedContent = _formatMapContentToMarkdown(content as Map<String, dynamic>);
                                  } else if (contentString.startsWith('{') || contentString.contains('whatThisIs')) {
                                    // Already handled in detail screen
                                    formattedContent = contentString;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LearningModuleDetailScreen(
                                        title: title,
                                        content: formattedContent,
                                        icon: '📚',
                                        taskId: taskId,
                                      ),
                                    ),
                                  );
                                } else if (isTodo) {
                                  // For todos without content, show a simple dialog or snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isBirthPlanTodo
                                            ? 'This is a birth plan action item. Complete it in your birth plan.'
                                            : 'This is a todo item. Mark it as done when completed.',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              // Mobile-first layout: compact status row on top, then title
                              // and description at full card width (no narrow side column).
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 8, 14, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Checkbox - show for all items (todos and learning modules)
                                        Checkbox(
                                          value: isCompleted,
                                          visualDensity: VisualDensity.compact,
                                          // Unchecking an archived item restores it.
                                          onChanged: isArchived
                                              ? (value) {
                                                  if (value == false) onRestore();
                                                }
                                              : onCheckboxChanged,
                                          activeColor: const Color(0xFF663399),
                                        ),
                                        const SizedBox(width: 6),
                                        // Icon box for learning modules, status badge for todos
                                        if (!isTodo)
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: colors['bg']!,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              icon,
                                              color: colors['icon']!,
                                              size: 20,
                                            ),
                                          )
                                        else
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isBirthPlanTodo
                                                    ? Colors.orange.shade100
                                                    : Colors.blue.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isBirthPlanTodo
                                                    ? 'Birth preferences'
                                                    : 'Next step',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isBirthPlanTodo
                                                      ? Colors.orange.shade700
                                                      : Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        const Spacer(),
                                        if (isArchived)
                                          const Icon(
                                            Icons.archive,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        if (contentString.isNotEmpty && !isTodo)
                                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, top: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayTitle,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isArchived ? Colors.grey[500] : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          _ExpandableDescription(
                                            key: ValueKey('desc_$taskId'),
                                            text: displayDescription,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.4,
                                              color: isArchived ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                          if (!isArchived && !isCompleted)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 10),
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: onMarkDoneAndArchive,
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: const Text(
                                                    'Mark Done & Archive',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF663399),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (isCompleted && !isArchived)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 10),
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: onArchiveCompleted,
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: Text(
                                                    'Archive',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (isArchived)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 10),
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: TextButton.icon(
                                                  onPressed: onRestore,
                                                  icon: const Icon(
                                                    Icons.undo,
                                                    size: 16,
                                                    color: Color(0xFF663399),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 4,
                                                    ),
                                                    minimumSize: const Size(0, 36),
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  label: Text(
                                                    isCompleted
                                                        ? 'Mark not done'
                                                        : 'Unarchive',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF663399),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
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
                        );
                      },
                              childCount: rows.length + 1,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
    );
  }
}

/// Week / trimester banner — parity with `Flutter UIdesign` `_ContinueCard` (profile-driven).
class _LearningWeekContinueCard extends StatelessWidget {
  const _LearningWeekContinueCard({this.userProfile});

  final dynamic userProfile;

  @override
  Widget build(BuildContext context) {
    final dueDate = userProfile?.dueDate as DateTime?;
    final weeks = PregnancyUtils.calculateWeeksPregnant(dueDate);
    final trimester = PregnancyUtils.calculateTrimester(dueDate);
    final title = weeks > 0
        ? PregnancyUtils.trimesterDisplayTitle(trimester)
        : 'Your learning journey';
    final subtitle = weeks > 0
        ? "Week $weeks of 40 · ${PregnancyUtils.getTrimesterInfo(trimester)}"
        : 'Add your due date for week-by-week guidance';

    const fg = AppTheme.textPrimary;
    const muted = AppTheme.textMuted;

    // Compact pregnancy-status banner (replaces the large progress card).
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openTrimesterJourney(context),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEBE4F3),
                Color(0xFFE6D8ED),
                Color(0xFFEAD9E0),
              ],
            ),
            border: Border.all(color: const Color(0x80E0D3E8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xCCFAF8F4),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.brandPurple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full title + week info wrap rather than ellipsize
                      // (Bold Text / larger Dynamic Type).
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Flutter UIdesign `LearningScreen` — “Plain language promise” footer.
class _LearningApproachCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundWarm,
            Color(0xFFFDFBFC),
            Color(0xFFFEF9F5),
          ],
        ),
        border: Border.all(color: Color(0x80E8E0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plain language promise',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All our content is written at a 6th grade reading level. No confusing medical jargon, just clear, supportive guidance that helps you understand your care.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w300,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading row with an optional one-line context explaining its source.
class _SectionHeading {
  const _SectionHeading(this.label, {this.subtitle});

  final String label;
  final String? subtitle;
}

/// Shows a concise summary (up to 3 lines) with a
/// "Show more" / "Show less" toggle when the text is longer.
class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({
    super.key,
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;
  static const int collapsedLines = 3;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(
            text: widget.text,
            style: DefaultTextStyle.of(context).style.merge(widget.style),
          ),
          maxLines: _ExpandableDescription.collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        final collapsed = overflows && !_expanded;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: collapsed ? _ExpandableDescription.collapsedLines : null,
              overflow: collapsed ? TextOverflow.ellipsis : null,
            ),
            if (overflows)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _expanded ? 'Show less' : 'Show more',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF663399),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryActionGradient : null,
          color: isSelected ? null : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.borderLighter.withOpacity(0.5),
          ),
          boxShadow: isSelected
              ? AppTheme.shadowSoft(opacity: 0.1, blur: 14, y: 3)
              : AppTheme.shadowSoft(opacity: 0.05, blur: 10, y: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.brandWhite : AppTheme.textMuted,
            fontWeight: FontWeight.w300,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
