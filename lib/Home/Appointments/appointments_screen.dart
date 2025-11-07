import 'package:flutter/material.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/family.jpeg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.2)),
          Center(
            child: Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('No upcoming appointments', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text('Schedule or view details from here.'),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

