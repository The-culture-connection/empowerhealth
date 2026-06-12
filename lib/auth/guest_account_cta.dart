import 'package:flutter/material.dart';

import '../app_router.dart';
import '../cors/ui_theme.dart';

/// Full-screen call-to-action shown in place of account-only screens (e.g. the
/// profile tab) when the user is browsing as a guest.
class GuestAccountCta extends StatelessWidget {
  const GuestAccountCta({
    super.key,
    this.title = 'Create your free account',
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline,
                      size: 36, color: AppTheme.brandPurple),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: AppTheme.brandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.terms),
                    child: const Text('Create account'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.brandPurple,
                      side: BorderSide(color: AppTheme.brandPurple),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.login),
                    child: const Text('Log in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
