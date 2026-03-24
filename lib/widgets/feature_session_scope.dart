import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';

/// Wraps a feature surface so we emit [feature_session_started] / [feature_session_ended].
///
/// Nested scopes for the **same** [feature] share one logical session via ref-counting
/// (first mount starts, last unmount ends with total dwell time).
class FeatureSessionScope extends StatefulWidget {
  const FeatureSessionScope({
    super.key,
    required this.feature,
    required this.child,
    this.entrySource,
  });

  final String feature;
  final String? entrySource;
  final Widget child;

  static final Map<String, int> _depth = {};
  static final Map<String, DateTime> _startedAt = {};

  @override
  State<FeatureSessionScope> createState() => _FeatureSessionScopeState();
}

class _FeatureSessionScopeState extends State<FeatureSessionScope> {
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    final f = widget.feature;
    final next = (FeatureSessionScope._depth[f] ?? 0) + 1;
    FeatureSessionScope._depth[f] = next;
    if (next == 1) {
      FeatureSessionScope._startedAt[f] = DateTime.now();
      _logStart();
    }
  }

  @override
  void dispose() {
    final f = widget.feature;
    final current = FeatureSessionScope._depth[f] ?? 1;
    final next = current - 1;
    if (next <= 0) {
      FeatureSessionScope._depth.remove(f);
      final started = FeatureSessionScope._startedAt.remove(f);
      _logEnd(started);
    } else {
      FeatureSessionScope._depth[f] = next;
    }
    super.dispose();
  }

  Future<void> _logStart() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      UserProfile? profile;
      if (uid != null) {
        try {
          profile = await _databaseService.getUserProfile(uid);
        } catch (_) {
          profile = null;
        }
      }
      await _analytics.logFeatureSessionStarted(
        feature: widget.feature,
        entrySource: widget.entrySource,
        userProfile: profile,
      );
    } catch (_) {}
  }

  Future<void> _logEnd(DateTime? started) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      UserProfile? profile;
      if (uid != null) {
        try {
          profile = await _databaseService.getUserProfile(uid);
        } catch (_) {
          profile = null;
        }
      }
      final seconds = started != null
          ? DateTime.now().difference(started).inSeconds
          : 0;
      await _analytics.logFeatureSessionEnded(
        feature: widget.feature,
        durationSeconds: seconds < 0 ? 0 : seconds,
        entrySource: widget.entrySource,
        userProfile: profile,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
