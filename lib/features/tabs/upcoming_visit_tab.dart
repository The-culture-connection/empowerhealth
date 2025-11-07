import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class UpcomingVisitTab extends StatelessWidget {
  const UpcomingVisitTab({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      body: Column(
        children: [
          DS.heroHeader(
            context: context,
            title: 'Upcoming Visit',
            subtitle: 'Prepare for your appointment',
            backgroundImage: backgroundImage,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              children: [
                // Appointment details card
                Card(
                  color: AppTheme.lightPrimary.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingXL),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 64,
                          color: AppTheme.lightPrimary,
                        ),
                        DS.gapL,
                        const Text(
                          'OB Appointment',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        DS.gapS,
                        Text(
                          'Tuesday, November 12, 2024',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.lightForeground.withOpacity(0.8),
                          ),
                        ),
                        DS.gapXS,
                        const Text(
                          '10:30 AM - 11:15 AM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightPrimary,
                          ),
                        ),
                        DS.gapL,
                        const Divider(),
                        DS.gapL,
                        _InfoRow(
                          icon: Icons.person,
                          label: 'Provider',
                          value: 'Dr. Sarah Martinez, MD',
                        ),
                        DS.gapM,
                        _InfoRow(
                          icon: Icons.location_on,
                          label: 'Location',
                          value: 'Women\'s Health Center\n123 Medical Plaza, Suite 200',
                        ),
                        DS.gapM,
                        _InfoRow(
                          icon: Icons.phone,
                          label: 'Contact',
                          value: '(555) 123-4567',
                        ),
                        DS.gapXL,
                        Row(
                          children: [
                            Expanded(
                              child: DS.secondary(
                                'Get Directions',
                                icon: Icons.directions,
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: DS.cta(
                                'Call Office',
                                icon: Icons.phone,
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                DS.gapXL,
                
                // Preparation checklist
                Text(
                  'Preparation Checklist',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DS.gapM,
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      children: [
                        _ChecklistItem(
                          title: 'Review questions to ask',
                          subtitle: 'Write down any concerns or questions',
                          isCompleted: true,
                        ),
                        const Divider(height: AppTheme.spacingL),
                        _ChecklistItem(
                          title: 'Bring insurance card',
                          subtitle: 'Have your insurance information ready',
                          isCompleted: true,
                        ),
                        const Divider(height: AppTheme.spacingL),
                        _ChecklistItem(
                          title: 'List current medications',
                          subtitle: 'Include vitamins and supplements',
                          isCompleted: false,
                        ),
                        const Divider(height: AppTheme.spacingL),
                        _ChecklistItem(
                          title: 'Prepare symptom log',
                          subtitle: 'Note any symptoms since last visit',
                          isCompleted: false,
                        ),
                      ],
                    ),
                  ),
                ),
                DS.gapXL,
                
                // Questions to ask
                Text(
                  'Suggested Questions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DS.gapM,
                _QuestionCard(
                  question: 'What tests or screenings do I need this trimester?',
                  category: 'Tests & Screenings',
                ),
                _QuestionCard(
                  question: 'Are there any warning signs I should watch for?',
                  category: 'Health & Safety',
                ),
                _QuestionCard(
                  question: 'What should I expect at my next appointment?',
                  category: 'Next Steps',
                ),
                DS.gapXL,
                
                // Recording reminder
                Card(
                  color: AppTheme.lightAccent.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.mic,
                          size: 48,
                          color: AppTheme.lightAccent,
                        ),
                        DS.gapM,
                        const Text(
                          'Record Your Visit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        DS.gapS,
                        Text(
                          'Don\'t forget to record your appointment so you can review important information later.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.lightForeground.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        DS.gapL,
                        DS.cta(
                          'Set up Recording',
                          icon: Icons.fiber_manual_record,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.lightPrimary),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.lightForeground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;

  const _ChecklistItem({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? AppTheme.success : AppTheme.lightBorder,
          size: 24,
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted
                      ? AppTheme.lightForeground.withOpacity(0.5)
                      : AppTheme.lightForeground,
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
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String question;
  final String category;

  const _QuestionCard({
    required this.question,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.lightAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightAccent,
                ),
              ),
            ),
            DS.gapS,
            Text(
              question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
