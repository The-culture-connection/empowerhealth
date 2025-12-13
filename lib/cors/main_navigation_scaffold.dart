import 'package:flutter/material.dart';

import '../Home/home_screen_v2.dart';
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
    HomeScreenV2(),
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 8,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: '', tooltip: 'Home'),
          NavigationDestination(icon: Icon(Icons.edit_note_rounded), label: '', tooltip: 'Journal'),
          NavigationDestination(icon: Icon(Icons.people_rounded), label: '', tooltip: 'Community'),
          NavigationDestination(icon: Icon(Icons.support_agent_rounded), label: '', tooltip: 'Assistant'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: '', tooltip: 'Profile'),
        ],
      ),
    );
  }
}
