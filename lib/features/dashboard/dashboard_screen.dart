import 'package:flutter/material.dart';

import '../../design_system/background.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';
import '../appointments/appointment_data.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onViewAppointments;
  final VoidCallback onOpenTranscription;
  final VoidCallback onOpenCommunity;
  final VoidCallback onOpenFeedback;

  const DashboardScreen({
    super.key,
    required this.onViewAppointments,
    required this.onOpenTranscription,
    required this.onOpenCommunity,
    required this.onOpenFeedback,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = sampleAppointments
        .where((appointment) =>
            appointment.dateTime.isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final nextAppointment = upcoming.isNotEmpty ? upcoming.first : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingM),
            child: FilledButton.icon(
              onPressed: widget.onOpenTranscription,
              icon: const Icon(Icons.mic),
              label: const Text('Transcribe'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: DSBackground(
        imagePath: 'assets/images/bg5.png',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Maya 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  nextAppointment != null
                      ? 'Your next visit is ${_formatDate(nextAppointment.dateTime)} with ${nextAppointment.provider}.'
                      : 'No upcoming appointments — schedule your next visit to stay on track.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                _AppointmentsOverviewCard(
                  selectedDate: _selectedDate,
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  upcoming: upcoming.take(2).toList(),
                  onTap: widget.onViewAppointments,
                ),
                const SizedBox(height: AppTheme.spacingXL),
                _VoiceNotesCard(onOpenTranscription: widget.onOpenTranscription),
                const SizedBox(height: AppTheme.spacingXL),
                Text(
                  'Community pulse',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: _SquareMessageCard(
                        title: 'Community',
                        author: _latestCommunityMessage.author,
                        excerpt: _latestCommunityMessage.excerpt,
                        icon: Icons.forum,
                        onTap: widget.onOpenCommunity,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    Expanded(
                      child: _SquareMessageCard(
                        title: 'Feedback',
                        author: _latestFeedbackMessage.author,
                        excerpt: _latestFeedbackMessage.excerpt,
                        icon: Icons.feedback,
                        onTap: widget.onOpenFeedback,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthNames[date.month]} ${date.day}';
  }
}

class _AppointmentsOverviewCard extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final List<Appointment> upcoming;
  final VoidCallback onTap;

  const _AppointmentsOverviewCard({
    required this.selectedDate,
    required this.onDateChanged,
    required this.upcoming,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      'Upcoming visits',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: SizedBox(
                  height: 260,
                  child: CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onDateChanged: onDateChanged,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              for (final appointment in upcoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: Row(
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
                          Icons.event_available,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${appointment.provider} · ${_formatDateTime(appointment.dateTime)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${_monthNames[date.month]} ${date.day} · $hour:$minute $suffix';
  }
}

class _VoiceNotesCard extends StatelessWidget {
  final VoidCallback onOpenTranscription;

  const _VoiceNotesCard({required this.onOpenTranscription});

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
                Icon(
                  Icons.mic,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Record a visit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Capture conversations and convert them into smart notes instantly.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                DS.cta(
                  'Start recording',
                  icon: Icons.fiber_manual_record,
                  onPressed: onOpenTranscription,
                  fullWidth: false,
                ),
                const SizedBox(width: AppTheme.spacingM),
                DS.secondary(
                  'Past transcripts',
                  icon: Icons.history,
                  onPressed: onOpenTranscription,
                  fullWidth: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareMessageCard extends StatelessWidget {
  final String title;
  final String author;
  final String excerpt;
  final IconData icon;
  final VoidCallback onTap;

  const _SquareMessageCard({
    required this.title,
    required this.author,
    required this.excerpt,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Latest from $author',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    excerpt,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 4,
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

class _LatestMessage {
  final String author;
  final String excerpt;

  const _LatestMessage({
    required this.author,
    required this.excerpt,
  });
}

const _LatestMessage _latestCommunityMessage = _LatestMessage(
  author: 'Danielle',
  excerpt: '32 weeks today and the backaches are real. Any stretches that helped you?',
);

const _LatestMessage _latestFeedbackMessage = _LatestMessage(
  author: 'Support Team',
  excerpt: 'Thanks for sharing your experience! We\'ve updated the visit summaries view.',
);

const List<String> _monthNames = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
