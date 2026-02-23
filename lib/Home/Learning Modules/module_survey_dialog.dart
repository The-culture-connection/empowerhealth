import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../cors/ui_theme.dart';

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
          backgroundColor: Colors.orange,
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

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSurveyCompleted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Survey completed! Module archived.'),
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

  Widget _buildStarRating(String label, int rating, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                onRatingChanged(index + 1);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: 40,
                  color: index < rating 
                      ? Colors.amber 
                      : Colors.grey,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            rating == 0 
                ? 'Tap stars to rate'
                : '$rating out of 5 stars',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Please complete the survey before archiving "${widget.moduleTitle}"',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
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
              const Text(
                'General Comments (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentsController,
                decoration: InputDecoration(
                  hintText: 'Share any additional thoughts or feedback...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.brandPurple, width: 2),
                  ),
                ),
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSurvey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                          'Submit & Archive',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
