import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class RecorderTab extends StatefulWidget {
  const RecorderTab({super.key});

  @override
  State<RecorderTab> createState() => _RecorderTabState();
}

class _RecorderTabState extends State<RecorderTab> {
  bool _isRecording = false;
  int _recordingSeconds = 0;

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      body: Column(
        children: [
          DS.heroHeader(
            context: context,
            title: 'Record Visit',
            subtitle: 'Secure, private recording',
            backgroundImage: backgroundImage,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Column(
                children: [
                  DS.gapXL,
                  // Recording status
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isRecording
                            ? [
                                AppTheme.error.withOpacity(0.2),
                                AppTheme.error.withOpacity(0.1),
                              ]
                            : [
                                AppTheme.lightPrimary.withOpacity(0.2),
                                AppTheme.lightAccent.withOpacity(0.1),
                              ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? AppTheme.error : AppTheme.lightPrimary,
                          boxShadow: _isRecording
                              ? [
                                  BoxShadow(
                                    color: AppTheme.error.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : AppTheme.cardShadowLight,
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  DS.gapXL,
                  
                  // Timer
                  if (_isRecording)
                    Column(
                      children: [
                        Text(
                          _formatDuration(_recordingSeconds),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.error,
                          ),
                        ),
                        DS.gapS,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.error,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Recording',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Text(
                          'Ready to Record',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        DS.gapS,
                        Text(
                          'Tap to start recording your visit',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.lightForeground.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  DS.gapXXL,
                  
                  // Main action button
                  DS.cta(
                    _isRecording ? 'Stop Recording' : 'Start Recording',
                    icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    onPressed: () {
                      setState(() {
                        _isRecording = !_isRecording;
                        if (!_isRecording) {
                          _recordingSeconds = 0;
                        }
                      });
                    },
                  ),
                  DS.gapXL,
                  
                  // Info card
                  Card(
                    color: AppTheme.lightAccent.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.security,
                            size: 40,
                            color: AppTheme.lightAccent,
                          ),
                          DS.gapM,
                          const Text(
                            'Privacy & Security',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          DS.gapS,
                          Text(
                            'Your recordings are encrypted and stored securely on your device. You have full control over what is shared.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.lightForeground.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  DS.gapL,
                  
                  // Recent recordings
                  if (!_isRecording) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent Recordings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    DS.gapM,
                    DS.messageTile(
                      title: 'Appointment - Nov 5, 2024',
                      subtitle: 'Duration: 18:32 • Transcribed',
                      avatarText: '🎙️',
                      onTap: () {},
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {},
                        color: AppTheme.lightPrimary,
                      ),
                    ),
                    DS.messageTile(
                      title: 'Appointment - Oct 22, 2024',
                      subtitle: 'Duration: 15:47 • Transcribed',
                      avatarText: '🎙️',
                      onTap: () {},
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {},
                        color: AppTheme.lightPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
