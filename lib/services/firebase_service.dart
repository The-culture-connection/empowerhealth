import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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
      
      // TEMPORARILY DISABLED: App Check activation
      // App Check is causing "Too many attempts" errors because debug token isn't registered
      // TODO: Re-enable after adding debug token to Firebase Console
      // Debug token: 8c88f9e4-b464-4115-aa74-e972fff7e419
      // 
      // To re-enable:
      // 1. Go to Firebase Console → App Check → your app → Manage debug tokens
      // 2. Add token: 8c88f9e4-b464-4115-aa74-e972fff7e419
      // 3. Uncomment the code below
      // 4. Also disable App Check enforcement in Firebase Console if needed
      
      /*
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug, // Use debug for development
          // Switch to AndroidProvider.playIntegrity for production
          appleProvider: AppleProvider.debug, // Use debug for development
          // Switch to AppleProvider.appAttest or AppleProvider.deviceCheck for production
        );
        if (kDebugMode) {
          print('✅ App Check activated successfully');
          print('📋 IMPORTANT: Copy the debug token from logs and add it to Firebase Console → App Check → Manage debug tokens');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ App Check activation failed: $e');
        }
      }
      */
      
      if (kDebugMode) {
        print('⚠️ App Check temporarily disabled - function will work without App Check token');
        print('📋 To enable App Check: Add debug token 8c88f9e4-b464-4115-aa74-e972fff7e419 to Firebase Console');
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

