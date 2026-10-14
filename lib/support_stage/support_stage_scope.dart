import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/database_service.dart';

/// Provides live [UserProfile] to tab roots (home, learn, community).
class SupportStageScope extends InheritedWidget {
  const SupportStageScope({
    super.key,
    required this.profile,
    required super.child,
  });

  final UserProfile? profile;

  static SupportStageScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SupportStageScope>();
  }

  static UserProfile? profileOf(BuildContext context) {
    return maybeOf(context)?.profile;
  }

  @override
  bool updateShouldNotify(SupportStageScope oldWidget) {
    return oldWidget.profile?.currentSupportStage !=
            profile?.currentSupportStage ||
        oldWidget.profile?.hidePregnancyMilestones !=
            profile?.hidePregnancyMilestones ||
        oldWidget.profile?.emotionalSupportPregnancyLoss !=
            profile?.emotionalSupportPregnancyLoss ||
        oldWidget.profile?.pregnancyLossSupportPreferences !=
            profile?.pregnancyLossSupportPreferences;
  }
}

/// Wraps main navigation with a profile stream.
class SupportStageScopeHost extends StatefulWidget {
  const SupportStageScopeHost({super.key, required this.child});

  final Widget child;

  @override
  State<SupportStageScopeHost> createState() => _SupportStageScopeHostState();
}

class _SupportStageScopeHostState extends State<SupportStageScopeHost> {
  final DatabaseService _db = DatabaseService();
  UserProfile? _profile;
  StreamSubscription<UserProfile?>? _sub;

  @override
  void initState() {
    super.initState();
    _listen();
    _loadInitialProfile();
  }

  Future<void> _loadInitialProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final p = await _db.getUserProfile(uid);
    if (mounted) setState(() => _profile = p);
  }

  void _listen() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _sub?.cancel();
    _sub = _db.streamUserProfile(uid).listen((p) {
      if (mounted) setState(() => _profile = p);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SupportStageScope(
      profile: _profile,
      child: widget.child,
    );
  }
}
