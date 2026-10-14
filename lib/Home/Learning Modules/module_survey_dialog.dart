import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';
import '../../services/analytics_service.dart';
import '../../services/database_service.dart';
import '../../services/research/research_firestore_service.dart';
import '../../services/research/research_micro_measure_service.dart';

class ModuleSurveyDialog extends StatefulWidget {
  final String moduleTitle;
  final String taskId;
  final VoidCallback onSurveyCompleted;

  const ModuleSurveyDialog({
    super.key,
    required this.moduleTitle,
    required this.taskId,
    required this.onSurveyCompleted,
  });

  @override
  State<ModuleSurveyDialog> createState() => _ModuleSurveyDialogState();
}

class _ModuleSurveyDialogState extends State<ModuleSurveyDialog> {
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  int _understandingRating = 0;
  int _nextStepsRating = 0;
  int _confidenceRating = 0;
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
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

      try {
        final profile = await _databaseService.getUserProfile(userId);
        final avg = ((_understandingRating + _nextStepsRating + _confidenceRating) / 3)
            .round();
        await _analytics.logLearningModuleSurveySubmitted(
          surveyContext: 'module_archive_gate',
          moduleId: widget.taskId,
          averageRating: avg,
          userProfile: profile,
        );
        if (profile != null && profile.isResearchParticipant) {
          final sid = await ResearchFirestoreService.instance.ensureStudyId(profile);
          if (sid != null) {
            await ResearchMicroMeasureService.instance.submitMicroMeasure(
              studyId: sid,
              microUnderstand: _understandingRating,
              microNextStep: _nextStepsRating,
              microConfidence: _confidenceRating,
              contentId: widget.taskId,
              contentType: 'learning_module',
              microTsClientIso: DateTime.now().toUtc().toIso8601String(),
            );
          }
        }
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSurveyCompleted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey completed! Module archived.'),
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
          style: const TextStyle(
            fontFamily: AppTheme.sansFamily,
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: HearthStarRating(
            value: rating,
            size: 40,
            onChanged: (value) => onRatingChanged(value),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            rating == 0
                ? 'Tap stars to rate'
                : '$rating out of 5 stars',
            style: hearthCaptionStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Surface fill so the comments field reads as inset (Learn-Survey).
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: const BorderSide(color: AppTheme.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Complete Survey',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  HearthCircleButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Please complete the survey before archiving "${widget.moduleTitle}"',
                style: hearthCardBodyStyle,
              ),
              const SizedBox(height: 20),
              _buildStarRating(
                'I understand what this means.',
                _understandingRating,
                (rating) {
                  setState(() => _understandingRating = rating);
                },
              ),
              const SizedBox(height: 20),
              _buildStarRating(
                'I know what I need to do next.',
                _nextStepsRating,
                (rating) {
                  setState(() => _nextStepsRating = rating);
                },
              ),
              const SizedBox(height: 20),
              _buildStarRating(
                'I feel confident about my next steps.',
                _confidenceRating,
                (rating) {
                  setState(() => _confidenceRating = rating);
                },
              ),
              const SizedBox(height: 20),
              Text(
                'General Comments (Optional)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.ink),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentsController,
                decoration: const InputDecoration(
                  fillColor: AppTheme.surfaceInset,
                  hintText: 'Share any additional thoughts or feedback...',
                ),
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: 20),
              HearthButton.primary(
                label: 'Submit & Archive',
                loading: _isSubmitting,
                onPressed: _submitSurvey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
