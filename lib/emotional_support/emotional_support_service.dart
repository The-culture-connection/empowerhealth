import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';

const String _kPrefsKey = 'emotional_support_last_selections';

/// Persists check-in selections and logs analytics (`feature: emotional-support`).
class EmotionalSupportService {
  EmotionalSupportService._();
  static final EmotionalSupportService instance = EmotionalSupportService._();

  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _db = DatabaseService();

  Future<void> logOpened({UserProfile? profile}) async {
    await _analytics.logEvent(
      eventName: 'support_checkin_opened',
      feature: 'emotional-support',
      userProfile: profile,
    );
  }

  Future<void> logCompleted({
    required List<String> optionIds,
    UserProfile? profile,
  }) async {
    await _analytics.logEvent(
      eventName: 'support_checkin_completed',
      feature: 'emotional-support',
      parameters: {'options': optionIds, 'option_count': optionIds.length},
      userProfile: profile,
    );
  }

  Future<void> logOptionSelected({
    required String optionId,
    UserProfile? profile,
  }) async {
    await _analytics.logEvent(
      eventName: 'support_option_selected',
      feature: 'emotional-support',
      parameters: {'option_id': optionId},
      userProfile: profile,
    );
  }

  Future<void> logResourceOpened({
    required String resourceId,
    required String pathwayId,
    UserProfile? profile,
  }) async {
    await _analytics.logEvent(
      eventName: 'support_resource_opened',
      feature: 'emotional-support',
      parameters: {'resource_id': resourceId, 'pathway_id': pathwayId},
      userProfile: profile,
    );
  }

  Future<void> logCrisisResourceOpened({
    required String action,
    UserProfile? profile,
  }) async {
    await _analytics.logEvent(
      eventName: 'crisis_resource_opened',
      feature: 'emotional-support',
      parameters: {'action': action},
      userProfile: profile,
    );
  }

  Future<void> logPpdSupportOpened({UserProfile? profile}) async {
    await _analytics.logEvent(
      eventName: 'ppd_support_opened',
      feature: 'emotional-support',
      userProfile: profile,
    );
  }

  Future<void> logPregnancyLossFlowStarted({UserProfile? profile}) async {
    await _analytics.logEvent(
      eventName: 'pregnancy_loss_flow_started',
      feature: 'emotional-support',
      userProfile: profile,
    );
  }

  Future<void> saveCheckIn({
    required List<String> selectedOptionIds,
    String? somethingElseText,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final payload = <String, dynamic>{
      'selectedOptions': selectedOptionIds,
      'somethingElseText': somethingElseText?.trim() ?? '',
      'completedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _db.updateUserProfile(uid, {
        'emotionalSupportCheckIn': payload,
        'emotionalSupportLastCheckInAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ emotionalSupport save profile: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kPrefsKey,
        jsonEncode({
          'selectedOptions': selectedOptionIds,
          'somethingElseText': somethingElseText?.trim() ?? '',
          'savedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('⚠️ emotionalSupport prefs: $e');
    }
  }

  @Deprecated('Use PregnancyLossService.enterPregnancyLossMode')
  Future<void> acknowledgePregnancyLoss() async {
    // Legacy callers — full stage is set in pregnancy loss flow.
  }
}
