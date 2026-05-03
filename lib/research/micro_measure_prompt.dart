import 'package:flutter/material.dart';

/// Shared 1–5 Likert prompts for immediate outcome signals (research micro-measures).
class MicroMeasurePrompt extends StatelessWidget {
  const MicroMeasurePrompt({
    super.key,
    required this.understand,
    required this.nextStep,
    required this.confidence,
    required this.onUnderstand,
    required this.onNextStep,
    required this.onConfidence,
  });

  final int understand;
  final int nextStep;
  final int confidence;
  final ValueChanged<int> onUnderstand;
  final ValueChanged<int> onNextStep;
  final ValueChanged<int> onConfidence;

  Widget _row(String label, int rating, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => onChanged(index + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: 40,
                  color: index < rating ? Colors.amber : Colors.grey,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            rating == 0 ? 'Tap stars to rate (1 = low, 5 = high)' : '$rating of 5',
            style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('I understand what this means.', understand, onUnderstand),
        const SizedBox(height: 24),
        _row('I know what I need to do next.', nextStep, onNextStep),
        const SizedBox(height: 24),
        _row('I feel confident about my next steps.', confidence, onConfidence),
      ],
    );
  }
}
