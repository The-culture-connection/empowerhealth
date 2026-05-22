import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../services/firebase_functions_service.dart';
import '../support_stage/support_stage.dart';
import 'pregnancy_loss_entry_exception.dart';

/// Persists pregnancy-loss support stage and analytics.
class PregnancyLossService {
  PregnancyLossService._();
  static final PregnancyLossService instance = PregnancyLossService._();

  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _db = DatabaseService();
  final FirebaseFunctionsService _functions = FirebaseFunctionsService();

  Future<UserProfile?> _profile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _db.getUserProfile(uid);
  }

  Future<void> _log(
    String eventName, {
    Map<String, Object?> parameters = const {},
    UserProfile? profile,
  }) async {
    try {
      await _analytics.logEvent(
        eventName: eventName,
        feature: 'pregnancy-loss',
        parameters: parameters,
        userProfile: profile ?? await _profile(),
      );
    } catch (e) {
      debugPrint('⚠️ pregnancy-loss analytics $eventName: $e');
    }
  }

  Future<void> logTransitionViewed() async {
    await _log('pregnancy_loss_transition_viewed');
  }

  Future<void> logFlowStarted() async {
    await _log('pregnancy_loss_flow_started');
  }

  Future<void> logSupportPreferencesSaved({
    required List<String> preferenceIds,
    bool skipped = false,
  }) async {
    await _log(
      'pregnancy_loss_support_preferences_saved',
      parameters: {
        'preference_ids': preferenceIds,
        'preference_count': preferenceIds.length,
        'skipped': skipped,
      },
    );
  }

  Future<void> logHomeViewed() async {
    await _log('pregnancy_loss_home_viewed');
  }

  Future<void> logModuleOpened(String moduleId) async {
    await _log(
      'pregnancy_loss_module_opened',
      parameters: {'module_id': moduleId},
    );
  }

  Future<void> logCommunityOpened() async {
    await _log('pregnancy_loss_community_opened');
  }

  Future<void> logResourceOpened(String resourceId) async {
    await _log(
      'pregnancy_loss_resource_opened',
      parameters: {'resource_id': resourceId},
    );
  }

  Future<void> logNavTapped(String destinationId) async {
    await _log(
      'pregnancy_loss_nav_tapped',
      parameters: {'destination_id': destinationId},
    );
  }

  Future<void> log988Tapped(String action) async {
    await _log(
      'pregnancy_loss_988_${action}_tapped',
      parameters: {'action': action},
    );
  }

  Future<void> logSupportStageUpdated(String newStage) async {
    try {
      await _analytics.logEvent(
        eventName: 'support_stage_updated',
        feature: 'pregnancy-loss',
        parameters: {'support_stage': newStage},
        userProfile: await _profile(),
      );
    } catch (e) {
      debugPrint('⚠️ support_stage_updated analytics: $e');
    }
  }

  Map<String, dynamic> _pregnancyLossProfilePayload({
    required List<String> checkInOptionIds,
    String? somethingElseText,
  }) {
    return {
      'currentSupportStage': SupportStage.pregnancyLoss,
      'hidePregnancyMilestones': true,
      'emotionalSupportPregnancyLoss': true,
      'pregnancyLossFlowStartedAt': FieldValue.serverTimestamp(),
      'emotionalSupportPregnancyLossAt': FieldValue.serverTimestamp(),
      'emotionalSupportCheckIn': {
        'selectedOptions': checkInOptionIds,
        'somethingElseText': somethingElseText?.trim() ?? '',
        'completedAt': FieldValue.serverTimestamp(),
      },
      'emotionalSupportLastCheckInAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _persistViaClientMerge({
    required String uid,
    required List<String> checkInOptionIds,
    String? somethingElseText,
  }) async {
    await _db.mergeUserProfile(
      uid,
      _pregnancyLossProfilePayload(
        checkInOptionIds: checkInOptionIds,
        somethingElseText: somethingElseText,
      ),
    );
  }

  bool _callableUnavailable(FirebaseFunctionsException e) {
    return e.code == 'not-found' ||
        e.code == 'unavailable' ||
        e.code == 'unimplemented';
  }

  /// Enters pregnancy-loss mode: Cloud Function first, client merge fallback.
  Future<void> enterPregnancyLossMode({
    List<String> checkInOptionIds = const [],
    String? somethingElseText,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw PregnancyLossEntryException('Please sign in to continue.');
    }

    try {
      final result = await _functions.enterPregnancyLossSupportMode(
        selectedOptions: checkInOptionIds,
        somethingElseText: somethingElseText,
      );
      if (result['success'] != true) {
        throw PregnancyLossEntryException(
          'We could not save your support settings. Please try again.',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('⚠️ enterPregnancyLossSupportMode callable: ${e.code} ${e.message}');
      if (e.code == 'unauthenticated') {
        throw PregnancyLossEntryException(
          e.message ?? 'Please sign in to continue.',
        );
      }
      if (_callableUnavailable(e)) {
        await _persistViaClientMerge(
          uid: user.uid,
          checkInOptionIds: checkInOptionIds,
          somethingElseText: somethingElseText,
        );
      } else {
        throw PregnancyLossEntryException(
          e.message ?? 'We could not save your support settings. Please try again.',
        );
      }
    } on PregnancyLossEntryException {
      rethrow;
    } catch (e) {
      debugPrint('⚠️ enterPregnancyLossMode callable failed, trying client merge: $e');
      try {
        await _persistViaClientMerge(
          uid: user.uid,
          checkInOptionIds: checkInOptionIds,
          somethingElseText: somethingElseText,
        );
      } catch (mergeError) {
        debugPrint('⚠️ enterPregnancyLossMode client merge: $mergeError');
        throw PregnancyLossEntryException(
          'We could not save your support settings. Please try again.',
        );
      }
    }
  }

  Future<void> saveSupportPreferences({
    required List<String> preferenceIds,
    String? somethingElseText,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db.mergeUserProfile(uid, {
      'pregnancyLossSupportPreferences': preferenceIds,
      if (somethingElseText != null && somethingElseText.trim().isNotEmpty)
        'pregnancyLossSomethingElseText': somethingElseText.trim(),
    });
  }

  Future<void> updateSupportStage(String stage) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{
      'currentSupportStage': stage,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (stage == SupportStage.pregnancyLoss) {
      updates['hidePregnancyMilestones'] = true;
      updates['emotionalSupportPregnancyLoss'] = true;
      updates['pregnancyLossFlowStartedAt'] = FieldValue.serverTimestamp();
    } else {
      updates['hidePregnancyMilestones'] = false;
      updates['emotionalSupportPregnancyLoss'] = false;
    }

    if (stage == SupportStage.pregnant) {
      updates['isPregnant'] = true;
      updates['isPostpartum'] = false;
    } else if (stage == SupportStage.postpartum) {
      updates['isPostpartum'] = true;
    }

    try {
      await _db.mergeUserProfile(uid, updates);
      await logSupportStageUpdated(stage);
    } catch (e) {
      debugPrint('⚠️ updateSupportStage: $e');
      rethrow;
    }
  }
}
