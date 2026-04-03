import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppTheme.newUiAppBar(context, title: 'Appointment Details'),
      body: const Center(child: Text('Details coming soon.')),
    );
  }
}

