import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedTrimester = 'general';
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

  // Helper to get icon for module
  IconData _getModuleIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('right') || lowerTitle.contains('advocacy')) return Icons.scale;
    if (lowerTitle.contains('nutrition') || lowerTitle.contains('food') || lowerTitle.contains('eat')) return Icons.restaurant;
    if (lowerTitle.contains('medication') || lowerTitle.contains('medicine')) return Icons.medication;
    if (lowerTitle.contains('mental') || lowerTitle.contains('emotional') || lowerTitle.contains('wellbeing')) return Icons.favorite;
    if (lowerTitle.contains('birth') || lowerTitle.contains('labor') || lowerTitle.contains('delivery')) return Icons.child_care;
    if (lowerTitle.contains('risk') || lowerTitle.contains('prenatal')) return Icons.shield;
    return Icons.book_outlined;
  }

  // Helper to get color for module
  Map<String, Color> _getModuleColors(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('right') || lowerTitle.contains('advocacy')) {
      return {'bg': Colors.red.shade50, 'icon': Colors.red.shade600};
    }
    if (lowerTitle.contains('nutrition') || lowerTitle.contains('food')) {
      return {'bg': Colors.green.shade50, 'icon': Colors.green.shade600};
    }
    if (lowerTitle.contains('medication')) {
      return {'bg': Colors.green.shade50, 'icon': Colors.green.shade600};
    }
    if (lowerTitle.contains('mental') || lowerTitle.contains('emotional')) {
      return {'bg': Colors.purple.shade50, 'icon': const Color(0xFF663399)};
    }
    if (lowerTitle.contains('risk') || lowerTitle.contains('prenatal')) {
      return {'bg': Colors.amber.shade50, 'icon': Colors.amber.shade600};
    }
    return {'bg': Colors.blue.shade50, 'icon': Colors.blue.shade500};
  }

  String _normalizeTrimester(String? trimester) {
    if (trimester == null) return 'general';
    final lower = trimester.toLowerCase();
    if (lower.contains('first') || lower.contains('1')) return 'first';
    if (lower.contains('second') || lower.contains('2')) return 'second';
    if (lower.contains('third') || lower.contains('3')) return 'third';
    return 'general';
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    
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

              // Continue Learning Section - Show most recent module
              StreamBuilder<QuerySnapshot>(
                stream: userId != null
                    ? FirebaseFirestore.instance
                        .collection('learning_tasks')
                        .where('userId', isEqualTo: userId)
                        .where('isGenerated', isEqualTo: true)
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .snapshots()
                    : null,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final doc = snapshot.data!.docs.first;
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '').toString();
                    final description = (data['description'] ?? '').toString();
                    final content = data['content'];
                    final contentString = content is String ? content : (content is Map ? content.toString() : '');
                    final colors = _getModuleColors(title);
                    final icon = _getModuleIcon(title);
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
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
                        child: InkWell(
                          onTap: () {
                            if (contentString.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LearningModuleDetailScreen(
                                    title: title,
                                    content: contentString,
                                    icon: '📚',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(icon, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'IN PROGRESS',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      description.isNotEmpty ? description : 'Continue your learning journey',
                                      style: const TextStyle(
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
                    );
                  }
                  // Fallback to Know Your Rights if no modules
                  return Padding(
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
                  );
                },
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

              // Generated Learning Modules List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: userId != null
                      ? FirebaseFirestore.instance
                          .collection('learning_tasks')
                          .where('userId', isEqualTo: userId)
                          .where('isGenerated', isEqualTo: true)
                          .orderBy('createdAt', descending: true)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF663399), Color(0xFF8855BB)],
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Icon(
                                  Icons.book_outlined,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No Learning Modules Yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Generate personalized learning modules from the Home screen',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final tasks = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final taskTrimester = _normalizeTrimester(data['trimester']?.toString());
                      return _selectedTrimester == 'general' || taskTrimester == _selectedTrimester;
                    }).toList();

                    if (tasks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No modules for selected trimester',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final doc = tasks[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '').toString();
                        final description = (data['description'] ?? '').toString();
                        final content = data['content'];
                        final contentString = content is String ? content : (content is Map ? content.toString() : '');
                        final colors = _getModuleColors(title);
                        final icon = _getModuleIcon(title);

                        // Check if completed
                        final isCompleted = data['isCompleted'] ?? false;
                        final progress = isCompleted ? 100 : (data['progress'] ?? 0);

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
                              if (contentString.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LearningModuleDetailScreen(
                                      title: title,
                                      content: contentString,
                                      icon: '📚',
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
                                      color: colors['bg']!,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: colors['icon']!,
                                      size: 24,
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
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          description.isNotEmpty ? description : 'Learning module',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (progress > 0) ...[
                                          const SizedBox(height: 12),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: progress / 100,
                                              backgroundColor: Colors.grey.shade100,
                                              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF663399)),
                                              minHeight: 6,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$progress% complete',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                        if (progress == 0 && contentString.isEmpty) ...[
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () {
                                              // Generate module - could trigger generation
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Start learning →',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF663399),
                                              ),
                                            ),
                                          ),
                                        ],
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
                    );
                  },
                ),
              ),

              // Resources Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade50, Colors.pink.shade50],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.pink.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plain Language Promise',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All our content is written at a 6th grade reading level. No confusing medical jargon—just clear, supportive guidance that helps you understand your care.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
