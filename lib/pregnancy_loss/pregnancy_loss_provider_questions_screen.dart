import 'package:flutter/material.dart';

import '../app_router.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../widgets/feature_session_scope.dart';
import 'pregnancy_loss_constants.dart';

/// Gentle provider question prompts with journal shortcut.
class PregnancyLossProviderQuestionsScreen extends StatelessWidget {
  const PregnancyLossProviderQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureSessionScope(
      feature: 'pregnancy-loss',
      entrySource: 'provider_questions',
      child: Scaffold(
        backgroundColor: AppTheme.ground,
        body: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: HearthPushedHeader(
                  onBack: () => Navigator.pop(context),
                  title: 'Questions to ask my provider',
                  subtitle:
                      'You can save these in your journal or bring them to your next visit. There is no rush.',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ...kPregnancyLossProviderPrompts.map(
                      (q) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HearthCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 20,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              q,
                              style: hearthCardBodyStyle.copyWith(
                                fontSize: 15,
                                height: 22 / 15,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    HearthButton.primary(
                      onPressed: () {
                        if (!MainNavigationScope.goToTab(
                          context,
                          MainNavigationScope.tabJournal,
                        )) {
                          Navigator.pushNamed(context, Routes.journal);
                        }
                      },
                      icon: Icons.edit_outlined,
                      label: 'Open journal to save notes',
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
