import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../widgets/feature_session_scope.dart';
import 'pregnancy_loss_navigation.dart';
import 'pregnancy_loss_preferences_screen.dart';
import 'pregnancy_loss_service.dart';

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
    final textTheme = Theme.of(context).textTheme;
    return FeatureSessionScope(
      feature: 'pregnancy-loss',
      entrySource: 'transition',
      child: Scaffold(
        backgroundColor: AppTheme.ground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                Text(
                  'Support after pregnancy loss',
                  style: textTheme.displayLarge,
                ),
                const SizedBox(height: 18),
                Text(
                  'You\'re not alone. We\'ll adjust your support experience so it feels more supportive and relevant to where you are right now.',
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 25 / 16,
                  ),
                ),
                const Spacer(flex: 3),
                HearthButton.primary(
                  label: 'Show me support',
                  onPressed: _showSupport,
                ),
                const SizedBox(height: 12),
                HearthButton.secondary(
                  label: 'Skip for now',
                  onPressed: _skipForNow,
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'You can update this later in your profile.',
                    textAlign: TextAlign.center,
                    style: hearthCaptionStyle,
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
