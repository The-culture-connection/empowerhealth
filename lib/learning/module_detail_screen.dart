import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'module_notes.dart';
import 'notes_dialog.dart';
import '../widgets/ai_disclaimer_banner.dart';
import '../widgets/learning_module_formatted_content.dart';
import '../widgets/medical_citations_section.dart';
import '../widgets/module_quick_feedback.dart';

class ModuleDetailScreen extends StatefulWidget {
  final String title;
  final String trimester;
  final String type;
  final String? preloadedContent;

  const ModuleDetailScreen({
    super.key,
    required this.title,
    required this.trimester,
    required this.type,
    this.preloadedContent,
  });

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey _contentKey = GlobalKey();
  String? _content;
  bool _isLoading = false;
  bool _exiting = false;
  String? _error;
  UserProfile? _userProfile;
  String? _selectedText;

  /// The user's notes on this lesson (highlighted in the text below).
  late final Stream<List<ModuleNote>> _notesStream =
      watchModuleNotes(moduleTitle: widget.title);

  @override
  void initState() {
    super.initState();
    if (widget.preloadedContent != null) {
      _content = widget.preloadedContent;
    } else {
      _loadUserProfileAndContent();
    }
  }

  Future<void> _loadUserProfileAndContent() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _userProfile = await _databaseService.getUserProfile(userId);
    }
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.type == 'rights') {
        final result = await _functionsService.generateRightsContent(
          topic: widget.title,
        );
        setState(() {
          _content = result['content'];
          _isLoading = false;
        });
      } else {
        // Prepare user profile data for personalization
        Map<String, dynamic>? profileData;
        if (_userProfile != null) {
          profileData = {
            'chronicConditions': _userProfile!.chronicConditions,
            'healthLiteracyGoals': _userProfile!.healthLiteracyGoals,
            'insuranceType': _userProfile!.insuranceType,
            'providerPreferences': _userProfile!.providerPreferences,
            'educationLevel': _userProfile!.educationLevel,
          };
        }

        final result = await _functionsService.generateLearningContent(
          topic: widget.title,
          trimester: widget.trimester,
          moduleType: widget.type,
          userProfile: profileData,
        );
        setState(() {
          _content = result['content'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openNotesDialog({String? highlightedText}) {
    showDialog(
      context: context,
      builder: (context) => NotesDialog(
        preFilledText: highlightedText,
        moduleTitle: widget.title,
        moduleId: null, // Could be passed if we track module IDs
      ),
    );
  }

  void _handleTextSelection() {
    // Get selected text from clipboard (workaround for text selection)
    Clipboard.getData(Clipboard.kTextPlain).then((clipboardData) {
      if (clipboardData != null && clipboardData.text != null && clipboardData.text!.isNotEmpty) {
        setState(() {
          _selectedText = clipboardData.text;
        });
        _openNotesDialog(highlightedText: _selectedText);
      }
    });
  }

  /// Shows the exit feedback modal, then leaves the screen. Guarded so it runs
  /// once whether triggered by the app-bar back or the system back gesture.
  Future<void> _confirmExit() async {
    if (_exiting) return;
    _exiting = true;
    await showModuleExitFeedbackSheet(
      context,
      feature: 'learning-modules',
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
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back goes through maybePop so PopScope still shows the exit sheet.
              HearthPushedHeader(
                title: widget.title,
                actions: [
                  HearthCircleButton(
                    icon: Icons.note_add_outlined,
                    tooltip: 'Add Note',
                    onPressed: () => _openNotesDialog(),
                  ),
                ],
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.brandPurple),
            SizedBox(height: 16),
            Text('Loading content...', style: hearthCardBodyStyle),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HearthIconChip(Icons.info_outline, size: 64, iconSize: 30),
              const SizedBox(height: 16),
              Text(
                'Error loading content',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: hearthCardBodyStyle),
              const SizedBox(height: 20),
              HearthButton.primary(
                label: 'Try Again',
                onPressed: _loadContent,
                expand: false,
              ),
            ],
          ),
        ),
      );
    }

    if (_content == null) {
      return const Center(child: Text('No content available', style: hearthCardBodyStyle));
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trimester badge
              HearthTag(
                '${widget.trimester} Trimester',
                tone: HearthTagTone.tintPurple,
              ),
              const SizedBox(height: 16),
              
              // AI Disclaimer Banner (for AI-generated content)
              const AIDisclaimerBanner(
                customMessage: 'This content helps you understand your care.',
                customSubMessage: 'It does not replace medical advice from your provider.',
              ),
              const SizedBox(height: 16),
              
              // Content with markdown support and text selection
              StreamBuilder<List<ModuleNote>>(
                stream: _notesStream,
                builder: (context, snapshot) => _SelectableMarkdownWidget(
                  content: _content!,
                  moduleTitle: widget.title,
                  notes: snapshot.data ?? const <ModuleNote>[],
                  onTextSelected: (selectedText) {
                    _openNotesDialog(highlightedText: selectedText);
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Medical citations (Guideline 1.4.1)
              MedicalCitationsSection(topic: widget.title),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleReviewSection extends StatefulWidget {
  final String moduleTitle;
  final String? taskId; // Add taskId to track which module this survey is for

  const _ModuleReviewSection({required this.moduleTitle, this.taskId});

  @override
  State<_ModuleReviewSection> createState() => _ModuleReviewSectionState();
}

class _ModuleReviewSectionState extends State<_ModuleReviewSection> {
  int _understandingRating = 0;
  int _nextStepsRating = 0;
  int _confidenceRating = 0;
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkIfSurveyCompleted();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
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
    if (_understandingRating == 0 || _nextStepsRating == 0 || _confidenceRating == 0) {
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

  Widget _buildStarRating(String label, int rating, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 12),
        Center(
          child: HearthStarRating(
            value: rating,
            size: 40,
            onChanged: (star) => onRatingChanged(star),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            rating == 0
                ? 'Tap stars to rate'
                : '$rating out of 5 stars',
            style: hearthCaptionStyle,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSubmitted) {
      return const HearthCard(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.brandPurple),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Thank you for completing the survey!',
                style: hearthCardTitleStyle,
              ),
            ),
          ],
        ),
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
        _buildStarRating(
          'I know what I need to do next.',
          _nextStepsRating,
          (rating) {
            setState(() => _nextStepsRating = rating);
          },
        ),
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
        // Border and fill come from the Hearth input theme.
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
          onPressed: _isSubmitting ? null : _submitSurvey,
          loading: _isSubmitting,
        ),
      ],
    );
  }
}

