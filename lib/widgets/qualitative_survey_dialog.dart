/**
 * Qualitative Survey Dialog
 * Reusable dialog for qualitative surveys with 1-5 rating questions
 */

import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../services/qualitative_survey_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
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
  final Map<int, int> _ratings = {}; // questionIndex -> rating (1-5)
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.brandPurple,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Questions
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please rate your experience (1 = Strongly Disagree, 5 = Strongly Agree)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                      ),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || !_allQuestionsAnswered() ? null : _submitSurvey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
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
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final value = i + 1;
              final isSelected = rating == value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _ratings[index] = value;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.brandPurple : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppTheme.brandPurple : AppTheme.borderLight,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }),
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

      if (mounted) {
        Navigator.of(context).pop();
        if (widget.onCompleted != null) {
          widget.onCompleted!();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Thank you for your feedback!'),
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
