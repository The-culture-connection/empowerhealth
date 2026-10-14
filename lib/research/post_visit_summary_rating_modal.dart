import 'package:flutter/material.dart';
import '../design_system/hearth.dart';
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
    final textTheme = Theme.of(context).textTheme;
    // Shape and fill come from the dialog theme.
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.headline, style: textTheme.headlineMedium),
                  ),
                  const SizedBox(width: 12),
                  HearthCircleButton(
                    icon: Icons.close,
                    iconSize: 18,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Your answers help us learn whether the summary was clear and useful (1 = not at all, 5 = very much).',
                style: textTheme.bodyMedium,
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
