import 'package:flutter/material.dart';

import '../Home/home_screen.dart';
import '../Journal/Journal_screen.dart';
import '../Community/community_screen.dart';
import '../assistant/assistant_screen.dart';
import '../editprofile/edit_profile_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    JournalScreen(),
    CommunityScreen(),
    AssistantScreen(),
    EditProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white.withOpacity(0.15),
        elevation: 0,
        indicatorColor: Colors.white.withOpacity(0.25),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.edit_note_rounded), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.people_rounded), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.support_agent_rounded), label: 'Assistant'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
