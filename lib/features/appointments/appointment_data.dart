class Appointment {
  final DateTime dateTime;
  final String title;
  final String provider;
  final String location;

  const Appointment({
    required this.dateTime,
    required this.title,
    required this.provider,
    required this.location,
  });
}

const List<Appointment> sampleAppointments = [
  Appointment(
    dateTime: DateTime(2025, 1, 12, 10, 0),
    title: 'Prenatal Check-up',
    provider: 'Dr. Amina Patel',
    location: 'Downtown Women\'s Clinic',
  ),
  Appointment(
    dateTime: DateTime(2025, 1, 19, 14, 30),
    title: 'Nutrition Consultation',
    provider: 'Lina Gomez, RD',
    location: 'Empower Health Center',
  ),
  Appointment(
    dateTime: DateTime(2025, 1, 26, 9, 30),
    title: 'Ultrasound Session',
    provider: 'Dr. Marcus Lee',
    location: 'Radiance Imaging Labs',
  ),
];
