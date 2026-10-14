import 'package:flutter/material.dart';

import '../design_system/hearth.dart';
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
              // Loss mode is calm, so the tab header drops its warm circle.
              const SliverToBoxAdapter(
                child: HearthTabHeader(
                  warmCircle: false,
                  title: 'Support after pregnancy loss',
                  subtitle:
                      'Practical, plain-language guides about recovery, visits, terminology, and follow-up care.',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final topic = kPregnancyLossLearningTopics[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HearthCard(
                          onTap: () {
                            PregnancyLossService.instance
                                .logModuleOpened(topic.id);
                            openPregnancyLossLearningTopic(context, topic);
                          },
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HearthIconChip(topic.listIcon),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic.title,
                                      style: hearthCardTitleStyle,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      topic.subtitle,
                                      style: hearthCardBodyStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
