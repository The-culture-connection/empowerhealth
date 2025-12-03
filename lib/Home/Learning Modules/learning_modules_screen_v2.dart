import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/learning_module.dart';
import '../../services/ai_service.dart';
import '../../cors/ui_theme.dart';
import 'learning_module_detail_screen.dart';
import 'rights_screen.dart';

class LearningModulesScreenV2 extends StatefulWidget {
  const LearningModulesScreenV2({super.key});

  @override
  State<LearningModulesScreenV2> createState() => _LearningModulesScreenV2State();
}

class _LearningModulesScreenV2State extends State<LearningModulesScreenV2> {
  final AIService _aiService = AIService();
  String _selectedTrimester = 'first';
  bool _isGenerating = false;

  final List<Map<String, String>> _bankedModules = [
    {
      'title': 'Your First Trimester',
      'topic': 'Early Pregnancy Changes',
      'trimester': 'first',
      'icon': '🌱',
    },
    {
      'title': 'Nutrition in Pregnancy',
      'topic': 'Eating Well for You and Baby',
      'trimester': 'first',
      'icon': '🥗',
    },
    {
      'title': 'Know Your Rights',
      'topic': 'Patient Rights in Maternity Care',
      'trimester': 'general',
      'icon': '⚖️',
    },
    {
      'title': 'Your Growing Baby',
      'topic': 'Second Trimester Development',
      'trimester': 'second',
      'icon': '👶',
    },
    {
      'title': 'Staying Active',
      'topic': 'Safe Exercise During Pregnancy',
      'trimester': 'second',
      'icon': '🏃‍♀️',
    },
    {
      'title': 'Getting Ready for Baby',
      'topic': 'Third Trimester Preparation',
      'trimester': 'third',
      'icon': '🎒',
    },
    {
      'title': 'Labor and Delivery',
      'topic': 'What to Expect During Birth',
      'trimester': 'third',
      'icon': '🏥',
    },
    {
      'title': 'Your Mental Health',
      'topic': 'Emotional Wellbeing',
      'trimester': 'general',
      'icon': '💚',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Modules'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Trimester selector
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.brandPurple.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Your Trimester',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _TrimesterChip(
                      label: '1st',
                      isSelected: _selectedTrimester == 'first',
                      onTap: () => setState(() => _selectedTrimester = 'first'),
                    ),
                    const SizedBox(width: 8),
                    _TrimesterChip(
                      label: '2nd',
                      isSelected: _selectedTrimester == 'second',
                      onTap: () => setState(() => _selectedTrimester = 'second'),
                    ),
                    const SizedBox(width: 8),
                    _TrimesterChip(
                      label: '3rd',
                      isSelected: _selectedTrimester == 'third',
                      onTap: () => setState(() => _selectedTrimester = 'third'),
                    ),
                    const SizedBox(width: 8),
                    _TrimesterChip(
                      label: 'All',
                      isSelected: _selectedTrimester == 'general',
                      onTap: () => setState(() => _selectedTrimester = 'general'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick access to Know Your Rights
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RightsScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.brandPurple, AppTheme.brandPurple.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text(
                      '⚖️',
                      style: TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Know Your Rights',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Learn about your rights in maternity care',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),

          // Modules list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _getFilteredModules().length + 1,
              itemBuilder: (context, index) {
                if (index == _getFilteredModules().length) {
                  return _AIGenerateCard();
                }

                final module = _getFilteredModules()[index];
                return _ModuleCard(
                  title: module['title']!,
                  topic: module['topic']!,
                  trimester: module['trimester']!,
                  icon: module['icon']!,
                  onTap: () async {
                    // Generate content for this module
                    setState(() => _isGenerating = true);
                    try {
                      final result = await _aiService.generateLearningContent(
                        topic: module['topic']!,
                        trimester: module['trimester']!,
                        moduleType: 'educational',
                      );

                      if (!mounted) return;
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LearningModuleDetailScreen(
                            title: module['title']!,
                            content: result['content'],
                            icon: module['icon']!,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error loading module: $e')),
                      );
                    } finally {
                      setState(() => _isGenerating = false);
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

  List<Map<String, String>> _getFilteredModules() {
    if (_selectedTrimester == 'general') {
      return _bankedModules;
    }
    return _bankedModules
        .where((m) => m['trimester'] == _selectedTrimester || m['trimester'] == 'general')
        .toList();
  }

  Widget _AIGenerateCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _isGenerating ? null : _showCustomModuleDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask a Question',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Get AI-generated answers to your specific questions',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle, color: AppTheme.brandPurple),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomModuleDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ask Your Question'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'What would you like to learn about?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              
              Navigator.pop(context);
              setState(() => _isGenerating = true);
              
              try {
                final result = await _aiService.generateLearningContent(
                  topic: controller.text.trim(),
                  trimester: _selectedTrimester,
                  moduleType: 'custom',
                );

                if (!mounted) return;
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LearningModuleDetailScreen(
                      title: controller.text.trim(),
                      content: result['content'],
                      icon: '✨',
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              } finally {
                setState(() => _isGenerating = false);
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}

class _TrimesterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrimesterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.brandPurple,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.brandPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String topic;
  final String trimester;
  final String icon;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.topic,
    required this.trimester,
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
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
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
                      topic,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

