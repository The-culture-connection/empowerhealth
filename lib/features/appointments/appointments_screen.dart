import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
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
                  // Calendar section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        children: [
                          // Calendar header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'November 2024',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                          DS.gapM,
                          // Calendar grid
                          _FullCalendarGrid(),
                        ],
                      ),
                    ),
                  ),
                  DS.gapXL,
                  
                  // Upcoming Appointments
                  Text(
                    'Upcoming Appointments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  DS.gapM,
                  
                  // Appointment cards
                  _AppointmentCard(
                    title: 'OB Appointment',
                    date: 'Tuesday, November 12, 2024',
                    time: '10:30 AM - 11:15 AM',
                    provider: 'Dr. Sarah Martinez, MD',
                    location: 'Women\'s Health Center',
                  ),
                  DS.gapM,
                  _AppointmentCard(
                    title: 'Ultrasound',
                    date: 'Friday, November 22, 2024',
                    time: '2:00 PM - 2:30 PM',
                    provider: 'Dr. Sarah Martinez, MD',
                    location: 'Women\'s Health Center',
                  ),
                  DS.gapM,
                  _AppointmentCard(
                    title: 'Lab Work',
                    date: 'Monday, November 25, 2024',
                    time: '9:00 AM - 9:15 AM',
                    provider: 'Lab Services',
                    location: 'Women\'s Health Center',
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

// Full Calendar Grid
class _FullCalendarGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final days = List.generate(30, (index) => index + 1);
    final appointments = [12, 22, 25]; // Days with appointments
    
    return Column(
      children: [
        // Week day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) => Expanded(
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
            width: (MediaQuery.of(context).size.width - AppTheme.spacingXL * 2 - AppTheme.spacingL * 2 - 24) / 7,
            height: 40,
            decoration: BoxDecoration(
              color: appointments.contains(day)
                  ? AppTheme.lightPrimary.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: day == 12
                  ? Border.all(color: AppTheme.lightPrimary, width: 2)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: appointments.contains(day)
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: appointments.contains(day)
                          ? AppTheme.lightPrimary
                          : AppTheme.lightForeground,
                    ),
                  ),
                  if (appointments.contains(day))
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.lightPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// Appointment Card
class _AppointmentCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String provider;
  final String location;

  const _AppointmentCard({
    required this.title,
    required this.date,
    required this.time,
    required this.provider,
    required this.location,
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.lightPrimary,
                    size: 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      DS.gapXS,
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightForeground.withOpacity(0.6),
                        ),
                      ),
                      DS.gapXS,
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DS.gapM,
            const Divider(),
            DS.gapM,
            _InfoRow(
              icon: Icons.person,
              label: 'Provider',
              value: provider,
            ),
            DS.gapS,
            _InfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: location,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.lightPrimary),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.lightForeground.withOpacity(0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
