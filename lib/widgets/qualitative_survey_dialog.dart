/**
 * Qualitative Survey Dialog
 * Reusable dialog for qualitative surveys with 1-5 rating questions
 */

import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../services/qualitative_survey_service.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QualitativeSurveyDialog extends StatefulWidget {
  final String feature;
  final List<String> questions;
  final String title;
  final String? sourceId;
  final VoidCallback? onCompleted;

  const QualitativeSurveyDialog({
    super.key,
    required this.feature,
    required this.questions,
    required this.title,
    this.sourceId,
    this.onCompleted,
  });

  @override
  State<QualitativeSurveyDialog> createState() => _QualitativeSurveyDialogState();
}

class _QualitativeSurveyDialogState extends State<QualitativeSurveyDialog> {
  final QualitativeSurveyService _surveyService = QualitativeSurveyService();
  final DatabaseService _databaseService = DatabaseService();
  final AnalyticsService _analytics = AnalyticsService();
  final Map<int, int> _ratings = {}; // questionIndex -> rating (1-5)
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  HearthCircleButton(
                    icon: Icons.close,
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Questions
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please rate your experience (1 = Strongly Disagree, 5 = Strongly Agree)',
                      style: hearthCardBodyStyle,
                    ),
                    const SizedBox(height: 24),
                    ...widget.questions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      return _buildQuestion(index, question);
                    }),
                  ],
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.borderWarm, width: 1),
                ),
              ),
              child: HearthButton.primary(
                label: 'Submit',
                loading: _isSubmitting,
                onPressed: !_allQuestionsAnswered() ? null : _submitSurvey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(int index, String question) {
    final rating = _ratings[index] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Shrink the 5 rating circles to fit narrow screens (44-48).
              final size = ((constraints.maxWidth - 8 * 4) / 5).clamp(44.0, 48.0);
              return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final value = i + 1;
              final isSelected = rating == value;
              return Semantics(
                button: true,
                selected: isSelected,
                child: GestureDetector(
                onTap: () {
                  setState(() {
                    _ratings[index] = value;
                  });
                },
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.brandPurple : AppTheme.surface,
                    border: Border.all(
                      color: isSelected ? AppTheme.brandPurple : AppTheme.borderWarm,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      value.toString(),
                      style: TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppTheme.onPurple : AppTheme.ink,
                      ),
                    ),
                  ),
                ),
                ),
              );
            }),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _allQuestionsAnswered() {
    return _ratings.length == widget.questions.length &&
        _ratings.values.every((rating) => rating >= 1 && rating <= 5);
  }

  Future<void> _submitSurvey() async {
    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final userProfile = await _databaseService.getUserProfile(userId);

      // Convert ratings to question-answer format
      final questions = widget.questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        return {
          'question': question,
          'answer': _ratings[index] ?? 0,
        };
      }).toList();

      await _surveyService.saveQualitativeSurvey(
        feature: widget.feature,
        questions: questions,
        userProfile: userProfile,
        sourceId: widget.sourceId,
      );

      if (widget.feature == 'learning-modules') {
        final ratings = _ratings.values.toList();
        final avg = ratings.isEmpty
            ? null
            : (ratings.fold<int>(0, (a, b) => a + b) / ratings.length).round();
        await _analytics.logLearningModuleSurveySubmitted(
          surveyContext: 'qualitative_feedback',
          moduleId: widget.sourceId ?? 'unknown',
          averageRating: avg,
          userProfile: userProfile,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        if (widget.onCompleted != null) {
          widget.onCompleted!();
        }
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
}
