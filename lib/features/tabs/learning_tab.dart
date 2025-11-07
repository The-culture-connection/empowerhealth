import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class LearningTab extends StatelessWidget {
  const LearningTab({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      body: Column(
        children: [
          DS.heroHeader(
            context: context,
            title: 'Learning Center',
            subtitle: 'Empowering knowledge for your journey',
            backgroundImage: backgroundImage,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              children: [
                Text(
                  'Featured Courses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DS.gapM,
                _LearningCard(
                  title: 'Birth Plan Basics',
                  subtitle: 'Understand your options and preferences',
                  duration: '15 min',
                  progress: 0.6,
                  icon: Icons.description_outlined,
                  color: AppTheme.lightPrimary,
                  onTap: () {},
                ),
                _LearningCard(
                  title: 'Understanding Lab Results',
                  subtitle: 'Learn what your tests mean',
                  duration: '10 min',
                  progress: 0.0,
                  icon: Icons.science_outlined,
                  color: AppTheme.lightAccent,
                  onTap: () {},
                ),
                _LearningCard(
                  title: 'Warning Signs to Watch',
                  subtitle: 'When to call your provider',
                  duration: '8 min',
                  progress: 1.0,
                  icon: Icons.warning_amber_outlined,
                  color: AppTheme.warning,
                  onTap: () {},
                ),
                DS.gapXL,
                
                Text(
                  'By Topic',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DS.gapM,
                Wrap(
                  spacing: AppTheme.spacingM,
                  runSpacing: AppTheme.spacingM,
                  children: [
                    _TopicChip(
                      label: 'Prenatal Care',
                      icon: Icons.pregnant_woman,
                      color: AppTheme.lightPrimary,
                    ),
                    _TopicChip(
                      label: 'Nutrition',
                      icon: Icons.restaurant,
                      color: AppTheme.lightAccent,
                    ),
                    _TopicChip(
                      label: 'Exercise',
                      icon: Icons.fitness_center,
                      color: AppTheme.success,
                    ),
                    _TopicChip(
                      label: 'Mental Health',
                      icon: Icons.psychology,
                      color: AppTheme.lightSecondary,
                    ),
                    _TopicChip(
                      label: 'Labor & Delivery',
                      icon: Icons.local_hospital,
                      color: AppTheme.lightPrimary,
                    ),
                    _TopicChip(
                      label: 'Postpartum',
                      icon: Icons.child_care,
                      color: AppTheme.lightAccent,
                    ),
                  ],
                ),
                DS.gapXL,
                
                Text(
                  'Recent Articles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DS.gapM,
                DS.messageTile(
                  title: 'Managing Morning Sickness',
                  subtitle: 'Tips and remedies that really work • 5 min read',
                  avatarText: '📖',
                  onTap: () {},
                ),
                DS.messageTile(
                  title: 'Your Third Trimester Checklist',
                  subtitle: 'Essential preparations for baby\'s arrival • 8 min read',
                  avatarText: '📖',
                  onTap: () {},
                ),
                DS.messageTile(
                  title: 'Understanding Ultrasound Results',
                  subtitle: 'What the measurements mean • 6 min read',
                  avatarText: '📖',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String duration;
  final double progress;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LearningCard({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.progress,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.lightForeground.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (progress > 0 && progress < 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightAccent,
                            ),
                          ),
                        ),
                      if (progress == 1.0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 12, color: AppTheme.success),
                              SizedBox(width: 4),
                              Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        duration,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightForeground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (progress > 0 && progress < 1) ...[
                const SizedBox(height: AppTheme.spacingM),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.lightMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TopicChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
