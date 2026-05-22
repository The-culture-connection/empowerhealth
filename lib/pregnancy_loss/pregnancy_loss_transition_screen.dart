import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../widgets/feature_session_scope.dart';
import 'pregnancy_loss_navigation.dart';
import 'pregnancy_loss_preferences_screen.dart';
import 'pregnancy_loss_service.dart';
import 'pregnancy_loss_theme.dart';

/// Gentle transition after selecting pregnancy loss on emotional check-in.
class PregnancyLossTransitionScreen extends StatefulWidget {
  const PregnancyLossTransitionScreen({super.key});

  @override
  State<PregnancyLossTransitionScreen> createState() =>
      _PregnancyLossTransitionScreenState();
}

class _PregnancyLossTransitionScreenState
    extends State<PregnancyLossTransitionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PregnancyLossService.instance.logTransitionViewed();
    });
  }

  Future<void> _showSupport() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const PregnancyLossPreferencesScreen(),
      ),
    );
    if (!mounted) return;
    finishPregnancyLossOnboarding(context);
  }

  void _skipForNow() {
    finishPregnancyLossOnboarding(context);
  }

  @override
  Widget build(BuildContext context) {
    return FeatureSessionScope(
      feature: 'pregnancy-loss',
      entrySource: 'transition',
      child: Scaffold(
        backgroundColor: PregnancyLossTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                Text(
                  'Support after pregnancy loss',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'You\'re not alone. We\'ll adjust your support experience so it feels more supportive and relevant to where you are right now.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                    height: 1.55,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showSupport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: AppTheme.brandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Show me support'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _skipForNow,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: PregnancyLossTheme.borderSoft.withValues(alpha: 0.8),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Skip for now'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'You can update this later in your profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w300,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
