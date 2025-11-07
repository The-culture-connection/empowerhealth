import 'package:flutter/material.dart';

import '../../design_system/background.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class TranscriptionScreen extends StatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  bool _isRecording = false;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Transcription'),
      ),
      body: DSBackground(
        imagePath: 'assets/images/bg2.png',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingXL),
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(_isRecording ? 0.3 : 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isRecording ? Icons.mic : Icons.mic_none,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        Text(
                          _isRecording
                              ? 'Listening... Speak freely.'
                              : 'Tap to start capturing your visit.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        DS.cta(
                          _isRecording ? 'Stop recording' : 'Start recording',
                          icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
                          onPressed: _toggleRecording,
                          fullWidth: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recent transcripts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                for (final transcript in _recentTranscripts)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        child: Icon(
                          Icons.description_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(transcript.title),
                      subtitle: Text(
                        '${transcript.dateLabel} · ${transcript.summary}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          // TODO: open transcript details
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Transcript {
  final String title;
  final String dateLabel;
  final String summary;

  const _Transcript({
    required this.title,
    required this.dateLabel,
    required this.summary,
  });
}

const List<_Transcript> _recentTranscripts = [
  _Transcript(
    title: 'Prenatal Check-up',
    dateLabel: 'Jan 5 • 18 min',
    summary: 'Discussed glucose screening results and next ultrasound schedule.',
  ),
  _Transcript(
    title: 'Doula Consultation',
    dateLabel: 'Dec 28 • 12 min',
    summary: 'Covered breathing routines and birth plan adjustments.',
  ),
  _Transcript(
    title: 'Nutrition Coaching',
    dateLabel: 'Dec 18 • 22 min',
    summary: 'Meal plan updates and hydration tips for third trimester.',
  ),
];
