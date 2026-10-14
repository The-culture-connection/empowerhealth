import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../cors/ui_theme.dart' show AppTheme;
import '../../design_system/hearth.dart';
import '../../learning/module_notes.dart';
import '../../learning/notes_dialog.dart';
import '../../services/analytics_service.dart';
import '../../services/database_service.dart';
import '../../widgets/learning_module_formatted_content.dart';
import '../../widgets/medical_citations_section.dart';
import '../../widgets/module_quick_feedback.dart';
import '../../widgets/qualitative_survey_dialog.dart';

class LearningModuleDetailScreen extends StatefulWidget {
  final String title;
  final String content;
  final String icon;
  final String? taskId; // Add taskId to track which module this survey is for
  final String? moduleId; // Module ID for analytics

  const LearningModuleDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    this.taskId,
    this.moduleId,
  });

  @override
  State<LearningModuleDetailScreen> createState() =>
      _LearningModuleDetailScreenState();
}

class _LearningModuleDetailScreenState
    extends State<LearningModuleDetailScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  DateTime? _viewStartTime;
  bool _hasTrackedView = false;
  bool _hasTrackedCompletion = false;
  bool _exiting = false;

  /// Text the user most recently selected in the module body. Kept after the
  /// selection is cleared by focus loss (e.g. clicking the "Add note" button
  /// on web) so the button can still attach it to the note.
  final ValueNotifier<String> _selectedText = ValueNotifier<String>('');

  String? get _noteModuleId => widget.moduleId ?? widget.taskId;

  /// The user's notes on this lesson; drives the in-text highlights so a
  /// newly saved note shows up right away.
  late final Stream<List<ModuleNote>> _notesStream = watchModuleNotes(
    moduleId: _noteModuleId,
    moduleTitle: widget.title,
  );

  /// Opens the journal notes dialog for this module, optionally quoting the
  /// highlighted text. Notes land in users/{uid}/notes with moduleTitle +
  /// moduleId so the Journal can link them back to this module.
  /// Saves this lesson to the Journal once (shows under Learning notes with an
  /// "Open lesson" link). A second tap just confirms it's already saved.
  Future<void> _saveLessonToJournal() async {
    final messenger = ScaffoldMessenger.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please sign in to save lessons.')),
      );
      return;
    }
    final key = _noteModuleId ?? widget.title;
    final notes = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes');
    try {
      final existing =
          await notes.where('savedLessonKey', isEqualTo: key).limit(1).get();
      if (existing.docs.isNotEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('This lesson is already saved in your Journal.')),
        );
        return;
      }
      await notes.add({
        'content': 'Saved lesson: ${widget.title}',
        'tag': NotesDialog.categoryForSection('learning_module'),
        'moduleTitle': widget.title,
        'moduleId': _noteModuleId,
        'highlightedText': null,
        'isFromModule': true,
        'savedLesson': true,
        'savedLessonKey': key,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Saved to your Journal.')),
      );
    } catch (e) {
      debugPrint('Save lesson failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('We couldn\'t save this lesson. Please try again.')),
      );
    }
  }

  void _openNotesDialog({String? highlightedText}) {
    final highlight = highlightedText?.trim();
    showDialog<void>(
      context: context,
      builder: (context) => NotesDialog(
        moduleTitle: widget.title,
        moduleId: _noteModuleId,
        preFilledText:
            (highlight == null || highlight.isEmpty) ? null : highlight,
        initialTag: NotesDialog.categoryForSection('learning_module'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _trackModuleView();
  }

  Future<void> _trackModuleView() async {
    if (_hasTrackedView) return;
    _hasTrackedView = true;
    _viewStartTime = DateTime.now();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final userProfile = await _databaseService.getUserProfile(userId);
      await _analytics.logLearningModuleViewed(
        moduleId: widget.moduleId ?? widget.taskId ?? 'unknown',
        moduleTopic: widget.title,
        userProfile: userProfile,
      );
      await _analytics.logLearningModuleStarted(
        moduleId: widget.moduleId ?? widget.taskId ?? 'unknown',
        moduleTopic: widget.title,
        userProfile: userProfile,
      );
    } catch (e) {
      print('Error tracking module view: $e');
    }
  }

  Future<void> _trackModuleExit() async {
    if (_viewStartTime == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final seconds = DateTime.now().difference(_viewStartTime!).inSeconds;
    final moduleId = widget.moduleId ?? widget.taskId ?? 'unknown';

    try {
      final userProfile = await _databaseService.getUserProfile(userId);

      await _analytics.logFeatureTimeSpent(
        feature: 'learning-modules',
        timeSpentSeconds: seconds,
        sourceId: moduleId,
        userProfile: userProfile,
      );

      if (!_hasTrackedCompletion) {
        _hasTrackedCompletion = true;
        await _analytics.logLearningModuleCompleted(
          moduleId: moduleId,
          moduleTopic: widget.title,
          timeSpentSeconds: seconds,
          completionStatus: seconds >= 45 ? 'completed' : 'partial',
          userProfile: userProfile,
        );
      }

      if (seconds < 20) {
        await _analytics.logFlowAbandoned(
          flowName: 'learning_module',
          stepName: 'module_detail',
          reason: 'early_exit',
          feature: 'learning-modules',
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking module exit: $e');
    }
  }

  @override
  void dispose() {
    _trackModuleExit();
    _selectedText.dispose();
    super.dispose();
  }

  /// Shows the exit feedback modal, then leaves the screen. Guarded so it runs
  /// once whether triggered by the back button or the system back gesture.
  Future<void> _confirmExit() async {
    if (_exiting) return;
    _exiting = true;
    await showModuleExitFeedbackSheet(
      context,
      feature: 'learning-modules',
      sourceId: widget.moduleId ?? widget.taskId,
      moduleTitle: widget.title,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
          child: Column(
            children: [
              HearthPushedHeader(
                title: widget.title,
                subtitle: 'Learning Module',
                onBack: _confirmExit,
                actions: [
                  HearthCircleButton(
                    icon: Icons.note_add_outlined,
                    tooltip: 'Add Note',
                    onPressed: () => _openNotesDialog(),
                  ),
                  HearthCircleButton(
                    icon: Icons.ios_share,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selectable text for highlighting
                      HearthCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 18,
                                  color: AppTheme.brandPurple,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Long-press or drag across text to highlight it, then add a note',
                                    style: TextStyle(
                                      fontFamily: AppTheme.sansFamily,
                                      fontSize: 13,
                                      height: 18 / 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.brandPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Always-visible fallback: on web the browser's
                            // own context menu replaces Flutter's, so the
                            // selection toolbar's "Add note" never appears.
                            ValueListenableBuilder<String>(
                              valueListenable: _selectedText,
                              builder: (context, selected, _) {
                                return TextButton.icon(
                                  onPressed: () => _openNotesDialog(
                                    highlightedText: selected,
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: Text(
                                    selected.isEmpty
                                        ? 'Add a note'
                                        : 'Add note to highlighted text',
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.brandPurple,
                                    minimumSize: const Size(0, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: AppTheme.sansFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<List<ModuleNote>>(
                              stream: _notesStream,
                              builder: (context, snapshot) {
                                return LearningModuleFormattedContent(
                                  content: widget.content,
                                  moduleTitle: widget.title,
                                  moduleId: _noteModuleId,
                                  notes: snapshot.data ?? const <ModuleNote>[],
                                  onAddNote: (text) =>
                                      _openNotesDialog(highlightedText: text),
                                  onSelectionTextChanged: (text) =>
                                      _selectedText.value = text,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Single save action: bookmarks the lesson in the
                      // Journal (Learning notes), with a link back here.
                      HearthButton.primary(
                        label: 'Save',
                        icon: Icons.bookmark_add_outlined,
                        onPressed: _saveLessonToJournal,
                      ),

                      const SizedBox(height: 24),

                      // Medical citations (Guideline 1.4.1)
                      MedicalCitationsSection(topic: widget.title),

                      // Feedback now lives directly under the module content
                      // (see ModuleQuickFeedback above) so it isn't overlooked.
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
      ),
    );
  }

  /// Inline card that opens [QualitativeSurveyDialog] (replaces the old star-rating block).
  Widget _buildNewSurveySection() {
    return HearthCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HearthIconChip(Icons.rate_review_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Text('Module feedback', style: hearthCardTitleStyle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Share a quick rating about how clear and helpful this module was.',
            style: hearthCardBodyStyle,
          ),
          const SizedBox(height: 16),
          HearthButton.secondary(
              icon: Icons.rate_review_outlined,
              label: 'Give feedback',
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => QualitativeSurveyDialog(
                    feature: 'learning-modules',
                    title: 'Learning module feedback',
                    sourceId: widget.moduleId ?? widget.taskId,
                    questions: const [
                      'I understand what this means for my care.',
                      'I know what I need to do next.',
                      'I feel confident about my next steps.',
                    ],
                  ),
                );
              },
          ),
        ],
      ),
    );
  }
}

// Old survey section removed - replaced with QualitativeSurveyDialog
// Keeping class name for backward compatibility but it's now unused
class _ModuleReviewSectionOld extends StatefulWidget {
  final String moduleTitle;
  final String? taskId;

  const _ModuleReviewSectionOld({required this.moduleTitle, this.taskId});

  @override
  State<_ModuleReviewSectionOld> createState() =>
      _ModuleReviewSectionOldState();
}

class _ModuleReviewSectionOldState extends State<_ModuleReviewSectionOld> {
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  int _understandingRating = 0;
  int _nextStepsRating = 0;
  int _confidenceRating = 0;
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkIfSurveyCompleted();
  }

  Future<void> _checkIfSurveyCompleted() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || widget.taskId == null) return;

    try {
      final surveyQuery = await FirebaseFirestore.instance
          .collection('ModuleFeedback')
          .where('userId', isEqualTo: userId)
          .where('taskId', isEqualTo: widget.taskId)
          .limit(1)
          .get();

      if (surveyQuery.docs.isNotEmpty) {
        final surveyData = surveyQuery.docs.first.data();
        setState(() {
          _understandingRating = surveyData['understandingRating'] ?? 0;
          _nextStepsRating = surveyData['nextStepsRating'] ?? 0;
          _confidenceRating = surveyData['confidenceRating'] ?? 0;
          _commentsController.text = surveyData['comments'] ?? '';
          _hasSubmitted = true;
        });
      }
    } catch (e) {
      print('Error checking survey completion: $e');
    }
  }

  Future<void> _submitSurvey() async {
    if (_understandingRating == 0 ||
        _nextStepsRating == 0 ||
        _confidenceRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final surveyData = {
        'userId': userId,
        'moduleTitle': widget.moduleTitle,
        'taskId': widget.taskId,
        'understandingRating': _understandingRating,
        'nextStepsRating': _nextStepsRating,
        'confidenceRating': _confidenceRating,
        'comments': _commentsController.text.trim().isEmpty
            ? null
            : _commentsController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Check if survey already exists
      if (widget.taskId != null) {
        final existingSurvey = await FirebaseFirestore.instance
            .collection('ModuleFeedback')
            .where('userId', isEqualTo: userId)
            .where('taskId', isEqualTo: widget.taskId)
            .limit(1)
            .get();

        if (existingSurvey.docs.isNotEmpty) {
          // Update existing survey
          await existingSurvey.docs.first.reference.update(surveyData);
        } else {
          // Create new survey
          await FirebaseFirestore.instance
              .collection('ModuleFeedback')
              .add(surveyData);
        }
      } else {
        // If no taskId, just add without taskId reference
        await FirebaseFirestore.instance
            .collection('ModuleFeedback')
            .add(surveyData);
      }

      setState(() {
        _isSubmitting = false;
        _hasSubmitted = true;
      });

      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final userProfile = await _databaseService.getUserProfile(userId);
          await _analytics.logConfidenceSignalSubmitted(
            sourceId: widget.taskId,
            researchContentType: 'learning_module',
            understandMeaningScore: _understandingRating,
            knowNextStepScore: _nextStepsRating,
            confidenceScore: _confidenceRating,
            userProfile: userProfile,
          );
        }
      } catch (e) {
        print('Error tracking confidence signal: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting survey: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Widget _buildStarRating(
    String label,
    int rating,
    Function(int) onRatingChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: hearthCardTitleStyle),
        const SizedBox(height: 12),
        Center(
          child: HearthStarRating(
            value: rating,
            size: 40,
            onChanged: onRatingChanged,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            rating == 0 ? 'Tap stars to rate' : '$rating out of 5 stars',
            style: hearthCaptionStyle,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSubmitted) {
      return const HearthNote(
        icon: Icons.check,
        title: 'Thank you for completing the survey!',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HearthSectionHeading('Module Survey'),
        const SizedBox(height: 8),
        const Text(
          'Please rate your experience with this module:',
          style: hearthCardBodyStyle,
        ),
        const SizedBox(height: 24),
        _buildStarRating(
          'I understand what this means.',
          _understandingRating,
          (rating) {
            setState(() => _understandingRating = rating);
          },
        ),
        const SizedBox(height: 32),
        _buildStarRating('I know what I need to do next.', _nextStepsRating, (
          rating,
        ) {
          setState(() => _nextStepsRating = rating);
        }),
        const SizedBox(height: 32),
        _buildStarRating(
          'I feel confident about my next steps.',
          _confidenceRating,
          (rating) {
            setState(() => _confidenceRating = rating);
          },
        ),
        const SizedBox(height: 32),
        Text(
          'General Comments (Optional)',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentsController,
          decoration: const InputDecoration(
            hintText: 'Share any additional thoughts or feedback...',
          ),
          maxLines: 4,
          minLines: 3,
        ),
        const SizedBox(height: 32),
        HearthButton.primary(
          label: 'Submit Survey',
          loading: _isSubmitting,
          onPressed: _submitSurvey,
        ),
      ],
    );
  }
}
