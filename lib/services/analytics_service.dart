/**
 * Analytics Service
 * Handles all analytics event tracking with user lifecycle context
 */

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../models/user_profile.dart';
import '../models/analytics_event.dart';
import '../models/micro_measure.dart';
import '../models/helpfulness_survey.dart';
import '../models/milestone_checkin.dart';
import '../models/care_navigation_outcome.dart';
import '../utils/pregnancy_utils.dart';
import 'analytics/realtime_analytics_service.dart';

/// Queued analytics event
class _QueuedEvent {
  final String eventName;
  final String feature;
  final Map<String, dynamic>? parameters;
  final int? durationMs;
  final UserProfile? userProfile;
  final DateTime queuedAt;
  int retryCount;

  _QueuedEvent({
    required this.eventName,
    required this.feature,
    this.parameters,
    this.durationMs,
    this.userProfile,
  }) : queuedAt = DateTime.now(),
       retryCount = 0;
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;

  // Use us-central1 region explicitly to match deployed functions
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // Firebase Analytics instance for standard analytics dashboard
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Firestore instance for direct analytics writes
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _sessionId;
  DateTime? _sessionStartTime;
  String? _sessionEntryPoint;

  // Cached user context for performance
  Map<String, dynamic>? _cachedUserContext;
  DateTime? _contextCacheTime;

  // Event queue for when auth is not ready
  final List<_QueuedEvent> _eventQueue = [];
  bool _isFlushingQueue = false;
  bool _authReady = false;

  // TODO: App Check is currently failing for iOS app
  // Error: "App not registered: 1:725364003316:ios:f627cbea909c143e8229a1"
  // This is separate from auth race condition and should not block analytics queueing
  // To fix: Register iOS app in Firebase Console → App Check → Manage apps

