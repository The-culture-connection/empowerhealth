import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_router.dart';
import '../cors/ui_theme.dart';

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

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Icon(Icons.lock_outline, size: 36, color: AppTheme.brandPurple),
          const SizedBox(height: 12),
          Text(
            'Create a free account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re exploring as a guest. Create a free account to $action and '
            'save your progress. You can keep browsing without one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: AppTheme.brandWhite,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(Routes.terms);
            },
            child: const Text('Create account'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Maybe later',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
