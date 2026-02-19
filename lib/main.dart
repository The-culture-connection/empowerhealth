import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cors/ui_theme.dart';
import 'cors/main_navigation_scaffold.dart';
import 'app_router.dart';
import 'auth/auth_screen.dart';
import 'profile/profile_creation_screen.dart';
import 'privacy/privacy_consent_screen.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'providers/profile_creation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  try {
    await FirebaseService.initialize();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    // Continue anyway - app can still run without Firebase for testing
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
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
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

class _AuthWrapperState extends State<_AuthWrapper> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isChecking = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _checkProfileAndConsent();
  }

  Future<void> _checkProfileAndConsent() async {
    final hasProfile = await _databaseService.userProfileExists(widget.userId);
    
    // Check if user has accepted privacy consent
    bool hasConsent = false;
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        final consents = userDoc.data()?['consents'];
        hasConsent = consents != null &&
            consents['termsAccepted'] == true &&
            consents['privacyAccepted'] == true;
      }
    } catch (e) {
      // If error checking consent, assume not accepted (safer)
      hasConsent = false;
    }
    
    if (mounted) {
      setState(() {
        _isChecking = false;
        // Determine target screen based on profile and consent status
        if (!hasConsent) {
          // Show consent screen first
          _targetScreen = const PrivacyConsentScreen(isFirstRun: true);
        } else if (!hasProfile) {
          _targetScreen = const ProfileCreationScreen();
        } else {
          _targetScreen = const MainNavigationScaffold();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return _targetScreen ?? const Scaffold(body: SizedBox.shrink());
  }
}
