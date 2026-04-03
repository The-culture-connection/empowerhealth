import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cors/ui_theme.dart';
import 'cors/main_navigation_scaffold.dart';
import 'app_router.dart';
import 'auth/auth_screen.dart';
import 'profile/profile_creation_screen.dart';
import 'privacy/consent_screen.dart';
import 'services/firebase_service.dart';
import 'services/push_notification_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/analytics_service.dart';
import 'providers/profile_creation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  // Initialize Firebase with error handling
  try {
    await FirebaseService.initialize();
    firebaseReady = true;
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    // Continue anyway - app can still run without Firebase for testing
  }

  if (firebaseReady) {
    // FCM: background isolate — register after Firebase.initializeApp, before runApp.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    try {
      await PushNotificationService.instance.setupAfterFirebaseInitialized();
    } catch (e, st) {
      debugPrint('⚠️ Push notification setup failed: $e\n$st');
    }
  }

  runApp(const AdvocacyApp());
}

class AdvocacyApp extends StatelessWidget {
  const AdvocacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileCreationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EmpowerHealth',
        theme: AppTheme.light(),
        themeMode: ThemeMode.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: StreamBuilder<User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            // Show loading while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: AppTheme.backgroundWarm,
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            
            // If user is logged in, check if they have a profile
            if (snapshot.hasData && snapshot.data != null) {
              return _AuthWrapper(userId: snapshot.data!.uid);
            }
            
            // User is not logged in, show auth screen
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}

class _AuthWrapper extends StatefulWidget {
  final String userId;
  const _AuthWrapper({required this.userId});

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  final AnalyticsService _analytics = AnalyticsService();
  bool _isChecking = true;
  Widget? _targetScreen;
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWithAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_endSessionOnDispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(_onAppPaused());
    } else if (state == AppLifecycleState.resumed &&
        _lastLifecycleState == AppLifecycleState.paused) {
      unawaited(_onAppResumedAfterPause());
    }
    _lastLifecycleState = state;
  }

  Future<void> _onAppPaused() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userProfile = await _databaseService.getUserProfile(widget.userId);
      await _analytics.logSessionEnded(userProfile: userProfile);
    } catch (e) {
      debugPrint('⚠️ Analytics: session end on pause: $e');
    }
  }

  Future<void> _onAppResumedAfterPause() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userProfile = await _databaseService.getUserProfile(widget.userId);
      await _analytics.logSessionStarted(
        entryPoint: 'app_resume',
        userProfile: userProfile,
      );
    } catch (e) {
      debugPrint('⚠️ Analytics: session start on resume: $e');
    }
  }

  Future<void> _endSessionOnDispose() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userProfile = await _databaseService.getUserProfile(widget.userId);
      await _analytics.logSessionEnded(userProfile: userProfile);
    } catch (e) {
      debugPrint('⚠️ Analytics: session end on dispose: $e');
    }
  }

  /// Wait for auth to be fully restored before sending analytics
  Future<void> _initializeWithAuth() async {
    // Wait for initial auth resolution before proceeding
    final user = await _analytics.waitForInitialAuthResolution();
    
    if (user != null) {
      // Auth is ready, track session start
      _trackSessionStart();
    } else {
      debugPrint('⚠️ Analytics: No authenticated user - session tracking skipped');
    }
    
    // Continue with profile check regardless of auth status
    _checkProfile();
  }

  Future<void> _trackSessionStart() async {
    try {
      final userProfile = await _databaseService.getUserProfile(widget.userId);
      await _analytics.logSessionStarted(
        entryPoint: 'app_cold_start',
        userProfile: userProfile,
      );
      debugPrint('✅ Analytics: Session started tracked');
    } catch (e) {
      debugPrint('⚠️ Analytics: Failed to track session start: $e');
      // Best-effort: don't block app initialization
    }
  }

  Future<void> _checkProfile() async {
    final hasProfile = await _databaseService.userProfileExists(widget.userId);
    
    if (mounted) {
      setState(() {
        _isChecking = false;
        // Show profile creation first, then consent will be shown after onboarding
        if (hasProfile) {
          // Check consent after profile exists
          _checkConsentAndNavigate();
        } else {
          _targetScreen = const ProfileCreationScreen();
        }
      });
    }
  }

  Future<void> _checkConsentAndNavigate() async {
    final hasConsent = await _checkConsent(widget.userId);
    
    if (mounted) {
      setState(() {
        if (!hasConsent) {
          // Show consent screen after onboarding
          _targetScreen = ConsentScreen(
            isFirstRun: true,
            onConsentAccepted: _onConsentAccepted,
          );
        } else {
          _targetScreen = const MainNavigationScaffold();
        }
      });
    }
  }

  Future<void> _onConsentAccepted() async {
    // After consent is accepted, navigate to main screen
    // Profile already exists at this point
    if (mounted) {
      setState(() {
        _targetScreen = const MainNavigationScaffold();
      });
    }
  }

  Future<bool> _checkConsent(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!doc.exists) return false;
      
      final consents = doc.data()?['consents'];
      if (consents == null) return false;
      
      return consents['termsAccepted'] == true && 
             consents['privacyAccepted'] == true;
    } catch (e) {
      debugPrint('Error checking consent: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundWarm,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return _targetScreen ??
        Scaffold(
          backgroundColor: AppTheme.backgroundWarm,
          body: const SizedBox.shrink(),
        );
  }
}
