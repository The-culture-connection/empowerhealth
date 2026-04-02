import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'realtime_analytics_config.dart';

/// Centralized Firestore writer for realtime analytics (`analytics_events`).
///
/// Used by [AnalyticsService] for mobile-originated events. Documents include
/// `source: mobile` and are aggregated by Cloud Functions (see `docs/realtime-analytics.md`).
class RealtimeAnalyticsService {
  RealtimeAnalyticsService._();
  static final RealtimeAnalyticsService instance = RealtimeAnalyticsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// `local` (debug), `staging`, or `prod`.
  static String resolveEnvironment() {
    if (kDebugMode) return 'local';
    return 'prod';
  }

  static Future<String?> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return null;
    }
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Sanitize [metadata] for Firestore (no nested cycles; primitives + lists/maps of primitives).
  static Map<String, dynamic> sanitizeMetadata(Map<String, dynamic>? input) {
    if (input == null || input.isEmpty) return {};
    final out = <String, dynamic>{};
    for (final e in input.entries) {
      final v = _sanitizeValue(e.value);
      if (v != null) {
        out[_truncateKey(e.key)] = v;
      }
    }
    return out;
  }

  static dynamic _sanitizeValue(dynamic v) {
    if (v == null) return null;
    if (v is String || v is num || v is bool) return v;
    if (v is DateTime) return v.toIso8601String();
    if (v is Map) {
      final m = <String, dynamic>{};
      for (final e in v.entries) {
        if (e.key is! String) continue;
        final sv = _sanitizeValue(e.value);
        if (sv != null) m[_truncateKey(e.key as String)] = sv;
      }
      return m;
    }
    if (v is List) {
      final list = <dynamic>[];
      for (final item in v.take(50)) {
        final sv = _sanitizeValue(item);
        if (sv != null) list.add(sv);
      }
      return list;
    }
    return v.toString();
  }

  static String _truncateKey(String k) =>
      k.length > 80 ? k.substring(0, 80) : k;

  static Map<String, String> timeKeysNow() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final dateKey = '$y-$m-$d';
    return {
      'dateKey': dateKey,
      'hourKey': '$dateKey-$h',
      'monthKey': '$y-$m',
    };
  }

  /// Writes one mobile analytics document to `analytics_events` and mirrors to
  /// `technology_features/{featureId}/analytics_events` when [feature] maps.
  Future<void> writeMobileAnalyticsEvent({
    required String eventName,
    required String feature,
    required String userId,
    required String anonUserId,
    required String sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (userId.isEmpty) return;

      final safeMeta = sanitizeMetadata(metadata);

      final keys = timeKeysNow();
      final clientTs = DateTime.now().toUtc().toIso8601String();
      final screen = safeMeta['screen_name']?.toString();

      final appVersion = await _appVersion();

      final eventData = <String, dynamic>{
        'eventName': eventName,
        'userId': userId,
        'feature': feature,
        'screen': screen,
        'timestamp': FieldValue.serverTimestamp(),
        'clientTimestamp': clientTs,
        'platform': _platformLabel(),
        'appVersion': appVersion,
        'environment': resolveEnvironment(),
        'sessionId': sessionId,
        'metadata': safeMeta,
        'source': kMobileAnalyticsSource,
        'aggregationVersion': kRealtimeAnalyticsAggregationVersion,
        'dateKey': keys['dateKey'],
        'hourKey': keys['hourKey'],
        'monthKey': keys['monthKey'],
        'cohortType': safeMeta['cohort_type'],
        'gestationalWeek': safeMeta['pregnancy_week'],
        'trimester': safeMeta['trimester'],
        'anonUserId': anonUserId,
      };

      await _firestore.collection('analytics_events').add(eventData);

      final technologyFeatureId = _mapFeatureToTechnologyDocId(feature);
      if (technologyFeatureId != null && technologyFeatureId.isNotEmpty) {
        try {
          await _firestore
              .collection('technology_features')
              .doc(technologyFeatureId)
              .collection('analytics_events')
              .add(eventData);
        } catch (e) {
          debugPrint('⚠️ RealtimeAnalytics: subcollection write failed: $e');
        }
      }
    } catch (e, st) {
      debugPrint('⚠️ RealtimeAnalytics: writeMobileAnalyticsEvent failed: $e\n$st');
    }
  }

  String? _mapFeatureToTechnologyDocId(String analyticsFeature) {
    const mapping = {
      'analytics-and-event-tracking': 'analytics-and-event-tracking',
      'appointment-summarizing': 'appointment-summarizing',
      'authentication-onboarding': 'authentication-onboarding',
      'birth-plan-generator': 'birth-plan-generator',
      'community': 'community',
      'journal': 'journal',
      'learning-modules': 'learning-modules',
      'profile-editing': 'profile-editing',
      'provider-search': 'provider-search',
      'user-feedback': 'user-feedback',
      'app': 'app',
    };
    return mapping[analyticsFeature] ?? analyticsFeature;
  }

  /// Convenience wrapper (same as [writeMobileAnalyticsEvent] with merged metadata).
  Future<void> logEvent({
    required String eventName,
    required String userId,
    required String anonUserId,
    required String sessionId,
    String? feature,
    String? screen,
    Map<String, dynamic>? metadata,
  }) {
    final meta = {
      if (metadata != null) ...metadata,
      if (screen != null) 'screen_name': screen,
    };
    return writeMobileAnalyticsEvent(
      eventName: eventName,
      feature: feature ?? 'app',
      userId: userId,
      anonUserId: anonUserId,
      sessionId: sessionId,
      metadata: meta,
    );
  }
}
