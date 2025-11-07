import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';
import '../../core/constants.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
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
                  // App Bar with Transcription button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          DS.logo(size: 32),
                          const SizedBox(width: AppTheme.spacingM),
                          Text(
                            'Dashboard',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      // Transcription button in top right
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.lightPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: AppTheme.lightPrimary,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.transcription);
                        },
                      ),
                    ],
                  ),
                  DS.gapXL,
                  
                  // Welcome section
                  Text(
                    'Welcome back, Sarah',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  DS.gapS,
                  Text(
                    'Here\'s an overview of your prenatal journey',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightForeground.withOpacity(0.6),
                        ),
                  ),
                  DS.gapXL,
                  
                  // Appointments Calendar Widget
                  _AppointmentsCalendarWidget(),
                  DS.gapXL,
                  
                  // Microphone Widget
                  _MicrophoneWidget(),
                  DS.gapXL,
                  
                  // Community and Feedback Widgets
                  Row(
                    children: [
                      Expanded(
                        child: _CommunityWidget(),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _FeedbackWidget(),
                      ),
                    ],
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

// Appointments Calendar Widget
class _AppointmentsCalendarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, Routes.appointments);
        },
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Appointments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.appointments);
                    },
                  ),
                ],
              ),
              DS.gapM,
              // Simple calendar view
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.lightPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Column(
                  children: [
                    // Calendar header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'November 2024',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    DS.gapM,
                    // Calendar days
                    _CalendarGrid(),
                    DS.gapM,
                    // Upcoming appointment highlight
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.lightPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppTheme.lightPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'OB Appointment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Tuesday, Nov 12 • 10:30 AM',
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
}

// Simple Calendar Grid
class _CalendarGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final days = List.generate(30, (index) => index + 1);
    
    return Column(
      children: [
        // Week day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) => SizedBox(
            width: 32,
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightForeground.withOpacity(0.5),
              ),
            ),
          )).toList(),
        ),
        DS.gapS,
        // Calendar days
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: days.map((day) => Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: day == 12
                  ? AppTheme.lightPrimary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: day == 12 ? FontWeight.w600 : FontWeight.w400,
                  color: day == 12
                      ? Colors.white
                      : AppTheme.lightForeground,
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// Microphone Widget
class _MicrophoneWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, Routes.transcription);
        },
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.mic,
                  color: AppTheme.lightPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Record Visit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DS.gapXS,
                    Text(
                      'Tap to start recording your appointment',
                      style: TextStyle(
                        fontSize: 14,
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
        ),
      ),
    );
  }
}

// Community Widget
class _CommunityWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, Routes.community);
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
                      color: AppTheme.lightAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: AppTheme.lightAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  const Text(
                    'Community',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              DS.gapM,
              // Most recent message preview
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.lightMuted.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How did you prep for GDM test?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    DS.gapXS,
                    Text(
                      '12 replies • 5m ago',
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
        ),
      ),
    );
  }
}

// Feedback Widget
class _FeedbackWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, Routes.feedback);
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
                      color: AppTheme.lightSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.feedback,
                      color: AppTheme.lightSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  const Text(
                    'Feedback',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              DS.gapM,
              // Most recent message preview
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.lightMuted.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doula A • 2h ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightForeground.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DS.gapXS,
                    Text(
                      'Consider asking about Tdap...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
