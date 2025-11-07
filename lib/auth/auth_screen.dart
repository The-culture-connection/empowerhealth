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
          Image.asset('assets/Authscreen.jpeg', fit: BoxFit.cover),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo/title at top in cursive-like style
                  Text(
                    'EmpowerHealth',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      // Use the provided Primary font for titles
                      fontFamily: 'Primary',
                      fontSize: 80,
                      fontWeight: FontWeight.w500,
                    ).copyWith(color: AppTheme.brandBrown),
                  ),
                  const Spacer(),
                  // Buttons styled to match design (solid brown rectangles)
                  _AuthPrimaryButton(
                    label: 'Sign Up',
                    onTap: () => Navigator.pushNamed(context, Routes.signup),
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
          backgroundColor: AppTheme.brandBrown,
          foregroundColor: AppTheme.brandBlack,
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