  AnalyticsService._internal() {
    // Listen for auth state changes to flush queued events
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && !_authReady) {
        _authReady = true;
        _flushEventQueue();
      } else if (user == null) {
        _authReady = false;
      }
    });
  }

  /// Wait for initial auth resolution
  /// Returns the authenticated user once auth state is resolved, or null if not authenticated
  Future<User?> waitForInitialAuthResolution() async {
    // First check if user is already available with valid token
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Verify token is ready
        await currentUser.getIdToken();
        _authReady = true;
        return currentUser;
      } catch (e) {
        // Token not ready yet, wait for auth state change
        print('📊 Analytics: Token not ready, waiting for auth state...');
      }
    }

    // Wait for auth state to resolve (first event from stream)
    try {
      final resolvedUser = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 5));

      if (resolvedUser != null) {
        try {
          // Verify token is ready
          await resolvedUser.getIdToken();
          _authReady = true;
          print('✅ Analytics: Auth resolved, token ready');
        } catch (e) {
          // Token still not ready, but user exists - mark as ready anyway
          // The function will handle token refresh
          _authReady = true;
          print('⚠️ Analytics: Auth resolved but token not ready yet: $e');
        }
      } else {
        print('📊 Analytics: Auth resolved - no authenticated user');
      }

      return resolvedUser;
    } catch (e) {
      // Timeout or error - return current user or null
      print('⚠️ Analytics: Auth resolution timeout/error: $e');
      final fallbackUser = FirebaseAuth.instance.currentUser;
      if (fallbackUser != null) {
        _authReady = true;
      }
      return fallbackUser;
    }
  }

  /// Flush queued events when auth becomes available
  Future<void> _flushEventQueue() async {
    if (_isFlushingQueue || _eventQueue.isEmpty) return;
    _isFlushingQueue = true;

    print('📊 Analytics: Flushing ${_eventQueue.length} queued events');

    final eventsToFlush = List<_QueuedEvent>.from(_eventQueue);
    _eventQueue.clear();

    for (final event in eventsToFlush) {
      try {
        await _sendEvent(
          eventName: event.eventName,
          feature: event.feature,
          parameters: event.parameters,
          durationMs: event.durationMs,
          userProfile: event.userProfile,
          status: 'sent (queued)',
        );
      } catch (e) {
        // If still failing, re-queue with retry limit
        if (event.retryCount < 3) {
          event.retryCount++;
          _eventQueue.add(event);
          print(
            '📊 Analytics: [retrying] Re-queued event "${event.eventName}" (retry ${event.retryCount}/3)',
          );
        } else {
          print(
            '📊 Analytics: [dropped] Event "${event.eventName}" after 3 retries',
          );
        }
      }
    }

    _isFlushingQueue = false;

    // If there are still events in queue (retries), try again after delay
    if (_eventQueue.isNotEmpty) {
      Future.delayed(const Duration(seconds: 2), () => _flushEventQueue());
    }
  }

  /// Get or create session ID (persists for browser/app session)
  String getSessionId() {
    if (_sessionId == null) {
      _sessionId =
          'session_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString()}';
    }
    return _sessionId!;
  }

  String _generateRandomString() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      9,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }

  /// Generate stable anonymized user ID from UID
  /// Uses SHA-256 hash with salt for consistent anonymization
  Future<String> getAnonUserId(String uid) async {
    try {
      // Check if user already has anonUserId stored
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data()?['anonUserId'] != null) {
        return userDoc.data()!['anonUserId'] as String;
      }

      // Generate new anonUserId using SHA-256 hash
      // Use a consistent salt (in production, this should be from environment/config)
      const salt = 'empower-health-analytics-salt-2024';
      final bytes = utf8.encode('$uid$salt');
      final digest = sha256.convert(bytes);
      final anonId = digest.toString().substring(0, 16); // Use first 16 chars

      // Store it in user document for future use
      try {
        await _firestore.collection('users').doc(uid).set({
          'anonUserId': anonId,
        }, SetOptions(merge: true));
      } catch (e) {
        // Best effort - if write fails, still return the anonId
        print('⚠️ Analytics: Failed to store anonUserId: $e');
      }

      return anonId;
    } catch (e) {
      // Fallback: generate a simple hash
      print('⚠️ Analytics: Error generating anonUserId: $e');
      final simpleHash = uid.hashCode.abs().toRadixString(36).substring(0, 16);
      return simpleHash;
    }
  }

  /// Get user lifecycle context from user profile
  Future<Map<String, dynamic>> getUserLifecycleContext(
    UserProfile? userProfile,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ Analytics: No authenticated user - returning empty context');
      return {
        'session_id': getSessionId(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    final context = <String, dynamic>{
      'user_id': user.uid,
      'session_id': getSessionId(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (userProfile != null) {
      // Calculate pregnancy week from due date
      int? pregnancyWeek;
      String? trimester;

      if (userProfile.dueDate != null && userProfile.isPregnant) {
        final now = DateTime.now();
        final dueDate = userProfile.dueDate!;
        final difference = dueDate.difference(now).inDays;
        pregnancyWeek = ((280 - difference) / 7).ceil();
        if (pregnancyWeek < 0) pregnancyWeek = 0;
        if (pregnancyWeek > 40) pregnancyWeek = 40;

        trimester = PregnancyUtils.calculateTrimester(userProfile.dueDate);
      } else if (userProfile.pregnancyStage != null) {
        // Try to extract trimester from pregnancyStage string
        final stage = userProfile.pregnancyStage!.toLowerCase();
        if (stage.contains('first')) {
          trimester = 'First Trimester';
        } else if (stage.contains('second')) {
          trimester = 'Second Trimester';
        } else if (stage.contains('third')) {
          trimester = 'Third Trimester';
        } else {
          trimester = userProfile.pregnancyStage;
        }
      }

      context['pregnancy_week'] = pregnancyWeek;
      context['trimester'] = trimester;

      // Optional fields - derive from profile or set defaults
      context['cohort_type'] = userProfile.hasPrimaryProvider
          ? 'navigator'
          : 'self_directed';
      context['navigator'] = userProfile.hasPrimaryProvider;
      context['self_directed'] = !userProfile.hasPrimaryProvider;

      // Postpartum phase
      if (userProfile.isPostpartum && userProfile.childAgeMonths != null) {
        if (userProfile.childAgeMonths! < 3) {
          context['postpartum_phase'] = 'early';
        } else if (userProfile.childAgeMonths! < 6) {
          context['postpartum_phase'] = 'mid';
        } else {
          context['postpartum_phase'] = 'late';
        }
      }

      // Provider selected (if they have a primary provider)
      context['provider_selected'] = userProfile.hasPrimaryProvider;
    }

    return context;
  }

  /// Log an analytics event with user lifecycle context
  /// Events are queued if auth is not ready, then sent when auth becomes available
  Future<void> logEvent({
    required String eventName,
    required String feature,
    Map<String, dynamic>? parameters,
    int? durationMs,
    UserProfile? userProfile,
  }) async {
    try {
      // Check if user is authenticated and auth is ready
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || !_authReady) {
        // Queue event for later when auth is ready
        _eventQueue.add(
          _QueuedEvent(
            eventName: eventName,
            feature: feature,
            parameters: parameters,
            durationMs: durationMs,
            userProfile: userProfile,
          ),
        );
        print(
          '📊 Analytics: Queued event "$eventName" (auth not ready, ${_eventQueue.length} in queue)',
        );
        return;
      }

      // Auth is ready, send immediately
      await _sendEvent(
        eventName: eventName,
        feature: feature,
        parameters: parameters,
        durationMs: durationMs,
        userProfile: userProfile,
        status: 'sent',
      );
    } catch (e) {
      // Best-effort: never crash the app
      print('⚠️ Analytics: Error queuing event "$eventName": $e');
    }
  }

  /// Internal method to actually send an event to Cloud Function
  Future<void> _sendEvent({
    required String eventName,
    required String feature,
    Map<String, dynamic>? parameters,
    int? durationMs,
    UserProfile? userProfile,
    required String status, // 'sent', 'sent (queued)', 'retrying'
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print(
        '📊 Analytics: [$status] Event "$eventName" for feature "$feature"',
      );
      print('📊 Analytics: User ID: ${user.uid}');

      // Force refresh auth token to ensure it's valid
      String? token;
      try {
        token = await user.getIdToken(true); // Force refresh
        if (token == null) {
          throw Exception('No token available');
        }
      } catch (e) {
        print('❌ Analytics: Token refresh failed: $e');
        throw Exception('Token refresh failed: $e');
      }

      // Get user lifecycle context
      final lifecycleContext = await getUserLifecycleContext(userProfile);

      // Merge parameters with lifecycle context
      final metadata = {...lifecycleContext, ...(parameters ?? {})};

      // Call Cloud Function
      final callable = _functions.httpsCallable(
        'logAnalyticsEvent',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call({
        'eventName': eventName,
        'feature': feature,
        'metadata': metadata,
        'durationMs': durationMs,
        'sessionId': getSessionId(),
      });

      // Log the full result for debugging
      print(
        '📊 Analytics: [$status] Function call result for "$eventName": ${result.data}',
      );

      // Check if result indicates success
      // Cloud Function returns { success: true } or the event data
      if (result.data != null) {
        final resultData = result.data as Map<String, dynamic>?;
        if (resultData != null && resultData['success'] == false) {
          print(
            '⚠️ Analytics: [$status] Event "$eventName" call returned success=false: ${result.data}',
          );
          // Don't throw - this might be a transient issue, but also don't retry App Check errors
          final errorMsg = resultData['error']?.toString().toLowerCase() ?? '';
          if (errorMsg.contains('app check') ||
              errorMsg.contains('appcheck') ||
              errorMsg.contains('app not registered')) {
            print(
              '⚠️ Analytics: App Check error in function response - not retrying',
            );
            return;
          }
          throw Exception('Function returned success=false: ${result.data}');
        } else {
          // Success - result.data exists and success is not false
          print(
            '✅ Analytics: [$status] Event "$eventName" logged successfully to Firestore via Cloud Function',
          );
        }
      } else {
        print(
          '⚠️ Analytics: [$status] Event "$eventName" call returned null result',
        );
        // Null result might be OK for some functions, but log it
        print(
          '✅ Analytics: [$status] Event "$eventName" completed (null result)',
        );
      }

      // Also save directly to Firestore for query-friendly schema - best effort
      try {
        await _saveEventToFirestore(
          eventName: eventName,
          feature: feature,
          metadata: metadata,
          userProfile: userProfile,
        );
        print(
          '✅ Analytics: [$status] Event "$eventName" also saved to Firestore analytics_events',
        );
      } catch (e) {
        // Don't fail if Firestore write fails - Cloud Function already handled it
        print(
          '⚠️ Analytics: Failed to save to Firestore directly (non-critical): $e',
        );
      }

      // Also log to Firebase Analytics (standard dashboard) - best effort, don't block
      try {
        await _logToFirebaseAnalytics(
          eventName: eventName,
          feature: feature,
          parameters: parameters,
          durationMs: durationMs,
          metadata: metadata,
        );
        print(
          '✅ Analytics: [$status] Event "$eventName" also logged to Firebase Analytics',
        );
      } catch (e) {
        // Don't fail if Firebase Analytics logging fails - it's supplementary
        print(
          '⚠️ Analytics: Failed to log to Firebase Analytics (non-critical): $e',
        );
      }
    } catch (e, stackTrace) {
      final errorString = e.toString().toLowerCase();
      final user = FirebaseAuth.instance.currentUser;

      // Log full error details for debugging
      print('❌ Analytics: [$status] Full error for "$eventName": $e');
      print('❌ Analytics: Error type: ${e.runtimeType}');

      // Check if this is a FirebaseFunctionsException and inspect its code
      if (e is FirebaseFunctionsException) {
        print('❌ Analytics: Firebase Functions error code: ${e.code}');
        print('❌ Analytics: Firebase Functions error message: ${e.message}');
        print('❌ Analytics: Firebase Functions error details: ${e.details}');

        // Check for App Check related error codes
        if (e.code == 'failed-precondition' ||
            e.code == 'permission-denied' ||
            (e.code == 'unauthenticated' && user != null)) {
          // If user is authenticated but getting these errors, it's likely App Check
          print(
            '⚠️ Analytics: [$status] Event "$eventName" failed - likely App Check issue (code: ${e.code})',
          );
          print(
            '⚠️ Analytics: User is authenticated but function rejected request',
          );
          print(
            '⚠️ Analytics: This is expected - App Check is disabled. Event will not be retried.',
          );
          print(
            '⚠️ Analytics: To fix: Register iOS app in Firebase Console → App Check',
          );
          return;
        }
      }

      // Check if this is an App Check error (not a real auth issue)
      // App Check failures can manifest as various errors, so check multiple patterns
      final isAppCheckError =
          errorString.contains('app check') ||
          errorString.contains('appcheck') ||
          errorString.contains('app not registered') ||
          errorString.contains('failed_precondition') ||
          errorString.contains('failed-precondition') ||
          errorString.contains('devicecheck');

      // Also check if we're seeing App Check warnings in the logs (heuristic)
      // If the user is authenticated but getting permission errors, it's likely App Check
      if (user != null &&
          errorString.contains('permission') &&
          !errorString.contains('token')) {
        // User is authenticated but getting permission error - likely App Check
        print(
          '⚠️ Analytics: [$status] Event "$eventName" failed - likely App Check issue (user authenticated but permission denied)',
        );
        print(
          '⚠️ Analytics: This is expected - App Check is disabled. Event will not be retried.',
        );
        print(
          '⚠️ Analytics: To fix: Register iOS app in Firebase Console → App Check',
        );
        // Don't retry - App Check won't resolve until fixed
        return;
      }

      if (isAppCheckError) {
        // App Check is failing but this is expected - don't retry
        print(
          '⚠️ Analytics: [$status] Event "$eventName" failed due to App Check (app not registered)',
        );
        print(
          '⚠️ Analytics: This is expected - App Check is disabled. Event will not be retried.',
        );
        print(
          '⚠️ Analytics: To fix: Register iOS app in Firebase Console → App Check',
        );
        // Don't retry App Check errors - they won't resolve until App Check is fixed
        return;
      }

      // If unauthenticated error (but not App Check), queue for retry
      // Only retry if user is actually not authenticated
      if (errorString.contains('unauthenticated')) {
        if (user == null) {
          print(
            '📊 Analytics: Retrying event "$eventName" (user not authenticated)',
          );
          // Re-queue the event
          _eventQueue.add(
            _QueuedEvent(
              eventName: eventName,
              feature: feature,
              parameters: parameters,
              durationMs: durationMs,
              userProfile: userProfile,
            ),
          );
          // Try to flush queue after a delay
          Future.delayed(const Duration(seconds: 2), () => _flushEventQueue());
        } else {
          // User is authenticated but getting unauthenticated error - likely App Check
          print(
            '⚠️ Analytics: [$status] Event "$eventName" failed - user authenticated but getting unauthenticated error (likely App Check)',
          );
          print(
            '⚠️ Analytics: This is expected - App Check is disabled. Event will not be retried.',
          );
          return;
        }
        return;
      }

      // Log other errors but don't crash
      print(
        '❌ Analytics: [$status] Error sending event "$eventName" (feature: "$feature"):',
      );
      print('❌ Error: $e');

      if (errorString.contains('not found') || errorString.contains('404')) {
        print(
          '⚠️ Analytics: Cloud Function "logAnalyticsEvent" not found - may need deployment',
        );
      } else if (errorString.contains('timeout') ||
          errorString.contains('deadline')) {
        print(
          '⚠️ Analytics: Request timeout - Cloud Function may be slow or unavailable',
        );
      } else if (errorString.contains('unavailable') ||
          errorString.contains('unreachable')) {
        print('⚠️ Analytics: Service unavailable - check network connection');
      }

      // Still try to log to Firebase Analytics even if Cloud Function failed
      // They're independent systems, so one can succeed while the other fails
      try {
        final lifecycleContext = await getUserLifecycleContext(userProfile);
        final metadata = {...lifecycleContext, ...(parameters ?? {})};
        await _logToFirebaseAnalytics(
          eventName: eventName,
          feature: feature,
          parameters: parameters,
          durationMs: durationMs,
          metadata: metadata,
        );
        print(
          '✅ Analytics: Event "$eventName" logged to Firebase Analytics despite Cloud Function failure',
        );
      } catch (analyticsError) {
        print(
          '⚠️ Analytics: Also failed to log to Firebase Analytics: $analyticsError',
        );
      }

      // Don't throw - analytics shouldn't break the app
    }
  }

  /// Log event to Firebase Analytics (standard dashboard)
  /// This runs in parallel with the custom Firestore analytics
  Future<void> _logToFirebaseAnalytics({
    required String eventName,
    required String feature,
    Map<String, dynamic>? parameters,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Convert event name to Firebase Analytics format (40 char limit, snake_case)
      // Firebase Analytics event names should be lowercase with underscores
      String analyticsEventName = eventName;
      if (analyticsEventName.length > 40) {
        // Truncate if too long
        analyticsEventName = analyticsEventName.substring(0, 40);
      }

      // Prepare parameters for Firebase Analytics
      // Firebase Analytics parameters must be strings, numbers, or booleans
      // Parameter names must be 40 chars or less
      final Map<String, Object> analyticsParams = {
        'feature': feature.length > 40 ? feature.substring(0, 40) : feature,
      };

      // Add feature-specific parameters (limit to 40 chars for names and values)
      if (parameters != null) {
        for (final entry in parameters.entries) {
          final key = entry.key.length > 40
              ? entry.key.substring(0, 40)
              : entry.key;
          final value = entry.value;

          // Convert value to Firebase Analytics compatible type
          if (value is String) {
            analyticsParams[key] = value.length > 100
                ? value.substring(0, 100)
                : value;
          } else if (value is num || value is bool) {
            analyticsParams[key] = value;
          } else if (value != null) {
            // Convert other types to string
            final strValue = value.toString();
            analyticsParams[key] = strValue.length > 100
                ? strValue.substring(0, 100)
                : strValue;
          }
        }
      }

      // Add duration if provided
      if (durationMs != null) {
        analyticsParams['duration_ms'] = durationMs;
      }

      // Add key lifecycle context from metadata if available
      if (metadata != null) {
        if (metadata['cohort_type'] != null) {
          final cohort = metadata['cohort_type'].toString();
          analyticsParams['cohort_type'] = cohort.length > 100
              ? cohort.substring(0, 100)
              : cohort;
        }
        if (metadata['trimester'] != null) {
          final trimester = metadata['trimester'].toString();
          analyticsParams['trimester'] = trimester.length > 100
              ? trimester.substring(0, 100)
              : trimester;
        }
        if (metadata['pregnancy_week'] != null) {
          analyticsParams['pregnancy_week'] = metadata['pregnancy_week'] is num
              ? metadata['pregnancy_week']
              : int.tryParse(metadata['pregnancy_week'].toString()) ?? 0;
        }
        if (metadata['navigator'] != null) {
          analyticsParams['navigator'] = metadata['navigator'] is bool
              ? metadata['navigator']
              : metadata['navigator'].toString().toLowerCase() == 'true';
        }
        if (metadata['self_directed'] != null) {
          analyticsParams['self_directed'] = metadata['self_directed'] is bool
              ? metadata['self_directed']
              : metadata['self_directed'].toString().toLowerCase() == 'true';
        }
      }

      // Log to Firebase Analytics
      await _analytics.logEvent(
        name: analyticsEventName,
        parameters: analyticsParams,
      );
    } catch (e) {
      // Don't throw - Firebase Analytics failures shouldn't break the app
      // Just log the error
      print(
        '⚠️ Analytics: Firebase Analytics logging error (non-critical): $e',
      );
    }
  }

  Future<void> _saveEventToFirestore({
    required String eventName,
    required String feature,
    Map<String, dynamic>? metadata,
    UserProfile? userProfile,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (userId == null) {
        return;
      }

      final anonUserId = await getAnonUserId(userId);
      final lifecycleContext = await getUserLifecycleContext(userProfile);
      final mergedMeta = {...lifecycleContext, ...(metadata ?? {})};

      await RealtimeAnalyticsService.instance.writeMobileAnalyticsEvent(
        eventName: eventName,
        feature: feature,
        userId: userId,
        anonUserId: anonUserId,
        sessionId: getSessionId(),
        metadata: mergedMeta,
      );

      _updateUserContext(userId, userProfile).catchError((e) {
        print('⚠️ Analytics: Failed to update user context: $e');
      });
    } catch (e) {
      print('⚠️ Analytics: Error saving event to Firestore: $e');
    }
  }

  /// Update user context in users collection for analytics
  Future<void> _updateUserContext(
    String userId,
    UserProfile? userProfile,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'lastActiveAt': FieldValue.serverTimestamp(),
      };

      if (userProfile != null) {
        // Cohort type
        if (userProfile.hasPrimaryProvider != null) {
          updateData['cohortType'] = userProfile.hasPrimaryProvider!
              ? 'navigator'
              : 'self_directed';
        }

        // Pregnancy info
        if (userProfile.dueDate != null) {
          updateData['dueDate'] = Timestamp.fromDate(userProfile.dueDate!);

          // Calculate gestational week
          final now = DateTime.now();
          final dueDate = userProfile.dueDate!;
          final difference = dueDate.difference(now).inDays;
          final pregnancyWeek = ((280 - difference) / 7).ceil();
          if (pregnancyWeek >= 0 && pregnancyWeek <= 40) {
            updateData['gestationalWeek'] = pregnancyWeek;
          }

          // Trimester
          final trimester = PregnancyUtils.calculateTrimester(
            userProfile.dueDate,
          );
          if (trimester != null) {
            updateData['trimester'] = trimester.toLowerCase();
          }
        }

        // Postpartum
        if (userProfile.isPostpartum == true) {
          updateData['postpartum'] = true;
          if (userProfile.dueDate != null) {
            final now = DateTime.now();
            final dueDate = userProfile.dueDate!;
            final postpartumDays = now.difference(dueDate).inDays;
            if (postpartumDays > 0) {
              updateData['postpartumWeeks'] = (postpartumDays / 7).ceil();
            }
          }
        }

        // Insurance
        if (userProfile.insuranceType != null) {
          updateData['insuranceType'] = userProfile.insuranceType;
        }

        // Navigator ID - not available in UserProfile model
        // If needed, this would need to be fetched from a separate collection

        // Support person
        if (userProfile.hasSupportPerson != null) {
          updateData['supportPerson'] = userProfile.hasSupportPerson;
        }

        // Segments (array of strings for user segmentation)
        final segments = <String>[];
        if (userProfile.hasPrimaryProvider == true) segments.add('navigator');
        if (userProfile.hasPrimaryProvider == false)
          segments.add('self_directed');
        if (userProfile.isPostpartum == true) segments.add('postpartum');
        if (userProfile.isPostpartum == false && userProfile.dueDate != null) {
          final trimester = PregnancyUtils.calculateTrimester(
            userProfile.dueDate,
          );
          if (trimester != null) segments.add(trimester.toLowerCase());
        }
        if (segments.isNotEmpty) {
          updateData['segments'] = segments;
        }
      }

      // Update user document
      await _firestore
          .collection('users')
          .doc(userId)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      // Best effort - don't throw
      print('⚠️ Analytics: Error updating user context: $e');
    }
  }

  /// Start a new session
  Future<void> startSession({String? entryPoint}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (userId == null) {
        // Can't track session without user
        return;
      }

      final sessionId = getSessionId();
      _sessionStartTime = DateTime.now();
      _sessionEntryPoint = entryPoint;

      // Get anonUserId
      final anonUserId = await getAnonUserId(userId);

      // Determine platform
      final platform = _getPlatform();

      // Create/update session document
      await _firestore.collection('user_sessions').doc(sessionId).set({
        'userId': userId,
        'anonUserId': anonUserId,
        'startedAt': FieldValue.serverTimestamp(),
        'endedAt': null,
        'durationSeconds': null,
        'entryPoint': entryPoint,
        'platform': platform,
      }, SetOptions(merge: true));

      print('✅ Analytics: Session started: $sessionId');
    } catch (e) {
      print('⚠️ Analytics: Error starting session: $e');
    }
  }

  void _clearSessionTrackingState() {
    _sessionId = null;
    _sessionStartTime = null;
    _sessionEntryPoint = null;
  }

  /// Persists session end to `user_sessions` and returns duration in seconds.
  /// Does not clear in-memory session state — call [_clearSessionTrackingState] after logging `session_ended`.
  Future<int?> endSession() async {
    try {
      if (_sessionId == null || _sessionStartTime == null) {
        return null;
      }

      final sessionId = _sessionId!;
      final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;

      await _firestore.collection('user_sessions').doc(sessionId).update({
        'endedAt': FieldValue.serverTimestamp(),
        'durationSeconds': duration,
      });

      print('✅ Analytics: Session ended: $sessionId (duration: ${duration}s)');
      return duration;
    } catch (e) {
      print('⚠️ Analytics: Error ending session: $e');
      return null;
    }
  }

  /// Get platform identifier
  String _getPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else {
      return 'unknown';
    }
  }

  /// Save micro measure (confidence signal) to specialized collection
  Future<void> saveMicroMeasure({
    required String feature,
    String? sourceId,
    int? understandMeaningScore,
    int? knowNextStepScore,
    int? confidenceScore,
    UserProfile? userProfile,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (userId == null) {
        return;
      }

      final anonUserId = await getAnonUserId(userId);

      final microMeasure = MicroMeasure(
        userId: userId,
        anonUserId: anonUserId,
        feature: feature,
        sourceId: sourceId,
        timestamp: DateTime.now(),
        understandMeaningScore: understandMeaningScore,
        knowNextStepScore: knowNextStepScore,
        confidenceScore: confidenceScore,
      );

      final data = microMeasure.toFirestore();
      data['timestamp'] = FieldValue.serverTimestamp();

      // Save to micro_measures collection
      await _firestore.collection('micro_measures').add(data);

      // Also log as event
      await logEvent(
        eventName: 'micro_measure_submitted',
        feature: feature,
        parameters: {
          if (sourceId != null) 'source_id': sourceId,
          if (understandMeaningScore != null)
            'understand_meaning_score': understandMeaningScore,
          if (knowNextStepScore != null)
            'know_next_step_score': knowNextStepScore,
          if (confidenceScore != null) 'confidence_score': confidenceScore,
        },
        userProfile: userProfile,
      );

      print('✅ Analytics: Micro measure saved');
    } catch (e) {
      print('⚠️ Analytics: Error saving micro measure: $e');
    }
  }

  /// Save helpfulness survey to specialized collection
  Future<void> saveHelpfulnessSurvey({
    required String feature,
    String? sourceId,
    int? helpfulnessRating,
    bool? didHelpNextStep,
    String? notes,
    UserProfile? userProfile,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (userId == null) {
        return;
      }

      final anonUserId = await getAnonUserId(userId);

      final survey = HelpfulnessSurvey(
        userId: userId,
        anonUserId: anonUserId,
        feature: feature,
        sourceId: sourceId,
        timestamp: DateTime.now(),
        helpfulnessRating: helpfulnessRating,
        didHelpNextStep: didHelpNextStep,
        notes: notes,
      );

      final data = survey.toFirestore();
      data['timestamp'] = FieldValue.serverTimestamp();

      // Save to helpfulness_surveys collection
      await _firestore.collection('helpfulness_surveys').add(data);

      // Also log as event
      await logEvent(
        eventName: 'helpfulness_survey_submitted',
        feature: feature,
        parameters: {
          if (sourceId != null) 'source_id': sourceId,
          if (helpfulnessRating != null)
            'helpfulness_rating': helpfulnessRating,
          if (didHelpNextStep != null) 'did_help_next_step': didHelpNextStep,
          if (notes != null) 'notes': notes,
        },
        userProfile: userProfile,
      );

      print('✅ Analytics: Helpfulness survey saved');
    } catch (e) {
      print('⚠️ Analytics: Error saving helpfulness survey: $e');
    }
  }

  /// Save milestone checkin to specialized collection
  Future<void> saveMilestoneCheckin({
    String? phase,
    bool? hadHealthQuestion,
    bool? feltClearOnNextStep,
    bool? appHelpedTakeNextStep,
    UserProfile? userProfile,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (userId == null) {
        return;
      }

      final anonUserId = await getAnonUserId(userId);

      final checkin = MilestoneCheckin(
        userId: userId,
        anonUserId: anonUserId,
        timestamp: DateTime.now(),
        phase: phase,
        hadHealthQuestion: hadHealthQuestion,
        feltClearOnNextStep: feltClearOnNextStep,
        appHelpedTakeNextStep: appHelpedTakeNextStep,
      );

      final data = checkin.toFirestore();
      data['timestamp'] = FieldValue.serverTimestamp();

      // Save to milestone_checkins collection
      await _firestore.collection('milestone_checkins').add(data);

      // Also log as event
      await logEvent(
        eventName: 'milestone_checkin_submitted',
        feature: 'user-feedback',
        parameters: {
          if (phase != null) 'phase': phase,
          if (hadHealthQuestion != null)
            'had_health_question': hadHealthQuestion,
          if (feltClearOnNextStep != null)
            'felt_clear_on_next_step': feltClearOnNextStep,
          if (appHelpedTakeNextStep != null)
            'app_helped_take_next_step': appHelpedTakeNextStep,
        },
        userProfile: userProfile,
      );

      print('✅ Analytics: Milestone checkin saved');
    } catch (e) {
      print('⚠️ Analytics: Error saving milestone checkin: $e');
    }
  }

  /// Save care navigation outcome to specialized collection
  Future<void> saveCareNavigationOutcome({
    required String needType,
    String? sourceFeature,
    required bool neededHelp,
    required String
    outcome, // "yes" | "partly" | "no" | "didnt_try" | "didnt_know_how" | "couldnt_access"
    String? notes,
    UserProfile? userProfile,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (userId == null) {
        return;
      }

      final anonUserId = await getAnonUserId(userId);

      final navigationOutcome = CareNavigationOutcome(
        userId: userId,
        anonUserId: anonUserId,
        timestamp: DateTime.now(),
        needType: needType,
        sourceFeature: sourceFeature,
        neededHelp: neededHelp,
        outcome: outcome,
        notes: notes,
      );

      final data = navigationOutcome.toFirestore();
      data['timestamp'] = FieldValue.serverTimestamp();

      // Save to care_navigation_outcomes collection
      await _firestore.collection('care_navigation_outcomes').add(data);

      // Also log as event
      await logEvent(
        eventName: 'care_navigation_outcome_submitted',
        feature: sourceFeature ?? 'app',
        parameters: {
          'need_type': needType,
          if (sourceFeature != null) 'source_feature': sourceFeature,
          'needed_help': neededHelp,
          'outcome': outcome,
          if (notes != null) 'notes': notes,
        },
        userProfile: userProfile,
      );

      print('✅ Analytics: Care navigation outcome saved');
    } catch (e) {
      print('⚠️ Analytics: Error saving care navigation outcome: $e');
    }
  }

  // ========== Learning Modules Events ==========

  Future<void> logLearningModuleViewed({
    required String moduleId,
    String? moduleTopic,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_viewed',
      feature: 'learning-modules',
      parameters: {
        'module_id': moduleId,
        if (moduleTopic != null) 'module_topic': moduleTopic,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logLearningModuleStarted({
    required String moduleId,
    String? moduleTopic,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_started',
      feature: 'learning-modules',
      parameters: {
        'module_id': moduleId,
        if (moduleTopic != null) 'module_topic': moduleTopic,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logLearningModuleCompleted({
    required String moduleId,
    String? moduleTopic,
    int? timeSpentSeconds,
    String? completionStatus,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_completed',
      feature: 'learning-modules',
      parameters: {
        'module_id': moduleId,
        if (moduleTopic != null) 'module_topic': moduleTopic,
        if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
        if (completionStatus != null) 'completion_status': completionStatus,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logLearningModuleVideoPlayed({
    required String moduleId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_video_played',
      feature: 'learning-modules',
      parameters: {'module_id': moduleId},
      userProfile: userProfile,
    );
  }

  Future<void> logLearningModuleVideoCompleted({
    required String moduleId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_video_completed',
      feature: 'learning-modules',
      parameters: {'module_id': moduleId},
      userProfile: userProfile,
    );
  }

  /// Learning modules use **surveys**, not quizzes. Two flows:
  /// `survey_context` = `qualitative_feedback` (module detail qualitative dialog) or
  /// `module_archive_gate` (pre-archive survey dialog).
  Future<void> logLearningModuleSurveySubmitted({
    required String surveyContext,
    required String moduleId,
    int? averageRating,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_survey_submitted',
      feature: 'learning-modules',
      parameters: {
        'survey_context': surveyContext,
        'module_id': moduleId,
        if (averageRating != null) 'average_rating': averageRating,
      },
      userProfile: userProfile,
    );
  }

  // ========== After Visit Summary Events ==========

  Future<void> logVisitSummaryCreated({
    required String summaryId,
    String? appointmentType,
    String? providerType,
    int? timeToComplete,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_created',
      feature: 'appointment-summarizing',
      parameters: {
        'summary_id': summaryId,
        if (appointmentType != null) 'appointment_type': appointmentType,
        if (providerType != null) 'provider_type': providerType,
        if (timeToComplete != null) 'time_to_complete': timeToComplete,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logVisitSummaryViewed({
    required String summaryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_viewed',
      feature: 'appointment-summarizing',
      parameters: {'summary_id': summaryId},
      userProfile: userProfile,
    );
  }

  Future<void> logVisitSummaryEdited({
    required String summaryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_edited',
      feature: 'appointment-summarizing',
      parameters: {'summary_id': summaryId},
      userProfile: userProfile,
    );
  }

  Future<void> logVisitSummaryExportedPdf({
    required String summaryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_exported_pdf',
      feature: 'appointment-summarizing',
      parameters: {'summary_id': summaryId, 'exported': true},
      userProfile: userProfile,
    );
  }

  Future<void> logVisitSummarySharedProvider({
    required String summaryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_shared_provider',
      feature: 'appointment-summarizing',
      parameters: {'summary_id': summaryId, 'shared_with_provider': true},
      userProfile: userProfile,
    );
  }

  Future<void> logVisitSummaryVoiceNoteAdded({
    required String summaryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_voice_note_added',
      feature: 'appointment-summarizing',
      parameters: {'summary_id': summaryId},
      userProfile: userProfile,
    );
  }

  // ========== Birth Plan Builder Events ==========

  Future<void> logBirthPlanViewed({
    String? planId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_viewed',
      feature: 'birth-plan-generator',
      parameters: {if (planId != null) 'plan_id': planId},
      userProfile: userProfile,
    );
  }

  /// User exported or shared a birth plan via system share sheet (PDF or text file).
  /// Distinct from [logBirthPlanSharedProvider] (share-with-care-team) and
  /// [logBirthPlanDownloadedPdf] (legacy PDF download naming in builder flows).
  Future<void> logBirthPlanExported({
    required String exportType,
    String? planId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_exported',
      feature: 'birth-plan-generator',
      parameters: {
        'export_type': exportType,
        if (planId != null) 'plan_id': planId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanStarted({
    String? templateId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_started',
      feature: 'birth-plan-generator',
      parameters: {if (templateId != null) 'template_id': templateId},
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanTemplateSelected({
    required String templateId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_template_selected',
      feature: 'birth-plan-generator',
      parameters: {'template_id': templateId},
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanCompleted({
    int? completionTime,
    int? sectionsCompleted,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_completed',
      feature: 'birth-plan-generator',
      parameters: {
        if (completionTime != null) 'completion_time': completionTime,
        if (sectionsCompleted != null) 'sections_completed': sectionsCompleted,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanUpdated({UserProfile? userProfile}) async {
    await logEvent(
      eventName: 'birth_plan_updated',
      feature: 'birth-plan-generator',
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanSharedProvider({UserProfile? userProfile}) async {
    await logEvent(
      eventName: 'birth_plan_shared_provider',
      feature: 'birth-plan-generator',
      parameters: {'shared': true},
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanDownloadedPdf({UserProfile? userProfile}) async {
    await logEvent(
      eventName: 'birth_plan_downloaded_pdf',
      feature: 'birth-plan-generator',
      userProfile: userProfile,
    );
  }

  // ========== Provider Search Events ==========

  Future<void> logProviderSearchInitiated({
    double? searchRadius,
    String? insuranceFilter,
    String? providerType,
    bool? telehealth,
    bool? acceptingNewPatients,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_search_initiated',
      feature: 'provider-search',
      parameters: {
        if (searchRadius != null) 'search_radius': searchRadius,
        if (insuranceFilter != null) 'insurance_filter': insuranceFilter,
        if (providerType != null) 'provider_type': providerType,
        if (telehealth != null) 'telehealth': telehealth,
        if (acceptingNewPatients != null)
          'accepting_new_patients': acceptingNewPatients,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logProviderFilterApplied({
    String? filterType,
    String? filterValue,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_filter_applied',
      feature: 'provider-search',
      parameters: {
        if (filterType != null) 'filter_type': filterType,
        if (filterValue != null) 'filter_value': filterValue,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logProviderProfileViewed({
    required String providerId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_profile_viewed',
      feature: 'provider-search',
      parameters: {'provider_id': providerId},
      userProfile: userProfile,
    );
  }

  Future<void> logProviderContactClicked({
    required String providerId,
    String? contactMethod,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_contact_clicked',
      feature: 'provider-search',
      parameters: {
        'provider_id': providerId,
        if (contactMethod != null) 'contact_method': contactMethod,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logProviderSaved({
    required String providerId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_saved',
      feature: 'provider-search',
      parameters: {'provider_id': providerId},
      userProfile: userProfile,
    );
  }

  Future<void> logProviderReviewViewed({
    required String providerId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_review_viewed',
      feature: 'provider-search',
      parameters: {'provider_id': providerId},
      userProfile: userProfile,
    );
  }

  Future<void> logProviderReviewSubmitted({
    required String providerId,
    int? rating,
    bool? feltHeard,
    bool? feltRespected,
    bool? explainedClearly,
    bool? hasWhatWentWell,
    int? reviewTextLength,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_review_submitted',
      feature: 'provider-search',
      parameters: {
        'provider_id': providerId,
        if (rating != null) 'rating': rating,
        if (feltHeard != null) 'felt_heard': feltHeard,
        if (feltRespected != null) 'felt_respected': feltRespected,
        if (explainedClearly != null) 'explained_clearly': explainedClearly,
        if (hasWhatWentWell != null) 'has_what_went_well': hasWhatWentWell,
        if (reviewTextLength != null) 'review_text_length': reviewTextLength,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logProviderListingReportSubmitted({
    required String providerId,
    required String reasonCategory,
    String? reasonCategoryLabel,
    required bool hasDetails,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_listing_report_submitted',
      feature: 'provider-search',
      parameters: {
        'provider_id': providerId,
        'reason_category': reasonCategory,
        if (reasonCategoryLabel != null && reasonCategoryLabel.isNotEmpty)
          'reason_category_label': reasonCategoryLabel,
        'has_details': hasDetails,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logProviderSelectedSuccess({
    required String providerId,
    String? selectionMethod,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_selected_success',
      feature: 'provider-search',
      parameters: {
        'provider_id': providerId,
        if (selectionMethod != null) 'selection_method': selectionMethod,
      },
      userProfile: userProfile,
    );
  }

  // ========== Journal Events ==========

  Future<void> logJournalEntryCreated({
    String? moodType,
    int? entryLength,
    String? reflectionType,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'journal_entry_created',
      feature: 'journal',
      parameters: {
        if (moodType != null) 'mood_type': moodType,
        if (entryLength != null) 'entry_length': entryLength,
        if (reflectionType != null) 'reflection_type': reflectionType,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logJournalEntryUpdated({
    required String entryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'journal_entry_updated',
      feature: 'journal',
      parameters: {'entry_id': entryId},
      userProfile: userProfile,
    );
  }

  Future<void> logJournalEntryDeleted({
    required String entryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'journal_entry_deleted',
      feature: 'journal',
      parameters: {'entry_id': entryId},
      userProfile: userProfile,
    );
  }

  Future<void> logJournalMoodSelected({
    required String moodType,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'journal_mood_selected',
      feature: 'journal',
      parameters: {'mood_type': moodType},
      userProfile: userProfile,
    );
  }

  Future<void> logJournalEntryShared({
    required String entryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'journal_entry_shared',
      feature: 'journal',
      parameters: {'entry_id': entryId},
      userProfile: userProfile,
    );
  }

  // ========== Community Forums Events ==========

  Future<void> logCommunityPostCreated({
    String? topicCategory,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_post_created',
      feature: 'community',
      parameters: {if (topicCategory != null) 'topic_category': topicCategory},
      userProfile: userProfile,
    );
  }

  Future<void> logCommunityPostViewed({
    required String threadId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_post_viewed',
      feature: 'community',
      parameters: {'thread_id': threadId},
      userProfile: userProfile,
    );
  }

  Future<void> logCommunityReplyCreated({
    required String threadId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_reply_created',
      feature: 'community',
      parameters: {'thread_id': threadId},
      userProfile: userProfile,
    );
  }

  Future<void> logCommunityPostLiked({
    required String threadId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_post_liked',
      feature: 'community',
      parameters: {'thread_id': threadId},
      userProfile: userProfile,
    );
  }

  Future<void> logCommunityPostReplied({
    required String threadId,
    int? replyLength,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_post_replied',
      feature: 'community',
      parameters: {
        'thread_id': threadId,
        if (replyLength != null) 'reply_length': replyLength,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logCommunityPostReported({
    required String threadId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_post_reported',
      feature: 'community',
      parameters: {'thread_id': threadId},
      userProfile: userProfile,
    );
  }

  Future<void> logCommunitySupportRequest({
    required String threadId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_support_request',
      feature: 'community',
      parameters: {'thread_id': threadId},
      userProfile: userProfile,
    );
  }

  // ========== Surveys / Micro Measures Events ==========

  Future<void> logConfidenceSignalSubmitted({
    String? sourceId,
    int? understandMeaningScore,
    int? knowNextStepScore,
    int? confidenceScore,
    UserProfile? userProfile,
  }) async {
    // Save to specialized micro_measures collection
    await saveMicroMeasure(
      feature: 'user-feedback',
      sourceId: sourceId,
      understandMeaningScore: understandMeaningScore,
      knowNextStepScore: knowNextStepScore,
      confidenceScore: confidenceScore,
      userProfile: userProfile,
    );
  }

  Future<void> logHelpfulnessSurveySubmitted({
    String? sourceId,
    int? helpfulnessRating,
    bool? tookNextStep,
    UserProfile? userProfile,
  }) async {
    // Save to specialized helpfulness_surveys collection
    await saveHelpfulnessSurvey(
      feature: 'user-feedback',
      sourceId: sourceId,
      helpfulnessRating: helpfulnessRating,
      didHelpNextStep: tookNextStep,
      userProfile: userProfile,
    );
  }

  Future<void> logMilestoneCheckinSubmitted({
    String? phase,
    bool? hadHealthQuestion,
    bool? feltClearOnNextStep,
    bool? appHelpedTakeNextStep,
    UserProfile? userProfile,
  }) async {
    // Save to specialized milestone_checkins collection
    await saveMilestoneCheckin(
      phase: phase,
      hadHealthQuestion: hadHealthQuestion,
      feltClearOnNextStep: feltClearOnNextStep,
      appHelpedTakeNextStep: appHelpedTakeNextStep,
      userProfile: userProfile,
    );
  }

  // ========== System Metrics Events ==========

  Future<void> logSessionStarted({
    String? entryPoint,
    UserProfile? userProfile,
  }) async {
    // Start session tracking in user_sessions collection
    await startSession(entryPoint: entryPoint);

    // Also log as event
    await logEvent(
      eventName: 'session_started',
      feature: 'app',
      parameters: {if (entryPoint != null) 'entry_point': entryPoint},
      userProfile: userProfile,
    );
  }

  Future<void> logSessionEnded({
    int? durationSeconds,
    UserProfile? userProfile,
  }) async {
    final computed = await endSession();
    final duration = durationSeconds ?? computed;
    if (duration == null) {
      _clearSessionTrackingState();
      return;
    }

    await logEvent(
      eventName: 'session_ended',
      feature: 'app',
      parameters: {
        'duration_seconds': duration,
      },
      durationMs: duration * 1000,
      userProfile: userProfile,
    );
    _clearSessionTrackingState();
  }

  /// Feature lifecycle: user entered a feature surface (paired with [logFeatureSessionEnded]).
  Future<void> logFeatureSessionStarted({
    required String feature,
    String? entrySource,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'feature_session_started',
      feature: feature,
      parameters: {
        if (entrySource != null) 'entry_source': entrySource,
      },
      userProfile: userProfile,
    );
  }

  /// Feature lifecycle: user left a feature surface (dwell time since matching start).
  Future<void> logFeatureSessionEnded({
    required String feature,
    required int durationSeconds,
    String? entrySource,
    UserProfile? userProfile,
  }) async {
    final safeSeconds = durationSeconds < 0 ? 0 : durationSeconds;
    await logEvent(
      eventName: 'feature_session_ended',
      feature: feature,
      parameters: {
        'duration_seconds': safeSeconds,
        if (entrySource != null) 'entry_source': entrySource,
      },
      durationMs: safeSeconds * 1000,
      userProfile: userProfile,
    );
  }

  Future<void> logScreenView({
    required String screenName,
    String? feature,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'screen_view',
      feature: feature ?? 'app',
      parameters: {'screen_name': screenName},
      userProfile: userProfile,
    );
  }

  Future<void> logScreenTimeSpent({
    required String screenName,
    required int timeSpentSeconds,
    String? feature,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'screen_time_spent',
      feature: feature ?? 'app',
      parameters: {
        'screen_name': screenName,
        'time_spent_seconds': timeSpentSeconds,
      },
      durationMs: timeSpentSeconds * 1000,
      userProfile: userProfile,
    );
  }

  Future<void> logFeatureTimeSpent({
    required String feature,
    required int timeSpentSeconds,
    String? sourceId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'feature_time_spent',
      feature: feature,
      parameters: {
        'time_spent_seconds': timeSpentSeconds,
        if (sourceId != null) 'source_id': sourceId,
      },
      durationMs: timeSpentSeconds * 1000,
      userProfile: userProfile,
    );
  }

  Future<void> logFlowAbandoned({
    required String flowName,
    String? stepName,
    String? reason,
    String? feature,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'flow_abandoned',
      feature: feature ?? 'app',
      parameters: {
        'flow_name': flowName,
        if (stepName != null) 'step_name': stepName,
        if (reason != null) 'reason': reason,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logNotificationOpened({
    required String notificationId,
    String? notificationType,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'notification_opened',
      feature: 'app',
      parameters: {
        'notification_id': notificationId,
        if (notificationType != null) 'notification_type': notificationType,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logNotificationReceived({
    required String notificationId,
    String? notificationType,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'notification_received',
      feature: 'app',
      parameters: {
        'notification_id': notificationId,
        if (notificationType != null) 'notification_type': notificationType,
      },
      userProfile: userProfile,
    );
  }
}
