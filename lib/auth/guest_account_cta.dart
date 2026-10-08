import 'package:flutter/material.dart';

import '../app_router.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

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
                const HearthIconChip(
                  Icons.person_outline,
                  size: 72,
                  iconSize: 32,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 16,
                    height: 22 / 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                HearthButton.primary(
                  label: 'Create account',
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.terms),
                ),
                const SizedBox(height: 12),
                HearthButton.secondary(
                  label: 'Log in',
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
