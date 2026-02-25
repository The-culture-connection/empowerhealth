import 'package:flutter/material.dart';
import '../app_router.dart';
import '../cors/ui_theme.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/Authscreen.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to gradient if image fails to load
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.brandPurple.withOpacity(0.3), AppTheme.brandPurple],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Logo/title at top - responsive and eye-catching
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      children: [
                        Text(
                          'EMPOWERHEALTH',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Primary',
                            fontSize: MediaQuery.of(context).size.width * 0.12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandPurple,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: AppTheme.brandPurple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'WATCH',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Primary',
                            fontSize: MediaQuery.of(context).size.width * 0.12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandPurple,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: AppTheme.brandPurple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Buttons styled to match design (solid brown rectangles)
                  _AuthPrimaryButton(
                    label: 'Sign Up',
                    onTap: () => Navigator.pushNamed(context, Routes.terms),
                  ),
                  const SizedBox(height: 16),
                  _AuthPrimaryButton(
                    label: 'Login',
                    onTap: () => Navigator.pushNamed(context, Routes.login),
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

class _AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AuthPrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
