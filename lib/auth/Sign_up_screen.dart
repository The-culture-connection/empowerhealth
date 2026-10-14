import 'package:flutter/material.dart';
import '../widgets/feature_session_scope.dart';
import '../app_router.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'auth_error_messages.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showAuthError(Object e, {String fallback = AuthErrorMessages.generic}) {
    if (AuthErrorMessages.isUserCancellation(e)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AuthErrorMessages.forError(e, fallback: fallback)),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        final hasProfile = await _databaseService.userProfileExists(user.uid);
        if (mounted) {
          if (hasProfile) {
            Navigator.pushReplacementNamed(context, Routes.main);
          } else {
            Navigator.pushReplacementNamed(context, Routes.profileCreation);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showAuthError(e, fallback: AuthErrorMessages.googleFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithApple();
      if (user != null && mounted) {
        final hasProfile = await _databaseService.userProfileExists(user.uid);
        if (mounted) {
          if (hasProfile) {
            Navigator.pushReplacementNamed(context, Routes.main);
          } else {
            Navigator.pushReplacementNamed(context, Routes.profileCreation);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showAuthError(e, fallback: AuthErrorMessages.appleFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // Upgrades an anonymous guest in place (preserving UID/analytics) or
      // registers a fresh account when there's no guest session.
      final user = await _authService.linkEmailToGuest(
        _email.text.trim(),
        _password.text,
      );

      if (user != null) {
        if (mounted) {
          // Navigate to profile creation
          Navigator.pushReplacementNamed(context, Routes.profileCreation);
        }
      }
    } catch (e) {
      if (mounted) {
        _showAuthError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FeatureSessionScope(
      feature: 'authentication-onboarding',
      entrySource: 'sign_up',
      child: Scaffold(
        backgroundColor: AppTheme.ground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: HearthCard(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Center(
                          child: Column(
                            children: [
                              const HearthIconChip(
                                Icons.favorite_border,
                                size: 72,
                                iconSize: 32,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: textTheme.displaySmall,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Start your empowered pregnancy journey',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.sansFamily,
                                  fontSize: 14,
                                  height: 21 / 14,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Email field
                        _AuthField(
                          label: 'Email',
                          child: TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              fillColor: AppTheme.surfaceInset,
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.keyboard_hide,
                                  color: AppTheme.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => FocusScope.of(context).unfocus(),
                                tooltip: 'Dismiss keyboard',
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password field
                        _AuthField(
                          label: 'Password',
                          child: TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: InputDecoration(
                              fillColor: AppTheme.surfaceInset,
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.keyboard_hide,
                                  color: AppTheme.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => FocusScope.of(context).unfocus(),
                                tooltip: 'Dismiss keyboard',
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sign up button
                        HearthButton.primary(
                          label: 'Create Account',
                          onPressed: _isLoading ? null : _signUp,
                          loading: _isLoading,
                        ),
                        const SizedBox(height: 24),
                        // Divider
                        const Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppTheme.borderWarm,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  fontFamily: AppTheme.sansFamily,
                                  fontSize: 14,
                                  height: 21 / 14,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppTheme.borderWarm,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Google button
                        HearthButton.secondary(
                          label: 'Continue with Google',
                          icon: Icons.g_mobiledata,
                          onPressed: _isLoading ? null : _signInWithGoogle,
                        ),
                        const SizedBox(height: 12),
                        // Apple button
                        HearthButton.secondary(
                          label: 'Continue with Apple',
                          icon: Icons.apple,
                          onPressed: _isLoading ? null : _signInWithApple,
                        ),
                        const SizedBox(height: 24),
                        // Login link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textMuted,
                            ),
                            child: Text.rich(
                              const TextSpan(
                                style: TextStyle(
                                  fontFamily: AppTheme.sansFamily,
                                  fontSize: 14,
                                  height: 21 / 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textMuted,
                                ),
                                children: [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign in',
                                    style: TextStyle(
                                      color: AppTheme.brandPurple,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Field label above its input, as Hearth forms show it.
class _AuthField extends StatelessWidget {
  const _AuthField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
