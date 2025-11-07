import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class TranscriptionScreen extends StatelessWidget {
  const TranscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background image - stays in place
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightBackground,
              ),
              child: backgroundImage != null
                  ? Image.asset(
                      backgroundImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.lightBackground,
                                AppTheme.lightMuted,
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.lightBackground,
                            AppTheme.lightMuted,
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Recording section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXL),
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppTheme.lightPrimary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic,
                              size: 64,
                              color: AppTheme.lightPrimary,
                            ),
                          ),
                          DS.gapXL,
                          const Text(
                            'Ready to Record',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          DS.gapM,
                          Text(
                            'Tap the button below to start recording your appointment',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.lightForeground.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          DS.gapXL,
                          DS.cta(
                            'Start Recording',
                            icon: Icons.fiber_manual_record,
                            onPressed: () {
                              // TODO: Start recording
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  DS.gapXL,
                  
                  // Recent transcriptions
                  Text(
                    'Recent Transcriptions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  DS.gapM,
                  
                  _TranscriptionCard(
                    title: 'Visit 10/31 • 3 min summary',
                    date: 'October 31, 2024',
                    preview: 'Fundal height 28cm, GDM screen ordered. Everything looking good!',
                  ),
                  DS.gapM,
                  _TranscriptionCard(
                    title: 'Visit 10/15 • 2 min summary',
                    date: 'October 15, 2024',
                    preview: 'BP 118/72, fetal HR 140, next labs scheduled.',
                  ),
                  DS.gapM,
                  _TranscriptionCard(
                    title: 'Visit 9/28 • 5 min summary',
                    date: 'September 28, 2024',
                    preview: 'Routine checkup, all vitals normal. Discussed nutrition plan.',
                  ),
                  DS.gapXL,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptionCard extends StatelessWidget {
  final String title;
  final String date;
  final String preview;

  const _TranscriptionCard({
    required this.title,
    required this.date,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to full transcription
        },
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.article,
                      color: AppTheme.lightPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        DS.gapXS,
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.lightForeground.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.lightPrimary,
                  ),
                ],
              ),
              DS.gapM,
              Text(
                preview,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.lightForeground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
