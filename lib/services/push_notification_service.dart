import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/push_audience_topics.dart';
import '../utils/pregnancy_utils.dart';
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
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  String? _lastUid;

  /// Last FCM token written to Firestore (used to delete on sign-out; avoid `getToken` after auth clears).
  String? _lastPersistedToken;

  /// Avoid redundant subscribe/unsubscribe when Firestore snapshot fires often.
  String? _lastAudienceTopicFingerprint;

  /// Coalesce rapid `users/{uid}` updates so we do not churn FCM topic subscriptions.
  Timer? _topicSyncDebounce;
  Map<String, dynamic>? _pendingProfileForTopicSync;

  bool _notificationsAuthorized = false;

  /// Foreground / auth FCM listeners (register at most once).
  bool _fcmListenersRegistered = false;

  /// Call after [FirebaseService.initialize] succeeds. May run after [runApp] (post-frame).
  Future<void> setupAfterFirebaseInitialized() async {
    if (kIsWeb) {
      debugPrint('[FCM] Skipping push setup on web.');
      return;
    }

    // iOS: show banners while app is in foreground (otherwise only system tray / nothing).
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await _messaging
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            )
            .timeout(const Duration(seconds: 8));
      } on TimeoutException {
        debugPrint('[FCM] setForegroundNotificationPresentationOptions timed out');
      } catch (e) {
        debugPrint('[FCM] setForegroundNotificationPresentationOptions failed: $e');
      }
      debugPrint('[FCM] iOS foreground presentation: alert, badge, sound');
    }

    NotificationSettings? settings;
    try {
      settings = await _messaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      debugPrint('[FCM] requestPermission timed out — reading settings from native');
      try {
        settings = await _messaging
            .getNotificationSettings()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[FCM] getNotificationSettings failed after permission timeout: $e');
        settings = null;
      }
    } catch (e) {
      debugPrint('[FCM] requestPermission failed: $e');
      settings = null;
    }
    if (settings != null) {
      debugPrint(
        '[FCM] requestPermission authorizationStatus=${settings.authorizationStatus} '
        '(alert=${settings.alert}, badge=${settings.badge}, sound=${settings.sound})',
      );
      _notificationsAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
    } else {
      debugPrint('[FCM] No notification settings — push features disabled until next launch');
      _notificationsAuthorized = false;
    }

    try {
      await _messaging.setAutoInitEnabled(true).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      debugPrint('[FCM] setAutoInitEnabled timed out');
    } catch (e) {
      debugPrint('[FCM] setAutoInitEnabled failed: $e');
    }

    // Topic subscribe requires an APNS device token on iOS; do not block startup on it.
    unawaited(_subscribeCommunityTopicWhenApnsReady());

    RemoteMessage? initial;
    try {
      initial = await _messaging
          .getInitialMessage()
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      debugPrint('[FCM] getInitialMessage timed out — skipping');
      initial = null;
    }
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
    if (_lastUid != null && _notificationsAuthorized) {
      _attachUserTopicListener(_lastUid!);
    }

    if (!_fcmListenersRegistered) {
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

      _messaging.onTokenRefresh.listen((token) async {
        debugPrint('[FCM] onTokenRefresh (len=${token.length})');
        await _saveTokenToFirestore(token: token, reason: 'token_refresh');
      });

      await _authSub?.cancel();
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
        final uid = user?.uid;
        if (_lastUid != null && uid == null) {
          debugPrint('[FCM] auth signed out (was $_lastUid); removing device token doc');
          _detachUserTopicListener();
          await _unsubscribeAllManagedAudienceTopics();
          _lastAudienceTopicFingerprint = null;
          await _removeTokenDocForUser(_lastUid!);
        }
        _lastUid = uid;
        if (uid != null) {
          await _persistTokenForCurrentUser(reason: 'auth_state');
          if (_notificationsAuthorized) {
            _attachUserTopicListener(uid);
          }
        }
      });
      _fcmListenersRegistered = true;
    }
  }

  /// `subscribeToTopic` on iOS requires an APNS token; retry in the background so cold start
  /// is not coupled to token timing (especially after Xcode / iOS SDK upgrades).
  Future<void> _subscribeCommunityTopicWhenApnsReady() async {
    const topic = 'community_new_posts';
    if (kIsWeb) return;

    if (defaultTargetPlatform != TargetPlatform.iOS) {
      try {
        await _messaging.subscribeToTopic(topic);
        debugPrint('[FCM] subscribed to topic $topic');
      } catch (e) {
        debugPrint('[FCM] subscribeToTopic $topic failed: $e');
      }
      return;
    }

    for (var i = 0; i < 30; i++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null) {
        try {
          await _messaging.subscribeToTopic(topic);
          debugPrint('[FCM] subscribed to topic $topic');
        } catch (e) {
          debugPrint('[FCM] subscribeToTopic $topic failed: $e');
        }
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    debugPrint(
      '[FCM] APNS token still unavailable after retries; topic $topic subscribe skipped',
    );
  }

  void _attachUserTopicListener(String uid) {
    _detachUserTopicListener();
    _profileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
      (snap) {
        if (!snap.exists || snap.data() == null) return;
        _pendingProfileForTopicSync = snap.data();
        _topicSyncDebounce?.cancel();
        _topicSyncDebounce = Timer(const Duration(milliseconds: 600), () {
          final data = _pendingProfileForTopicSync;
          _pendingProfileForTopicSync = null;
          if (data != null) {
            unawaited(_syncAudienceTopicsFromUserDoc(data));
          }
        });
      },
      onError: (e) => debugPrint('[FCM] user profile listener: $e'),
    );
    debugPrint('[FCM] attached users/$uid topic listener');
  }

  void _detachUserTopicListener() {
    _topicSyncDebounce?.cancel();
    _topicSyncDebounce = null;
    _pendingProfileForTopicSync = null;
    _profileSub?.cancel();
    _profileSub = null;
  }

  Future<void> _unsubscribeAllManagedAudienceTopics() async {
    for (final topic in PushAudienceTopics.allManagedAudienceTopics()) {
      try {
        await _messaging.unsubscribeFromTopic(topic);
        debugPrint('[FCM] unsubscribed $topic');
      } catch (e) {
        debugPrint('[FCM] unsubscribe $topic: $e');
      }
    }
  }

  /// Resolves pregnancy stage + cohort FCM topics from Firestore `users` fields.
  Future<void> _syncAudienceTopicsFromUserDoc(Map<String, dynamic> data) async {
    if (!_notificationsAuthorized || kIsWeb) return;

    final stageTopic = _resolveStageTopic(data);
    final cohortTopic = _resolveCohortTopic(data);
    final fingerprint = 'g|${stageTopic ?? '-'}|$cohortTopic';
    if (fingerprint == _lastAudienceTopicFingerprint) return;
    _lastAudienceTopicFingerprint = fingerprint;

    // Reset managed audience topics, then subscribe to the current set.
    await _unsubscribeAllManagedAudienceTopics();

    try {
      await _messaging.subscribeToTopic(PushAudienceTopics.general);
      debugPrint('[FCM] subscribed ${PushAudienceTopics.general}');
    } catch (e) {
      debugPrint('[FCM] subscribe general: $e');
    }

    if (stageTopic != null) {
      try {
        await _messaging.subscribeToTopic(stageTopic);
        debugPrint('[FCM] subscribed $stageTopic');
      } catch (e) {
        debugPrint('[FCM] subscribe $stageTopic: $e');
      }
    }

    try {
      await _messaging.subscribeToTopic(cohortTopic);
      debugPrint('[FCM] subscribed $cohortTopic');
    } catch (e) {
      debugPrint('[FCM] subscribe cohort: $e');
    }
  }

  /// One of trimester / postpartum topics, or null if not in a targeted stage.
  String? _resolveStageTopic(Map<String, dynamic> data) {
    final isPostpartum = data['isPostpartum'] == true;
    final stageStr =
        data['pregnancyStage'] != null ? data['pregnancyStage'].toString().toLowerCase() : '';
    if (isPostpartum || stageStr.contains('post')) {
      return PushAudienceTopics.postpartum;
    }

    final isPregnant = data['isPregnant'] == true;
    final dueTs = data['dueDate'];
    DateTime? dueDate;
    if (dueTs is Timestamp) dueDate = dueTs.toDate();

    if (!isPregnant || dueDate == null) {
      return null;
    }

    final t = PregnancyUtils.calculateTrimester(dueDate);
    switch (t) {
      case 'Second':
        return PushAudienceTopics.trimesterSecond;
      case 'Third':
        return PushAudienceTopics.trimesterThird;
      case 'First':
      default:
        return PushAudienceTopics.trimesterFirst;
    }
  }

  String _resolveCohortTopic(Map<String, dynamic> data) {
    final cohort = data['cohortType']?.toString().toLowerCase();
    if (cohort == 'navigator') return PushAudienceTopics.cohortNavigator;
    if (cohort == 'self_directed') return PushAudienceTopics.cohortSelfDirected;
    if (data['hasPrimaryProvider'] == true) return PushAudienceTopics.cohortNavigator;
    return PushAudienceTopics.cohortSelfDirected;
  }

  Future<void> _persistTokenForCurrentUser({required String reason}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[FCM] persist skipped (no user) reason=$reason');
      return;
    }
    try {
      final token = await _messaging
          .getToken()
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () {
              debugPrint('[FCM] getToken() timed out reason=$reason');
              return null;
            },
          );
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

    // FCM can rotate the registration token without any APNs change. Doc id is derived from
    // the token, so a rotation would otherwise leave the old doc with a dead token and Cloud
    // Functions would keep sending to it (messaging/registration-token-not-registered).
    final previous = _lastPersistedToken;
    if (previous != null && previous.isNotEmpty && previous != token) {
      try {
        final oldId = _tokenDocId(previous);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('devices')
            .doc(oldId)
            .delete();
        debugPrint(
          '[FCM] removed superseded device doc users/${user.uid}/devices/$oldId (token rotated)',
        );
      } catch (e) {
        debugPrint('[FCM] failed to remove superseded device doc: $e');
      }
    }

    final docId = _tokenDocId(token);
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(docId);

    try {
      DocumentSnapshot<Map<String, dynamic>>? existing;
      try {
        existing = await ref.get().timeout(const Duration(seconds: 15));
      } on TimeoutException {
        debugPrint(
          '[FCM] Firestore get devices doc timed out — merge write (createdAt only if doc known new)',
        );
        existing = null;
      }
      final data = <String, dynamic>{
        'fcmToken': token,
        'platform': platform,
        'appVersion': appVersion,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastReason': reason,
      };
      if (existing != null && !existing.exists) {
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
    _detachUserTopicListener();
    _authSub?.cancel();
    _authSub = null;
  }
}
