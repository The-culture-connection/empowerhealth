import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../services/research/research_micro_measure_service.dart';
import 'micro_measure_prompt.dart';

/// Shown after module completion when the list path did not collect ratings via [ModuleSurveyDialog].
class PostModuleRatingModal extends StatefulWidget {
  const PostModuleRatingModal({
    super.key,
    required this.studyId,
    required this.contentId,
    required this.moduleTitle,
    this.contentType = 'learning_module',
  });

  final String studyId;
  final String contentId;
  final String moduleTitle;
  final String contentType;

  @override
  State<PostModuleRatingModal> createState() => _PostModuleRatingModalState();
}

class _PostModuleRatingModalState extends State<PostModuleRatingModal> {
  int _u = 0, _n = 0, _c = 0;
  bool _busy = false;

  Future<void> _submit() async {
    if (_u == 0 || _n == 0 || _c == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate all three items (1–5).')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ResearchMicroMeasureService.instance.submitMicroMeasure(
        studyId: widget.studyId,
        microUnderstand: _u,
        microNextStep: _n,
        microConfidence: _c,
        contentId: widget.contentId,
        contentType: widget.contentType,
        microTsClientIso: DateTime.now().toUtc().toIso8601String(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks! Your responses were saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Same surface dialog as the module survey (Learn-Rating).
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
                      'Quick check-in',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  HearthCircleButton(
                    icon: Icons.close,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You finished "${widget.moduleTitle}". How are you feeling about it?',
                style: hearthCardBodyStyle,
              ),
              const SizedBox(height: 20),
              MicroMeasurePrompt(
                understand: _u,
                nextStep: _n,
                confidence: _c,
                onUnderstand: (v) => setState(() => _u = v),
                onNextStep: (v) => setState(() => _n = v),
                onConfidence: (v) => setState(() => _c = v),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  HearthButton.text(
                    label: 'Skip',
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  HearthButton.primary(
                    label: 'Submit',
                    expand: false,
                    loading: _busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
