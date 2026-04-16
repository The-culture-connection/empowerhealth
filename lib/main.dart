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
    // Do **not** await full FCM + Firestore wiring here: on some iOS / SDK combinations
    // `getInitialMessage`, `getToken`, or Firestore can block indefinitely before the first
    // frame, which leaves the user on a white launch screen forever.
  }

  runApp(AdvocacyApp(firebaseReady: firebaseReady));
}

class AdvocacyApp extends StatefulWidget {
  const AdvocacyApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<AdvocacyApp> createState() => _AdvocacyAppState();
}

class _AdvocacyAppState extends State<AdvocacyApp> {
  @override
  void initState() {
    super.initState();
    if (widget.firebaseReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_runDeferredPushSetup());
      });
    }
  }

  Future<void> _runDeferredPushSetup() async {
    try {
      await PushNotificationService.instance
          .setupAfterFirebaseInitialized()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint(
                '⚠️ [FCM] setupAfterFirebaseInitialized timed out after 30s — UI already running',
              );
            },
          );
    } catch (e, st) {
      debugPrint('⚠️ Push notification setup failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
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
        home: const _InitialAuthGate(),
      ),
    );
  }
}

/// Resolves the first auth state without relying on [StreamBuilder]'s initial
/// `ConnectionState.waiting`, which can persist on some iOS + Firebase Auth combinations
/// after SDK upgrades and leaves the app on an endless loading surface.
class _InitialAuthGate extends StatefulWidget {
  const _InitialAuthGate();

  @override
  State<_InitialAuthGate> createState() => _InitialAuthGateState();
}

class _InitialAuthGateState extends State<_InitialAuthGate> {
  late final StreamSubscription<User?> _authSub;
  User? _user = FirebaseAuth.instance.currentUser;
  /// When true, we have either heard from [authStateChanges] or hit the safety timeout.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _ready = true;
    }
    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (!mounted) return;
        setState(() {
          _user = user;
          _ready = true;
        });
      },
      onError: (Object e) {
        debugPrint('⚠️ Auth state stream error: $e');
        if (!mounted) return;
        setState(() => _ready = true);
      },
    );
    Future<void>.delayed(const Duration(seconds: 8), () {
      if (!mounted || _ready) return;
      debugPrint('⚠️ Auth state: proceeding after timeout (stream did not resolve)');
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    unawaited(_authSub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundWarm,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final user = _user;
    if (user != null) {
      return _AuthWrapper(userId: user.uid);
    }
    return const AuthScreen();
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
    await _checkProfile();
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
    Widget resolvedScreen = const MainNavigationScaffold();

    try {
      final hasProfile = await _databaseService
          .userProfileExists(widget.userId)
          .timeout(const Duration(seconds: 12));

      if (!hasProfile) {
        resolvedScreen = const ProfileCreationScreen();
      } else {
        final hasConsent = await _checkConsent(
          widget.userId,
        ).timeout(const Duration(seconds: 12));
        if (!hasConsent) {
          resolvedScreen = ConsentScreen(
            isFirstRun: true,
            onConsentAccepted: _onConsentAccepted,
          );
        }
      }
    } catch (e) {
      debugPrint(
        '⚠️ Startup route resolution failed, falling back to main navigation: $e',
      );
      resolvedScreen = const MainNavigationScaffold();
    }

    if (!mounted) return;
    setState(() {
      _targetScreen = resolvedScreen;
      _isChecking = false;
    });
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
