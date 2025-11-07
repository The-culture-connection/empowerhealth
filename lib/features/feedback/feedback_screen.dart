import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request feedback section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request Feedback',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          DS.gapM,
                          TextField(
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Describe what you want input on...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                            ),
                          ),
                          DS.gapM,
                          DS.cta(
                            'Send to Doula / Provider',
                            icon: Icons.send,
                            onPressed: () {
                              // TODO: Send feedback request
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  DS.gapXL,
                  
                  // Most recent messages header
                  Text(
                    'Most Recent Messages',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  DS.gapM,
                  
                  // Feedback cards
                  _FeedbackCard(
                    sender: 'Doula A',
                    time: '2h ago',
                    message: 'Consider asking about Tdap vaccine at your next appointment. It\'s recommended during pregnancy.',
                  ),
                  DS.gapM,
                  _FeedbackCard(
                    sender: 'Provider B',
                    time: 'Yesterday',
                    message: 'All labs look good. Next step: glucose screen. Make sure to fast for 8 hours before.',
                  ),
                  DS.gapM,
                  _FeedbackCard(
                    sender: 'Doula A',
                    time: '3 days ago',
                    message: 'Great questions about birth positions! I\'ve sent you some resources to review.',
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

class _FeedbackCard extends StatelessWidget {
  final String sender;
  final String time;
  final String message;

  const _FeedbackCard({
    required this.sender,
    required this.time,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.lightSecondary,
                  child: Text(
                    sender[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sender,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightForeground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DS.gapM,
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.lightForeground.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
