import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';
import '../../core/constants.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
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
            ),
            // Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DS.gapXXL,
                  // Logo
                  DS.logo(size: 80),
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
                  DS.gapXL,
                  // Description
                  Text(
                    'Record visits, access expert resources, connect with your care team, and join a supportive community—all in one secure place.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.lightForeground.withOpacity(0.7),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  DS.gapXXL,
                  DS.gapXL,
                  
                  // Features
                  _FeatureCard(
                    icon: Icons.mic,
                    title: 'Record & Transcribe',
                    description: 'Never miss important details from your visits',
                    color: AppTheme.lightPrimary,
                  ),
                  DS.gapL,
                  _FeatureCard(
                    icon: Icons.school,
                    title: 'Learn & Grow',
                    description: 'Access expert resources and education',
                    color: AppTheme.lightAccent,
                  ),
                  DS.gapL,
                  _FeatureCard(
                    icon: Icons.people,
                    title: 'Community Support',
                    description: 'Connect with other mothers on their journey',
                    color: AppTheme.lightSecondary,
                  ),
                  DS.gapXXL,
                  DS.gapXL,
                  
                  // CTAs
                  DS.cta(
                    'Get Started',
                    icon: Icons.arrow_forward,
                    onPressed: () => Navigator.pushNamed(context, Routes.signup),
                  ),
                  DS.gapL,
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
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.lightForeground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
