import '../models/user_profile.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Session-only immediate support analytics — no Firestore persistence of selections.
class ImmediateSupportService {
  ImmediateSupportService._();
  static final ImmediateSupportService instance = ImmediateSupportService._();

  final AnalyticsService _analytics = AnalyticsService();

  Future<UserProfile?> _profile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return DatabaseService().getUserProfile(uid);
  }

  Future<void> _log(
    String eventName, {
    Map<String, Object?> parameters = const {},
  }) async {
    try {
      await _analytics.logEvent(
        eventName: eventName,
        feature: 'immediate-support',
        parameters: parameters,
        userProfile: await _profile(),
      );
    } catch (e) {
      debugPrint('⚠️ immediate-support analytics $eventName: $e');
    }
  }

  Future<void> logOpened({required String entrySource}) async {
    await _log(
      'immediate_support_opened',
      parameters: {'entry_source': entrySource},
    );
  }

  Future<void> logHubViewed({required int selectionCount}) async {
    await _log(
      'immediate_support_hub_viewed',
      parameters: {'selection_count': selectionCount},
    );
  }

  Future<void> logCompleted({
    required int selectionCount,
    required bool skipped,
  }) async {
    await _log(
      'immediate_support_completed',
      parameters: {
        'selection_count': selectionCount,
        'skipped': skipped,
      },
    );
  }

  Future<void> logResourceOpened(String resourceId) async {
    await _log(
      'immediate_support_resource_opened',
      parameters: {'resource_id': resourceId},
    );
  }

  Future<void> log988Tapped(String action) async {
    await _log(
      'immediate_support_988_${action}_tapped',
      parameters: {'action': action},
    );
  }
}
