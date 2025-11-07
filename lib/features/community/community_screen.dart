import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background image - stays in place
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightBackground,
              ),
              child: backgroundImage != null
                  ? Image.asset(
                      backgroundImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.lightBackground,
                                AppTheme.lightMuted,
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.lightBackground,
                            AppTheme.lightMuted,
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Most recent message header
                  Text(
                    'Most Recent Messages',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  DS.gapM,
                  
                  // Message cards
                  DS.messageTile(
                    title: 'How did you prep for GDM test?',
                    subtitle: 'Looking for advice on preparing for my glucose screening test next week. Any tips?',
                    avatarText: 'M',
                    onTap: () {},
                  ),
                  DS.messageTile(
                    title: 'Birth plan templates',
                    subtitle: 'Does anyone have a good birth plan template they\'d recommend?',
                    avatarText: 'S',
                    onTap: () {},
                  ),
                  DS.messageTile(
                    title: 'Morning sickness remedies',
                    subtitle: 'What worked best for you during the first trimester?',
                    avatarText: 'J',
                    onTap: () {},
                  ),
                  DS.messageTile(
                    title: 'Exercise during pregnancy',
                    subtitle: 'Safe exercises for second trimester?',
                    avatarText: 'A',
                    onTap: () {},
                  ),
                  DS.gapXL,
                  
                  // Popular topics
                  Text(
                    'Popular Topics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  DS.gapM,
                  
                  Wrap(
                    spacing: AppTheme.spacingS,
                    runSpacing: AppTheme.spacingS,
                    children: [
                      _TopicChip(label: 'Nutrition'),
                      _TopicChip(label: 'Exercise'),
                      _TopicChip(label: 'Preparing for Birth'),
                      _TopicChip(label: 'Baby Gear'),
                      _TopicChip(label: 'Health Concerns'),
                      _TopicChip(label: 'Support Groups'),
                    ],
                  ),
                  DS.gapXL,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;

  const _TopicChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppTheme.lightAccent.withOpacity(0.1),
      labelStyle: const TextStyle(
        color: AppTheme.lightAccent,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (selected) {
        // TODO: Filter by topic
      },
    );
  }
}
