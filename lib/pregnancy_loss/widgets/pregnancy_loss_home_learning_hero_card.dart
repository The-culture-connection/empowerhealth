import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
import '../pregnancy_loss_learning_topics.dart';

/// Same visual weight as the home week/trimester card, for loss-mode learning.
class PregnancyLossHomeLearningHeroCard extends StatelessWidget {
  const PregnancyLossHomeLearningHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = pregnancyLossTopicById('understanding_loss') ??
        kPregnancyLossLearningTopics.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openPregnancyLossLearningTopic(context, topic),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF663399),
                Color(0xFF7744AA),
                Color(0xFF8855BB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF663399).withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              Positioned(
                top: -20,
                left: MediaQuery.sizeOf(context).width * 0.2,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD4A574).withValues(alpha: 0.2),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                right: 20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB899D4).withValues(alpha: 0.18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brandWhite.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.brandWhite.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4A574),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Learning guide',
                            style: TextStyle(
                              color: const Color(0xFFF5F0F7),
                              fontSize: 12,
                              letterSpacing: 0.36,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                        letterSpacing: -0.28,
                        color: Color(0xFFF5F0F7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      topic.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        height: 1.5,
                        color: Color(0xFFE8DFF0),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Text(
                          'Open guide',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                            color: const Color(0xFFE8DFF0).withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: const Color(0xFFE8DFF0).withValues(alpha: 0.95),
                        ),
                      ],
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
