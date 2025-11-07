import 'package:flutter/material.dart';

import '../appointments/appointments_screen.dart';
import '../community/community_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../feedback/feedback_screen.dart';
import '../transcription/transcription_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(
        onViewAppointments: () => _onDestinationSelected(1),
        onOpenTranscription: () => _onDestinationSelected(2),
        onOpenCommunity: () => _onDestinationSelected(3),
        onOpenFeedback: () => _onDestinationSelected(4),
      ),
      const AppointmentsScreen(),
      const TranscriptionScreen(),
      const CommunityScreen(),
      const FeedbackScreen(),
    ];
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        elevation: 4,
        selectedIndex: _selectedIndex,
        animationDuration: const Duration(milliseconds: 300),
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none),
            selectedIcon: Icon(Icons.mic),
            label: 'Transcription',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.feedback_outlined),
            selectedIcon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
        ],
      ),
    );
  }
}
