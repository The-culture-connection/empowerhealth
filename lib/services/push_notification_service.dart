import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'firebase_service.dart';

/// Top-level background handler — must not be a class method.
/// Register with [FirebaseMessaging.onBackgroundMessage] before [runApp].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: FirebaseService.firebaseOptions);
  debugPrint(
    '[FCM][background] messageId=${message.messageId} '
    'from=${message.from} data=${message.data}',
  );
}

/// iOS-first FCM wiring: permission, token persistence, foreground presentation,
/// and handlers for foreground / background tap / cold start.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  StreamSubscription<User?>? _authSub;
  String? _lastUid;

  /// Last FCM token written to Firestore (used to delete on sign-out; avoid `getToken` after auth clears).
  String? _lastPersistedToken;

  /// Call after [FirebaseService.initialize] succeeds, before [runApp].
  Future<void> setupAfterFirebaseInitialized() async {
    if (kIsWeb) {
      debugPrint('[FCM] Skipping push setup on web.');
      return;
    }

    // iOS: show banners while app is in foreground (otherwise only system tray / nothing).
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] iOS foreground presentation: alert, badge, sound');
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint(
      '[FCM] requestPermission authorizationStatus=${settings.authorizationStatus} '
      '(alert=${settings.alert}, badge=${settings.badge}, sound=${settings.sound})',
    );

    await _messaging.setAutoInitEnabled(true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '[FCM][foreground] messageId=${message.messageId} '
        'notification=${message.notification?.title} '
        'data=${message.data}',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '[FCM][opened from background] messageId=${message.messageId} '
        'data=${message.data}',
      );
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint(
        '[FCM][initial / cold start] messageId=${initial.messageId} data=${initial.data}',
      );
    } else {
      debugPrint('[FCM][initial / cold start] no pending message');
    }

    // Token + Firestore when user is signed in; refresh subscription.
    _lastUid = FirebaseAuth.instance.currentUser?.uid;
    await _persistTokenForCurrentUser(reason: 'after_setup');

    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('[FCM] onTokenRefresh (len=${token.length})');
      await _saveTokenToFirestore(token: token, reason: 'token_refresh');
    });

    await _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      final uid = user?.uid;
      if (_lastUid != null && uid == null) {
        debugPrint('[FCM] auth signed out (was $_lastUid); removing device token doc');
        await _removeTokenDocForUser(_lastUid!);
      }
      _lastUid = uid;
      if (uid != null) {
        await _persistTokenForCurrentUser(reason: 'auth_state');
      }
    });
  }

  Future<void> _persistTokenForCurrentUser({required String reason}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[FCM] persist skipped (no user) reason=$reason');
      return;
    }
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] getToken() empty (simulator or APNs not ready?) reason=$reason');
        return;
      }
      debugPrint('[FCM] FCM token (len=${token.length}) reason=$reason');
      await _saveTokenToFirestore(token: token, reason: reason);
    } catch (e, st) {
      debugPrint('[FCM] getToken / persist failed: $e\n$st');
    }
  }

  Future<void> _saveTokenToFirestore({
    required String token,
    required String reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[FCM] Firestore save skipped (no user) reason=$reason');
      return;
    }

    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'unknown',
    };

    String appVersion = 'unknown';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (e) {
      debugPrint('[FCM] PackageInfo failed: $e');
    }

    final docId = _tokenDocId(token);
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(docId);

    try {
      final existing = await ref.get();
      final data = <String, dynamic>{
        'fcmToken': token,
        'platform': platform,
        'appVersion': appVersion,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastReason': reason,
      };
      if (!existing.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      await ref.set(data, SetOptions(merge: true));
      _lastPersistedToken = token;
      debugPrint(
        '[FCM] Firestore token save OK users/${user.uid}/devices/$docId reason=$reason',
      );
    } catch (e, st) {
      debugPrint('[FCM] Firestore token save FAILED: $e\n$st');
    }
  }

  String _tokenDocId(String token) {
    // Firestore doc IDs cannot contain '/'; FCM tokens are typically safe.
    return token.replaceAll('/', '_');
  }

  Future<void> _removeTokenDocForUser(String uid) async {
    final token = _lastPersistedToken;
    if (token == null || token.isEmpty) {
      debugPrint('[FCM] No cached token to remove on sign-out');
      return;
    }
    try {
      final docId = _tokenDocId(token);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(docId)
          .delete();
      _lastPersistedToken = null;
      debugPrint('[FCM] Removed users/$uid/devices/$docId on sign-out');
    } catch (e) {
      debugPrint('[FCM] remove token doc on sign-out: $e');
    }
  }

  void dispose() {
    _authSub?.cancel();
    _authSub = null;
  }
}
