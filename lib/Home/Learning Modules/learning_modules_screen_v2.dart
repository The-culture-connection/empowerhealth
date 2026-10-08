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
import '../../design_system/hearth.dart';
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

  // Helper to get icon for module. Every module uses the same warm icon chip;
  // only the glyph varies by topic.
  IconData _getModuleIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('right') || lowerTitle.contains('advocacy')) return Icons.shield_outlined;
    if (lowerTitle.contains('nutrition') || lowerTitle.contains('food') || lowerTitle.contains('eat')) return Icons.restaurant_outlined;
    if (lowerTitle.contains('medication') || lowerTitle.contains('medicine')) return Icons.medication_outlined;
    if (lowerTitle.contains('mental') || lowerTitle.contains('emotional') || lowerTitle.contains('wellbeing')) return Icons.favorite_border;
    if (lowerTitle.contains('birth') || lowerTitle.contains('labor') || lowerTitle.contains('delivery')) return Icons.child_care_outlined;
    if (lowerTitle.contains('risk') || lowerTitle.contains('prenatal')) return Icons.shield_outlined;
    return Icons.menu_book_outlined;
  }

  // Quiet text actions on module cards; still a 44px touch target.
  static final ButtonStyle _cardActionStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    minimumSize: const Size(0, 44),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: const TextStyle(
      fontFamily: AppTheme.sansFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );

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

  Widget _sectionHeader(String label, {String? subtitle, bool first = false}) {
    // Cards already leave 12 below them; the extra top padding makes the
    // 24 gap between sections.
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 12, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HearthSectionHeading(label),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: hearthCaptionStyle),
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
    // 32 vertical padding + 46 icon chip + 14 gap + 2 border, then scaled
    // text: title 3 × 22 + 4 gap + subtitle 2 × 18.
    final birthStripHeight =
        (94.0 + textScale * (3 * 22 + 4 + 2 * 18) + 4).clamp(180.0, 340.0);
    // Deliberate carousel: card is ~80% of the content width so the next card
    // peeks in from the screen edge (strip is full-bleed, not clipped at the
    // 20pt gutter).
    final contentWidth = MediaQuery.sizeOf(context).width - 40;
    final birthCardWidth = (contentWidth * 0.8).clamp(216.0, 340.0);
    // Archived shows only archived items — hide static modules/cards.
    final showStaticContent = _filterType != 'archived';

    return [
      const SliverToBoxAdapter(
        child: HearthTabHeader(
          title: 'Learning center',
          subtitle: 'Knowledge that empowers your choices',
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: _LearningWeekContinueCard(userProfile: _userProfile),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: HorizontalDragScroll(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  HearthChoiceChip(
                    label: 'All',
                    primary: true,
                    selected: _filterType == 'all',
                    onSelected: () => setState(() => _filterType = 'all'),
                  ),
                  const SizedBox(width: 8),
                  HearthChoiceChip(
                    label: 'Modules',
                    primary: true,
                    selected: _filterType == 'modules',
                    onSelected: () => setState(() => _filterType = 'modules'),
                  ),
                  const SizedBox(width: 8),
                  HearthChoiceChip(
                    label: 'Archived',
                    primary: true,
                    selected: _filterType == 'archived',
                    onSelected: () => setState(() => _filterType = 'archived'),
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: HearthSectionHeading('Birth & hospital basics'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: birthStripHeight,
                child: HorizontalDragScroll(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: birthLaborEducationTopics.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final t = birthLaborEducationTopics[i];
                      return SizedBox(
                        width: birthCardWidth,
                        child: HearthCard(
                          onTap: () => openBirthLaborTopic(context, t),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const HearthIconChip(Icons.local_hospital_outlined),
                              const SizedBox(height: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: hearthCardTitleStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      t.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: hearthCaptionStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          // The one purple feature card on this screen, matching Home.
          child: HearthFeatureCard(
            tone: HearthTone.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RightsScreen()),
              );
            },
            child: Row(
              children: [
                const HearthIconChip(Icons.shield_outlined, tone: HearthChipTone.gold),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Know your rights',
                        style: hearthFeatureTitleStyle(onPurple: true),
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
                const Icon(Icons.chevron_right, size: 20, color: AppTheme.onPurple),
              ],
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
                                  const HearthIconChip(
                                    Icons.menu_book_outlined,
                                    size: 80,
                                    iconSize: 36,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No Learning Modules Yet',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Generate personalized learning modules from the Home screen',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge,
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
                                  style: Theme.of(context).textTheme.bodyLarge,
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == rows.length) {
                          if (_filterType == 'archived') {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 24),
                            child: _LearningApproachCard(),
                          );
                        }
                        final row = rows[index];
                        if (row is String) {
                          return _sectionHeader(row, first: index == 0);
                        }
                        if (row is _SectionHeading) {
                          return _sectionHeader(
                            row.label,
                            subtitle: row.subtitle,
                            first: index == 0,
                          );
                        }
                        final doc = row as QueryDocumentSnapshot;
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '').toString();
                        final description = (data['description'] ?? '').toString();
                        final content = data['content'];
                        final contentString = content is String ? content : (content is Map ? content.toString() : '');
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

                        // Archived cards stay fully opaque; muted text marks them.
                        final titleColor =
                            isArchived ? AppTheme.textMuted : AppTheme.ink;
                        final bodyColor = isArchived
                            ? AppTheme.textMuted
                            : AppTheme.textSecondary;

                        return HearthCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
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
                                        icon: '',
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Icon chip for learning modules, status tag for todos
                                  if (!isTodo)
                                    HearthIconChip(icon)
                                  else
                                    Flexible(
                                      child: HearthTag(
                                        isBirthPlanTodo
                                            ? 'Birth preferences'
                                            : 'Next step',
                                      ),
                                    ),
                                  const Spacer(),
                                  if (isArchived)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  if (contentString.isNotEmpty && !isTodo)
                                    const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Icon(
                                          Icons.chevron_right,
                                          size: 22,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Pulled left so the box lines up with the tag
                              // while keeping a 44px touch target.
                              Transform.translate(
                                offset: const Offset(-11, 0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Checkbox - show for all items (todos and learning modules)
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Transform.scale(
                                        scale: 22 / 18,
                                        child: Checkbox(
                                          value: isCompleted,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          // Unchecking an archived item restores it.
                                          onChanged: isArchived
                                              ? (value) {
                                                  if (value == false) onRestore();
                                                }
                                              : onCheckboxChanged,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          displayTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                height: 24 / 17,
                                                color: titleColor,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              _ExpandableDescription(
                                key: ValueKey('desc_$taskId'),
                                text: displayDescription,
                                style: hearthCardBodyStyle.copyWith(color: bodyColor),
                              ),
                              if (!isArchived && !isCompleted)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: onMarkDoneAndArchive,
                                      style: _cardActionStyle,
                                      child: const Text('Mark Done & Archive'),
                                    ),
                                  ),
                                ),
                              if (isCompleted && !isArchived)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: onArchiveCompleted,
                                      style: _cardActionStyle.copyWith(
                                        foregroundColor:
                                            const WidgetStatePropertyAll(
                                          AppTheme.textSecondary,
                                        ),
                                      ),
                                      child: const Text('Archive'),
                                    ),
                                  ),
                                ),
                              if (isArchived)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: onRestore,
                                      icon: const Icon(Icons.undo, size: 18),
                                      style: _cardActionStyle,
                                      label: Text(
                                        isCompleted
                                            ? 'Mark not done'
                                            : 'Unarchive',
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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

    // Compact pregnancy-status banner (replaces the large progress card).
    return HearthFeatureCard(
      onTap: () => openTrimesterJourney(context),
      padding: const EdgeInsets.all(16),
      child: Row(
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
                // Full title + week info wrap rather than ellipsize
                // (Bold Text / larger Dynamic Type).
                Text(title, style: hearthFeatureTitleStyle()),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: hearthCardBodyStyle.copyWith(height: 20 / 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: AppTheme.brandPurple),
        ],
      ),
    );
  }
}

/// Flutter UIdesign `LearningScreen` — “Plain language promise” footer.
class _LearningApproachCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: HearthFeatureCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plain language promise', style: hearthFeatureTitleStyle()),
            const SizedBox(height: 8),
            const Text(
              'All our content is written at a 6th grade reading level. No confusing medical jargon, just clear, supportive guidance that helps you understand your care.',
              style: hearthCardBodyStyle,
            ),
          ],
        ),
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
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(_expanded ? 'Show less' : 'Show more'),
              ),
          ],
        );
      },
    );
  }
}
