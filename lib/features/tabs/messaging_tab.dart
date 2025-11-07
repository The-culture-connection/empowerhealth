import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class MessagingTab extends StatelessWidget {
  const MessagingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundImage = DS.getRandomBackgroundImage();
    
    return Scaffold(
      body: Column(
        children: [
          DS.heroHeader(
            context: context,
            title: 'Messages',
            subtitle: 'Stay connected with your care team',
            backgroundImage: backgroundImage,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide: const BorderSide(color: AppTheme.lightBorder),
                    ),
                  ),
                ),
                DS.gapL,
                
                // Message threads
                DS.messageTile(
                  title: 'Dr. Martinez',
                  subtitle: 'Your test results are in. Everything looks great! 📊',
                  avatarText: 'DM',
                  onTap: () {},
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '10:30 AM',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.lightPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DS.messageTile(
                  title: 'Doula Sarah',
                  subtitle: 'Let me know if you have any questions about the birth plan.',
                  avatarText: 'DS',
                  onTap: () {},
                  trailing: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Yesterday',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                DS.messageTile(
                  title: 'Nurse Kelly',
                  subtitle: 'Reminder: Take your prenatal vitamins daily',
                  avatarText: 'NK',
                  onTap: () {},
                  trailing: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '2 days ago',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                DS.messageTile(
                  title: 'Dr. Thompson',
                  subtitle: 'Follow-up appointment scheduled for next week',
                  avatarText: 'DT',
                  onTap: () {},
                  trailing: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '3 days ago',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                DS.messageTile(
                  title: 'Lactation Consultant',
                  subtitle: 'Great job today! Here are the resources we discussed.',
                  avatarText: 'LC',
                  onTap: () {},
                  trailing: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Last week',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                DS.gapXL,
                
                // Quick actions card
                Card(
                  color: AppTheme.lightPrimary.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 48,
                          color: AppTheme.lightPrimary,
                        ),
                        DS.gapM,
                        const Text(
                          'Secure Messaging',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        DS.gapS,
                        Text(
                          'All messages are HIPAA-compliant and encrypted for your privacy.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.lightForeground.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: New message
        },
        backgroundColor: AppTheme.lightPrimary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
    );
  }
}
