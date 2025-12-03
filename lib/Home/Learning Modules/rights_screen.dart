import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../cors/ui_theme.dart';
import 'learning_module_detail_screen.dart';

class RightsScreen extends StatelessWidget {
  const RightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AIService aiService = AIService();

    final List<Map<String, String>> rightsTopics = [
      {
        'title': 'Informed Consent',
        'topic': 'Understanding Informed Consent',
        'icon': '✅',
        'description': 'What you need to know before saying yes to any procedure',
      },
      {
        'title': 'Refusal of Care',
        'topic': 'Your Right to Say No',
        'icon': '🚫',
        'description': 'When and how you can refuse medical treatment',
      },
      {
        'title': 'Birth Preferences',
        'topic': 'Creating Your Birth Plan',
        'icon': '📋',
        'description': 'How to communicate your wishes for labor and delivery',
      },
      {
        'title': 'Support People',
        'topic': 'Having Support During Birth',
        'icon': '👥',
        'description': 'Your right to have people with you during labor',
      },
      {
        'title': 'Pain Relief Options',
        'topic': 'Understanding Pain Management Choices',
        'icon': '💊',
        'description': 'All your options for managing labor pain',
      },
      {
        'title': 'Respectful Care',
        'topic': 'Dignity and Respect in Healthcare',
        'icon': '❤️',
        'description': 'What respectful maternity care looks like',
      },
      {
        'title': 'Medical Records',
        'topic': 'Accessing Your Medical Information',
        'icon': '📄',
        'description': 'How to get copies of your medical records',
      },
      {
        'title': 'Second Opinions',
        'topic': 'Getting Another Doctor\'s View',
        'icon': '👩‍⚕️',
        'description': 'When and how to seek a second opinion',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Know Your Rights'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.brandPurple,
                  AppTheme.brandPurple.withOpacity(0.7),
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚖️',
                  style: TextStyle(fontSize: 48),
                ),
                SizedBox(height: 12),
                Text(
                  'Your Rights Matter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'You have the right to understand, question, and make decisions about your care.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rightsTopics.length,
              itemBuilder: (context, index) {
                final topic = rightsTopics[index];
                return _RightsCard(
                  title: topic['title']!,
                  description: topic['description']!,
                  icon: topic['icon']!,
                  onTap: () async {
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    try {
                      final result = await aiService.generateRightsContent(
                        topic: topic['topic']!,
                      );

                      if (!context.mounted) return;
                      
                      // Close loading dialog
                      Navigator.pop(context);

                      // Show content
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LearningModuleDetailScreen(
                            title: topic['title']!,
                            content: result['content'],
                            icon: topic['icon']!,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RightsCard extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final VoidCallback onTap;

  const _RightsCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

