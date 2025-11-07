import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class TranscriptionScreen extends StatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  bool _isRecording = false;
  String _transcriptionText = '';
  
  // Sample transcriptions
  final List<Map<String, dynamic>> _recentTranscriptions = [
    {
      'title': 'Doctor Visit - Dr. Smith',
      'date': '2 hours ago',
      'preview': 'Patient reports feeling better after medication...',
    },
    {
      'title': 'Physical Therapy Session',
      'date': 'Yesterday',
      'preview': 'Completed range of motion exercises, good progress...',
    },
    {
      'title': 'Consultation with Specialist',
      'date': '3 days ago',
      'preview': 'Discussed treatment options and next steps...',
    },
  ];

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _transcriptionText = 'Recording... Speak now.';
      } else {
        _transcriptionText = 'Recording stopped. Processing transcription...';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fixed background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
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
          
          // Scrollable content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      const Text(
                        'Transcription',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recording Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingXL),
                            child: Column(
                              children: [
                                // Microphone Button
                                GestureDetector(
                                  onTap: _toggleRecording,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isRecording
                                          ? AppTheme.error
                                          : AppTheme.lightPrimary,
                                      boxShadow: _isRecording
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.error.withOpacity(0.3),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                
                                DS.gapL,
                                
                                // Status Text
                                Text(
                                  _isRecording ? 'Recording...' : 'Tap to Start Recording',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _isRecording
                                        ? AppTheme.error
                                        : AppTheme.lightForeground,
                                  ),
                                ),
                                
                                if (_transcriptionText.isNotEmpty) ...[
                                  DS.gapM,
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingM),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightMuted,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    child: Text(
                                      _transcriptionText,
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        DS.gapXL,
                        
                        // Recent Transcriptions Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Transcriptions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        DS.gapM,
                        
                        // Transcriptions List
                        ..._recentTranscriptions.map((transcription) => Card(
                              margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightPrimary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    color: AppTheme.lightPrimary,
                                  ),
                                ),
                                title: Text(
                                  transcription['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      transcription['preview'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      transcription['date'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.lightForeground.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {},
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
