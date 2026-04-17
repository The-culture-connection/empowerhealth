import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Set `--dart-define=USE_FIREBASE_EMULATOR=true` for local Firestore emulator (see docs/realtime-analytics.md).
const bool _kUseFirebaseEmulator =
    bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      if (kDebugMode && _kUseFirebaseEmulator) {
        FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
        print('Firestore emulator: 127.0.0.1:8080');
      }
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }

      // firebase_app_check was removed from pubspec: the iOS plugin still attempted
      // DeviceCheck / App Attest token exchange and crashed when the app was not
      // registered in Firebase Console → App Check (FAILED_PRECONDITION / SIGABRT).
      // To use App Check later: add `firebase_app_check`, call activate() after
      // initializeApp, register the iOS app in App Check, and add a debug token for dev.
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase: $e');
      }
      rethrow;
    }
  }

  /// Options for the default Firebase app (used by [initialize] and by FCM background isolate).
  static FirebaseOptions get firebaseOptions => _getFirebaseOptions();

  static FirebaseOptions _getFirebaseOptions() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyA2arGVVaRoFBJ8Bhpq6oPuvIbM8d5gzhM',
        appId: '1:725364003316:android:1411a89c67dc93338229a1',
        messagingSenderId: '725364003316',
        projectId: 'empower-health-watch',
        storageBucket: 'empower-health-watch.firebasestorage.app',
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyAe1UtHRohnVmmh0EIOvpJRyLCaKOfuqD4',
        appId: '1:725364003316:ios:f627cbea909c143e8229a1',
        messagingSenderId: '725364003316',
        projectId: 'empower-health-watch',
        storageBucket: 'empower-health-watch.firebasestorage.app',
        iosBundleId: 'com.example.empowerhealth',
      );
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
