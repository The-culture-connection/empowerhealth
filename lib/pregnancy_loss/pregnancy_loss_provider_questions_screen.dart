import 'package:flutter/material.dart';

import '../app_router.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
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
        backgroundColor: const Color(0xFFF7F4FA),
        body: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.chevron_left, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Questions to ask my provider',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You can save these in your journal or bring them to your next visit. There is no rush.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...kPregnancyLossProviderPrompts.map(
                      (q) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppTheme.borderLight.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            q,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                              color: AppTheme.textPrimary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (!MainNavigationScope.goToTab(
                            context,
                            MainNavigationScope.tabJournal,
                          )) {
                            Navigator.pushNamed(context, Routes.journal);
                          }
                        },
                        icon: const Icon(Icons.edit_note_outlined, size: 20),
                        label: const Text('Open journal to save notes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPurple,
                          foregroundColor: AppTheme.brandWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
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
