import 'package:flutter/material.dart';

import '../Home/home_screen_v2.dart';
import '../Journal/Journal_screen.dart';
import '../Community/community_screen.dart';
import '../assistant/assistant_screen.dart';
import '../editprofile/edit_profile_screen.dart';
import '../Home/Learning Modules/learning_modules_screen_v2.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _index = 0;

  final _pages = const [
    HomeScreenV2(),
    LearningModulesScreenV2(), // Learn tab
    JournalScreen(),
    CommunityScreen(),
    EditProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.book_outlined,
                  label: 'Learn',
                  isSelected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icon: Icons.favorite_outline,
                  label: 'Journal',
                  isSelected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  label: 'Community',
                  isSelected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isSelected: _index == 4,
                  onTap: () => setState(() => _index = 4),
                ),
              ],
            ),
          ),
        ),
      ),
      // Floating AI Assistant Button (matching NewUI)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/assistant');
        },
        backgroundColor: const Color(0xFF663399),
        child: const Icon(Icons.support_agent, color: Colors.white),
        heroTag: 'assistant',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF663399) : Colors.grey.shade500,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF663399) : Colors.grey.shade500,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
