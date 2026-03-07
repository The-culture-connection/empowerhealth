import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Home/home_screen_v2.dart';
import '../Journal/Journal_screen.dart';
import '../Community/community_screen.dart';
import '../assistant/assistant_screen.dart';
import '../editprofile/edit_profile_screen.dart';
import '../Home/Learning Modules/learning_modules_screen_v2.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import 'ui_theme.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  int _index = 0;

  final _pages = const [
    HomeScreenV2(),
    LearningModulesScreenV2(), // Learn tab
    JournalScreen(),
    CommunityScreen(),
    EditProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _trackScreenViewAfterAuth();
  }

  /// Wait for auth to be ready before tracking screen view
  Future<void> _trackScreenViewAfterAuth() async {
    try {
      // Wait for auth to be fully restored
      final user = await _analytics.waitForInitialAuthResolution();
      
      if (user == null) {
        debugPrint('⚠️ Analytics: No authenticated user - screen view tracking skipped');
        return;
      }
      
      final userProfile = await _databaseService.getUserProfile(user.uid);
      await _analytics.logScreenView(
        screenName: 'main_navigation',
        userProfile: userProfile,
      );
    } catch (e) {
      debugPrint('⚠️ Analytics: Failed to track screen view: $e');
      // Best-effort: don't block navigation
    }
  }

  void _onTabChanged(int newIndex) {
    setState(() => _index = newIndex);
    // Track tab change asynchronously - don't block UI
    _trackTabView(newIndex);
  }

  Future<void> _trackTabView(int tabIndex) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Event will be queued by analytics service
        final screenNames = ['home', 'learn', 'journal', 'community', 'profile'];
        if (tabIndex < screenNames.length) {
          await _analytics.logScreenView(
            screenName: screenNames[tabIndex],
            userProfile: null,
          );
        }
        return;
      }
      
      final userProfile = await _databaseService.getUserProfile(user.uid);
      final screenNames = ['home', 'learn', 'journal', 'community', 'profile'];
      if (tabIndex < screenNames.length) {
        await _analytics.logScreenView(
          screenName: screenNames[tabIndex],
          userProfile: userProfile,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Analytics: Failed to track tab view: $e');
      // Best-effort: don't block navigation
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPurple.withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 1),
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
                  onTap: () => _onTabChanged(0),
                ),
                _NavItem(
                  icon: Icons.book_outlined,
                  label: 'Learn',
                  isSelected: _index == 1,
                  onTap: () => _onTabChanged(1),
                ),
                _NavItem(
                  icon: Icons.favorite_outline,
                  label: 'Journal',
                  isSelected: _index == 2,
                  onTap: () => _onTabChanged(2),
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  label: 'Community',
                  isSelected: _index == 3,
                  onTap: () => _onTabChanged(3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isSelected: _index == 4,
                  onTap: () => _onTabChanged(4),
                ),
              ],
            ),
          ),
        ),
      ),
      // Floating AI Assistant Button (matching NewUI)
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.gradientPurpleStart, AppTheme.gradientPurpleEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPurple.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              Navigator.pushNamed(context, '/assistant');
            },
            child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
          ),
        ),
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
              color: isSelected ? AppTheme.brandPurple : AppTheme.textLightest,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.brandPurple : AppTheme.textLightest,
                fontWeight: FontWeight.w300, // Lighter weight matching NewUI
              ),
            ),
          ],
        ),
      ),
    );
  }
}
