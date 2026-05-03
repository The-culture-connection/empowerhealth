import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../services/research/research_micro_measure_service.dart';
import 'micro_measure_prompt.dart';

/// After AVS / visit-summary flows — ties micro-measures to a stable summary or upload id.
class PostVisitSummaryRatingModal extends StatefulWidget {
  const PostVisitSummaryRatingModal({
    super.key,
    required this.studyId,
    required this.contentId,
    required this.contentType,
    this.headline = 'After your visit summary',
  });

  final String studyId;
  final String contentId;

  /// e.g. `visit_summary_avs` (upload + AI) or `visit_summary_notes` (typed summary doc).
  final String contentType;
  final String headline;

  @override
  State<PostVisitSummaryRatingModal> createState() => _PostVisitSummaryRatingModalState();
}

class _PostVisitSummaryRatingModalState extends State<PostVisitSummaryRatingModal> {
  int _u = 0, _n = 0, _c = 0;
  bool _busy = false;

  Future<void> _submit() async {
    if (_u == 0 || _n == 0 || _c == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate all three items (1–5).'), backgroundColor: Colors.orange),
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
          const SnackBar(content: Text('Thanks — your responses were saved.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                      widget.headline,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                'Your answers help us learn whether the summary was clear and useful (1 = not at all, 5 = very much).',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.brandPurple),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit'),
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
