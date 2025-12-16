import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cors/ui_theme.dart';
import 'cors/main_navigation_scaffold.dart';
import 'app_router.dart';
import 'auth/auth_screen.dart';
import 'profile/profile_creation_screen.dart';
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
  bool _isChecking = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final hasProfile = await _databaseService.userProfileExists(widget.userId);
    if (mounted) {
      setState(() {
        _isChecking = false;
        // Determine target screen based on profile status
        if (hasProfile) {
          _targetScreen = const MainNavigationScaffold();
        } else {
          _targetScreen = const ProfileCreationScreen();
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
