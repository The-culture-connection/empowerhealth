import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';
import '../../core/constants.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightBackground,
                    AppTheme.lightMuted,
                  ],
                ),
              ),
              child: backgroundImage != null
                  ? Image.asset(
                      backgroundImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    )
                  : null,
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  // Logo
                  Center(
                    child: DS.logo(size: 100),
                  ),
                  DS.gapXL,
                  // App name
                  const Text(
                    'EmpowerHealth',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  DS.gapL,
                  // Tagline
                  Text(
                    'Your Prenatal Journey, Empowered',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.lightForeground.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  DS.gapXXL,
                  DS.gapXL,
                  // Sign Up Button
                  DS.cta(
                    'Sign Up',
                    icon: Icons.person_add,
                    onPressed: () => Navigator.pushNamed(context, Routes.signup),
                  ),
                  DS.gapL,
                  // Login Button
                  DS.secondary(
                    'Sign In',
                    icon: Icons.login,
                    onPressed: () => Navigator.pushNamed(context, Routes.login),
                  ),
                  DS.gapXL,
                  // Terms
                  Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightForeground.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
