import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Community/community_screen.dart';
import '../Journal/Journal_screen.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../editprofile/edit_profile_screen.dart';
import '../models/user_profile.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../support_stage/support_stage.dart';
import '../widgets/ambient_background.dart';
import 'pregnancy_loss_home_screen.dart';
import 'pregnancy_loss_learning_screen.dart';

/// Bottom navigation for pregnancy-loss mode only (no standard pregnancy UI).
class PregnancyLossNavigationScaffold extends StatefulWidget {
  const PregnancyLossNavigationScaffold({super.key});

  @override
  State<PregnancyLossNavigationScaffold> createState() =>
      _PregnancyLossNavigationScaffoldState();
}

class _PregnancyLossNavigationScaffoldState
    extends State<PregnancyLossNavigationScaffold> {
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  int _index = 0;
  DateTime _tabEnteredAt = DateTime.now();
  DateTime? _featureSessionStartedAt;

  static final List<Widget> _pages = [
    PregnancyLossHomeScreen(key: ValueKey('loss_tab_home')),
    PregnancyLossLearningScreen(key: ValueKey('loss_tab_learn')),
    JournalScreen(key: ValueKey('loss_tab_journal')),
    CommunityScreen(
      key: ValueKey('loss_tab_community'),
      communityStageFilter: CommunityStage.pregnancyLoss,
    ),
    EditProfileScreen(key: ValueKey('loss_tab_profile')),
  ];

  @override
  void initState() {
    super.initState();
    _trackScreenViewAfterAuth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_startFeatureSessionForTab(_index));
      }
    });
  }

  Future<void> _trackScreenViewAfterAuth() async {
    try {
      final user = await _analytics.waitForInitialAuthResolution();
      if (user == null) return;

      final userProfile = await _databaseService.getUserProfile(user.uid);
      await _analytics.logScreenView(
        screenName: 'pregnancy_loss_main_navigation',
        userProfile: userProfile,
      );
    } catch (e) {
      debugPrint('⚠️ Analytics: Failed to track pregnancy loss shell: $e');
    }
  }

  void _onTabChanged(int newIndex) {
    _trackTabTimeSpent(_index);
    unawaited(_endFeatureSessionForTab(_index));
    setState(() => _index = newIndex);
    _tabEnteredAt = DateTime.now();
    unawaited(_startFeatureSessionForTab(newIndex));
    _trackTabView(newIndex);
  }

  @override
  void dispose() {
    unawaited(_endFeatureSessionForTab(_index));
    _trackTabTimeSpent(_index);
    super.dispose();
  }

  Future<void> _startFeatureSessionForTab(int tabIndex) async {
    _featureSessionStartedAt = DateTime.now();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      UserProfile? profile;
      try {
        profile = await _databaseService.getUserProfile(user.uid);
      } catch (_) {
        profile = null;
      }
      await _analytics.logFeatureSessionStarted(
        feature: _featureForTab(tabIndex),
        entrySource: 'pregnancy_loss_tab',
        userProfile: profile,
      );
    } catch (e) {
      debugPrint('⚠️ Analytics: pregnancy loss feature session start: $e');
    }
  }

  Future<void> _endFeatureSessionForTab(int tabIndex) async {
    final started = _featureSessionStartedAt;
    if (started == null) return;
    final seconds = DateTime.now().difference(started).inSeconds;
    if (seconds <= 0) {
      _featureSessionStartedAt = null;
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      UserProfile? profile;
      if (user != null) {
        try {
          profile = await _databaseService.getUserProfile(user.uid);
        } catch (_) {
          profile = null;
        }
      }
      await _analytics.logFeatureSessionEnded(
        feature: _featureForTab(tabIndex),
        durationSeconds: seconds,
        entrySource: 'pregnancy_loss_tab',
        userProfile: profile,
      );
    } catch (e) {
      debugPrint('⚠️ Analytics: pregnancy loss feature session end: $e');
    }
    _featureSessionStartedAt = null;
  }

  Future<void> _trackTabView(int tabIndex) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final screenNames = [
        'pregnancy_loss_home',
        'pregnancy_loss_learn',
        'journal',
        'pregnancy_loss_community',
        'profile',
      ];
      if (tabIndex >= screenNames.length) return;

      UserProfile? userProfile;
      if (user != null) {
        userProfile = await _databaseService.getUserProfile(user.uid);
      }
      await _analytics.logScreenView(
        screenName: screenNames[tabIndex],
        userProfile: userProfile,
      );
    } catch (e) {
      debugPrint('⚠️ Analytics: pregnancy loss tab view: $e');
    }
  }

  String _featureForTab(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return 'pregnancy-loss-learning';
      case 2:
        return 'journal';
      case 3:
        return 'pregnancy-loss-community';
      case 4:
        return 'profile-editing';
      default:
        return 'pregnancy-loss';
    }
  }

  Future<void> _trackTabTimeSpent(int tabIndex) async {
    try {
      final seconds = DateTime.now().difference(_tabEnteredAt).inSeconds;
      if (seconds <= 0) return;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final screenNames = [
        'pregnancy_loss_home',
        'pregnancy_loss_learn',
        'journal',
        'pregnancy_loss_community',
        'profile',
      ];
      final screenName = tabIndex < screenNames.length
          ? screenNames[tabIndex]
          : 'unknown';
      final feature = _featureForTab(tabIndex);

      if (userId != null) {
        final userProfile = await _databaseService.getUserProfile(userId);
        await _analytics.logScreenTimeSpent(
          screenName: screenName,
          feature: feature,
          timeSpentSeconds: seconds,
          userProfile: userProfile,
        );
        await _analytics.logFeatureTimeSpent(
          feature: feature,
          sourceId: screenName,
          timeSpentSeconds: seconds,
          userProfile: userProfile,
        );
      } else {
        await _analytics.logScreenTimeSpent(
          screenName: screenName,
          feature: feature,
          timeSpentSeconds: seconds,
          userProfile: null,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Analytics: pregnancy loss tab time: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainNavigationScope(
      selectTab: _onTabChanged,
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppTheme.backgroundWarm,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AmbientBackground(showRadialWashes: _index != 1),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 672,
                        minHeight: constraints.maxHeight,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: IndexedStack(
                        index: _index,
                        sizing: StackFit.expand,
                        children: _pages,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Material(
          color: AppTheme.navBarBgLight,
          elevation: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.navBarBorderLight)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LossNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: _index == 0,
                      onTap: () => _onTabChanged(0),
                    ),
                    _LossNavItem(
                      icon: Icons.menu_book_outlined,
                      activeIcon: Icons.menu_book_rounded,
                      label: 'Learn',
                      isSelected: _index == 1,
                      onTap: () => _onTabChanged(1),
                    ),
                    _LossNavItem(
                      icon: Icons.favorite_outline_rounded,
                      activeIcon: Icons.favorite_rounded,
                      label: 'Journal',
                      isSelected: _index == 2,
                      onTap: () => _onTabChanged(2),
                    ),
                    _LossNavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Community',
                      isSelected: _index == 3,
                      onTap: () => _onTabChanged(3),
                    ),
                    _LossNavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'You',
                      isSelected: _index == 4,
                      onTap: () => _onTabChanged(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LossNavItem extends StatelessWidget {
  const _LossNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = AppTheme.brandPurple;
    final inactive = AppTheme.navInactiveLight;
    final color = isSelected ? active : inactive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1,
              duration: const Duration(milliseconds: 220),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.4,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
