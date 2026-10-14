import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_router.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

/// Gates account-only actions for guests (anonymous users) and signed-out users.
///
/// Guests may freely browse non-account features (Guideline 5.1.1(v)), but
/// actions that create or personalize account data — posting, replying,
/// bookmarking, saving progress, messaging, completing assessments — require a
/// real account.
///
/// Returns `true` when the caller may proceed (a real, non-anonymous account is
/// signed in). Otherwise it shows a prompt inviting the user to create a free
/// account and returns `false`, so callers should early-return on `false`:
///
/// ```dart
/// if (!await requireAccount(context, action: 'post in the community')) return;
/// ```
Future<bool> requireAccount(
  BuildContext context, {
  required String action,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  final isRealAccount = user != null && !user.isAnonymous;
  if (isRealAccount) return true;

  await showHearthSheet<void>(
    context: context,
    builder: (ctx) => _CreateAccountPrompt(action: action),
  );
  return false;
}

class _CreateAccountPrompt extends StatelessWidget {
  const _CreateAccountPrompt({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final textTheme = Theme.of(context).textTheme;
    // The sheet shell draws the handle and side padding; this keeps clear of
    // the home indicator.
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: HearthIconChip(Icons.lock_outline)),
          const SizedBox(height: 12),
          Text(
            'Create a free account',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re exploring as a guest. Create a free account to $action and '
            'save your progress. You can keep browsing without one.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          HearthButton.primary(
            label: 'Create account',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(Routes.terms);
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
                textStyle: const TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Maybe later'),
            ),
          ),
        ],
      ),
    );
  }
}
