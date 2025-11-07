import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import 'home_tab.dart';
import 'learning_tab.dart';
import 'recorder_tab.dart';
import 'forums_tab.dart';
import 'messaging_tab.dart';

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key});

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  int _index = 0;

  final _tabs = const [
    HomeTab(),
    LearningTab(),
    RecorderTab(),
    ForumsTab(),
    MessagingTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _tabs[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppTheme.lightPrimary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.lightPrimary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: AppTheme.lightPrimary),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none),
            selectedIcon: Icon(Icons.mic, color: AppTheme.lightPrimary),
            label: 'Record',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum, color: AppTheme.lightPrimary),
            label: 'Forums',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message, color: AppTheme.lightPrimary),
            label: 'Messages',
          ),
        ],
      ),
    );
  }
}
