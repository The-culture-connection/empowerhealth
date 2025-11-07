import 'package:flutter/material.dart';

import '../../design_system/background.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Feedback'),
      ),
      body: DSBackground(
        imagePath: 'assets/images/bg4.png',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest updates',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'We listen to your feedback and share improvements here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                Expanded(
                  child: ListView.separated(
                    itemCount: _feedbackUpdates.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacingM),
                    itemBuilder: (context, index) {
                      final update = _feedbackUpdates[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.lightbulb_outline,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          update.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          update.dateLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              Text(
                                update.summary,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppTheme.spacingS),
                              TextButton.icon(
                                onPressed: () {
                                  // TODO: open feedback details
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Read more'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

class _FeedbackUpdate {
  final String title;
  final String dateLabel;
  final String summary;

  const _FeedbackUpdate({
    required this.title,
    required this.dateLabel,
    required this.summary,
  });
}

const List<_FeedbackUpdate> _feedbackUpdates = [
  _FeedbackUpdate(
    title: 'Visit summaries revamped',
    dateLabel: 'Jan 2',
    summary:
        'Clearer headings and quick highlights were added after several of you asked for easier scanning.',
  ),
  _FeedbackUpdate(
    title: 'Calendar sync is smoother',
    dateLabel: 'Dec 22',
    summary:
        'Resolved duplicate events when connecting Google Calendar. Thanks to the beta group for the reports!',
  ),
  _FeedbackUpdate(
    title: 'Community notifications',
    dateLabel: 'Dec 7',
    summary:
        'You can now choose digest emails or push alerts based on your favorite topics.',
  ),
];
