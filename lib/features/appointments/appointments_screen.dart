import 'package:flutter/material.dart';

import '../../design_system/background.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';
import 'appointment_data.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Appointments'),
      ),
      body: DSBackground(
        imagePath: 'assets/images/bg4.png',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your calendar',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        CalendarDatePicker(
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          onDateChanged: (date) {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                Text(
                  'Upcoming appointments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                if (upcoming.isEmpty)
                  DS.emptyState(
                    icon: Icons.event_busy,
                    title: 'No upcoming appointments',
                    message: 'Schedule your next visit to keep your care plan on track.',
                    action: DS.secondary(
                      'Add appointment',
                      icon: Icons.add,
                      onPressed: () {
                        // TODO: handle appointment creation
                      },
                      fullWidth: false,
                    ),
                  )
                else
                  ListView.separated(
                    itemCount: upcoming.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacingM),
                    itemBuilder: (context, index) {
                      final appointment = upcoming[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    color: Theme.of(context).colorScheme.primary,
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
                                              .titleMedium
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_formatDate(appointment.dateTime)} · ${_formatTime(appointment.dateTime)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
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
                              const SizedBox(height: AppTheme.spacingM),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 18),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Expanded(
                                    child: Text(
                                      appointment.provider,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 18),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Expanded(
                                    child: Text(
                                      appointment.location,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthNames[date.month]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

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
