import 'package:flutter/material.dart';
import '../app_router.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../services/auth_service.dart';
import '../widgets/feature_session_scope.dart';
import 'auth_error_messages.dart';
import 'terms_and_conditions_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  /// Guest entry: show the Terms/EULA first (Guideline 1.2 requires the EULA
  /// before entering), then sign in anonymously and open the app so guests can
  /// browse non-account features without registering (Guideline 5.1.1(v)).
  void _continueAsGuest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TermsAndConditionsScreen(
          acceptLabel: 'Agree & Continue',
          onAccept: (termsContext) async {
            showDialog(
              context: termsContext,
              barrierDismissible: false,
              builder: (_) =>
                  const Center(child: CircularProgressIndicator()),
            );
            try {
              await AuthService().signInAnonymously();
              if (!termsContext.mounted) return;
              Navigator.of(termsContext).pushNamedAndRemoveUntil(
                Routes.main,
                (route) => false,
              );
            } catch (e) {
              if (!termsContext.mounted) return;
              Navigator.of(termsContext).pop(); // dismiss loader
              ScaffoldMessenger.of(termsContext).showSnackBar(
                SnackBar(
                  content: Text(
                    'We couldn\'t start guest mode. ${AuthErrorMessages.forError(e)}',
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeatureSessionScope(
      feature: 'authentication-onboarding',
      entrySource: 'auth_landing',
      child: Scaffold(
        backgroundColor: AppTheme.ground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                // Scales down rather than wrapping mid-word on narrow phones.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    children: [
                      Text(
                        'EmpowerHealth',
                        textAlign: TextAlign.center,
                        style: _wordmarkStyle,
                      ),
                      Text(
                        'Watch',
                        textAlign: TextAlign.center,
                        style: _wordmarkStyle,
                      ),
                      const SizedBox(
                        width: 104,
                        height: 10,
                        child: CustomPaint(painter: _GoldSwashPainter()),
                      ),
                    ],
                  ),
                ),
              ),
              const Expanded(child: _ArchPhoto()),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthPrimaryButton(
                      label: 'Sign Up',
                      onTap: () => Navigator.pushNamed(context, Routes.terms),
                    ),
                    const SizedBox(height: 12),
                    _AuthPrimaryButton(
                      label: 'Login',
                      onTap: () => Navigator.pushNamed(context, Routes.login),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _continueAsGuest(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.brandPurple,
                        backgroundColor: AppTheme.surface,
                        minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: const StadiumBorder(
                          side: BorderSide(color: AppTheme.borderWarm),
                        ),
                      ),
                      child: const Text('Explore as Guest'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const TextStyle _wordmarkStyle = TextStyle(
  fontFamily: AppTheme.serifFamily,
  fontSize: 40,
  height: 46 / 40,
  fontWeight: FontWeight.w400,
  color: AppTheme.ink,
);

/// The welcome photo in an arch frame. Falls back to the warm tint with an
/// image glyph if the asset is missing.
class _ArchPhoto extends StatelessWidget {
  const _ArchPhoto();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final top = Radius.circular(constraints.maxWidth / 2);
          return ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: top,
              topRight: top,
              bottomLeft: const Radius.circular(24),
              bottomRight: const Radius.circular(24),
            ),
            child: Image.asset(
              'assets/Authscreen.jpeg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: AppTheme.tintWarm,
                  child: Center(
                    child: HearthIconChip(
                      Icons.image_outlined,
                      tone: HearthChipTone.surface,
                      size: 72,
                      iconSize: 28,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Hand-drawn gold underline beneath "Watch".
class _GoldSwashPainter extends CustomPainter {
  const _GoldSwashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 96;
    final path = Path()
      ..moveTo(2 * sx, 7)
      ..cubicTo(20 * sx, 1, 38 * sx, 1, 54 * sx, 5)
      ..cubicTo(70 * sx, 9, 82 * sx, 8, 94 * sx, 3);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.brandGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AuthPrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // The theme's 52px minimum (not a fixed box) keeps descenders from
    // clipping at large text sizes.
    return HearthButton.primary(label: label, onPressed: onTap);
  }
}
