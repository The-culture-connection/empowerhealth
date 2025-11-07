import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Sample appointments data
  final Map<DateTime, List<String>> _appointments = {
    DateTime.now(): ['Dr. Smith - General Checkup', 'Physical Therapy'],
    DateTime.now().add(const Duration(days: 3)): ['Dr. Johnson - Follow-up'],
    DateTime.now().add(const Duration(days: 7)): ['Dentist Appointment'],
  };

  List<String> _getAppointmentsForDay(DateTime day) {
    return _appointments[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fixed background image
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
                        'Appointments',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          // Add new appointment
                        },
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
                        // Calendar Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            child: TableCalendar(
                              firstDay: DateTime.now().subtract(const Duration(days: 365)),
                              lastDay: DateTime.now().add(const Duration(days: 365)),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: AppTheme.lightAccent,
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: const BoxDecoration(
                                  color: AppTheme.lightPrimary,
                                  shape: BoxShape.circle,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: AppTheme.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              eventLoader: _getAppointmentsForDay,
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        DS.gapL,
                        
                        // Upcoming Appointments Section
                        const Text(
                          'Upcoming Appointments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        DS.gapM,
                        
                        // Appointments List
                        ...(_selectedDay != null
                            ? _getAppointmentsForDay(_selectedDay!)
                            : _getAppointmentsForDay(DateTime.now()))
                            .map((appointment) => Card(
                                  margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightPrimary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today,
                                        color: AppTheme.lightPrimary,
                                      ),
                                    ),
                                    title: Text(
                                      appointment,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _selectedDay != null
                                          ? '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                                          : '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {},
                                    ),
                                  ),
                                ))
                            .toList(),
                        
                        // If no appointments
                        if ((_selectedDay != null
                                ? _getAppointmentsForDay(_selectedDay!)
                                : _getAppointmentsForDay(DateTime.now()))
                            .isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingXL),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_available,
                                      size: 48,
                                      color: AppTheme.lightForeground.withOpacity(0.3),
                                    ),
                                    DS.gapM,
                                    Text(
                                      'No appointments scheduled',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.lightForeground.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
