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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Learning Center',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Knowledge that empowers your choices',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Trimester selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
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
                ),
              ),
              const SizedBox(height: 20),

              // Quick access to Know Your Rights
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RightsScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF663399), Color(0xFF8855BB)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF663399).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text('⚖️', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IN PROGRESS',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
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
                                'Healthcare advocacy and informed consent',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // All Modules Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'All Topics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Modules List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _bankedModules.where((m) => 
                    _selectedTrimester == 'general' || m['trimester'] == _selectedTrimester
                  ).length,
                  itemBuilder: (context, index) {
                    final filteredModules = _bankedModules.where((m) => 
                      _selectedTrimester == 'general' || m['trimester'] == _selectedTrimester
                    ).toList();
                    final module = filteredModules[index];
                    
                    final iconColors = [
                      Colors.blue.shade50,
                      Colors.green.shade50,
                      Colors.amber.shade50,
                      Colors.purple.shade50,
                      Colors.rose.shade50,
                      Colors.pink.shade50,
                    ];
                    final iconColorValues = [
                      Colors.blue.shade500,
                      Colors.green.shade600,
                      Colors.amber.shade600,
                      const Color(0xFF663399),
                      Colors.pink.shade600,
                      Colors.pink.shade600,
                    ];
                    final colorIndex = index % iconColors.length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          if (module['title'] == 'Know Your Rights') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RightsScreen()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LearningModuleDetailScreen(
                                  title: module['title']!,
                                  content: 'Content for ${module['topic']!}',
                                  icon: module['icon']!,
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: iconColors[colorIndex],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    module['icon']!,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      module['title']!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      module['topic']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF663399) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF663399) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
