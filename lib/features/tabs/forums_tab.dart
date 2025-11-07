import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class ForumsTab extends StatelessWidget {
  const ForumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      body: Column(
        children: [
          DS.heroHeader(
            context: context,
            title: 'Community Forums',
            subtitle: 'Connect with other mothers',
            backgroundImage: backgroundImage,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              children: [
                // Category tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip('All Topics', isSelected: true),
                      _CategoryChip('Pregnancy'),
                      _CategoryChip('Birth Planning'),
                      _CategoryChip('Postpartum'),
                      _CategoryChip('Support'),
                    ],
                  ),
                ),
                DS.gapL,
                
                // Forum posts
                DS.messageTile(
                  title: 'How did you prep for GDM test?',
                  subtitle: '12 replies • Last active 5 min ago',
                  avatarText: 'M',
                  onTap: () {},
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.forum, size: 20, color: AppTheme.lightPrimary),
                      const SizedBox(height: 4),
                      Text(
                        '12',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightForeground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                DS.messageTile(
                  title: 'Birth plan templates to share?',
                  subtitle: '24 replies • Last active 1 hour ago',
                  avatarText: 'S',
                  onTap: () {},
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.forum, size: 20, color: AppTheme.lightPrimary),
                      const SizedBox(height: 4),
                      Text(
                        '24',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightForeground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                DS.messageTile(
                  title: 'Questions to ask at first appointment?',
                  subtitle: '18 replies • Last active 2 hours ago',
                  avatarText: 'K',
                  onTap: () {},
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.forum, size: 20, color: AppTheme.lightPrimary),
                      const SizedBox(height: 4),
                      Text(
                        '18',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightForeground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                DS.messageTile(
                  title: 'Doula recommendations?',
                  subtitle: '31 replies • Last active 5 hours ago',
                  avatarText: 'A',
                  onTap: () {},
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.forum, size: 20, color: AppTheme.lightPrimary),
                      const SizedBox(height: 4),
                      Text(
                        '31',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightForeground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                DS.messageTile(
                  title: 'Hospital bag essentials',
                  subtitle: '45 replies • Last active yesterday',
                  avatarText: 'L',
                  onTap: () {},
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.forum, size: 20, color: AppTheme.lightPrimary),
                      const SizedBox(height: 4),
                      Text(
                        '45',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightForeground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Create new post
        },
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
        backgroundColor: AppTheme.lightPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CategoryChip(this.label, {this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingS),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {},
        backgroundColor: AppTheme.lightCard,
        selectedColor: AppTheme.lightPrimary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.lightForeground,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