// Selectable markdown widget that allows text selection
class _SelectableMarkdownWidget extends StatefulWidget {
  final String content;
  final String moduleTitle;
  final Function(String) onTextSelected;
  final List<ModuleNote> notes;

  const _SelectableMarkdownWidget({
    required this.content,
    required this.moduleTitle,
    required this.onTextSelected,
    this.notes = const <ModuleNote>[],
  });

  @override
  State<_SelectableMarkdownWidget> createState() => _SelectableMarkdownWidgetState();
}

class _SelectableMarkdownWidgetState extends State<_SelectableMarkdownWidget> {
  @override
  Widget build(BuildContext context) {
    // Fix $1 formatting issue - replace $1 with proper section breaks
    final cleanedContent = widget.content.replaceAll('\$1', '\n\n---\n\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selectable text for highlighting (removed duplicate markdown display)
        HearthCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 18, color: AppTheme.brandPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Long-press text below to highlight and add a note',
                      style: hearthCaptionStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LearningModuleFormattedContent(
                content: cleanedContent,
                moduleTitle: widget.moduleTitle,
                notes: widget.notes,
                // Adds "Add note" to the selection context menu (the old
                // custom selectionControls toolbar was ignored by Flutter).
                onAddNote: (text) => widget.onTextSelected(text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
