import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../widgets/feature_session_scope.dart';
import 'pregnancy_loss_learning_topics.dart';
import 'pregnancy_loss_service.dart';

/// Pregnancy-loss-only learning list (no standard pregnancy milestones).
class PregnancyLossLearningScreen extends StatelessWidget {
  const PregnancyLossLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureSessionScope(
      feature: 'pregnancy-loss',
      entrySource: 'learning',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support after pregnancy loss',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Practical, plain-language guides about recovery, visits, terminology, and follow-up care.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final topic = kPregnancyLossLearningTopics[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Material(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            onTap: () {
                              PregnancyLossService.instance
                                  .logModuleOpened(topic.id);
                              openPregnancyLossLearningTopic(context, topic);
                            },
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandPurple
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          topic.listIcon,
                                          color: AppTheme.brandPurple,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                  Text(
                                    topic.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    topic.subtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w300,
                                      height: 1.45,
                                    ),
                                  ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: kPregnancyLossLearningTopics.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
