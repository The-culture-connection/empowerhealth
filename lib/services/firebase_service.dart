import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase: $e');
      }
      rethrow;
    }
  }

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

