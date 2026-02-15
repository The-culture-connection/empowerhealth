import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/learning_module.dart';
import '../../services/ai_service.dart';
import '../../cors/ui_theme.dart';
import 'learning_module_detail_screen.dart';

class LearningModulesScreenV2 extends StatefulWidget {
  const LearningModulesScreenV2({super.key});

  @override
  State<LearningModulesScreenV2> createState() => _LearningModulesScreenV2State();
}

class _LearningModulesScreenV2State extends State<LearningModulesScreenV2> {
  final AIService _aiService = AIService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _filterType = 'all'; // 'all' or 'archived'

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

  String _formatMapContentToMarkdown(Map<String, dynamic> contentMap) {
    final buffer = StringBuffer();
    final sections = [
      {'key': 'whatThisIs', 'title': 'What This Is'},
      {'key': 'whyItMatters', 'title': 'Why It Matters for Your Health'},
      {'key': 'whatToExpect', 'title': 'What to Expect'},
      {'key': 'whatYouCanAsk', 'title': 'What You Can Ask or Say'},
      {'key': 'risksOptionsAlternatives', 'title': 'Risks, Options, and Alternatives'},
      {'key': 'whenToSeekHelp', 'title': 'When to Seek Medical Help'},
      {'key': 'empowermentConnection', 'title': 'How This Connects to Your Empowerment'},
      {'key': 'keyPoints', 'title': 'Key Points'},
      {'key': 'yourRights', 'title': 'Your Rights'},
      {'key': 'insuranceNotes', 'title': 'Insurance Notes'},
    ];

    for (final section in sections) {
      final key = section['key']!;
      final title = section['title']!;
      final value = contentMap[key];
      
      if (value != null) {
        String valueStr = '';
        if (value is String) {
          valueStr = value;
        } else if (value is List) {
          valueStr = value.map((e) => e.toString()).join('\n• ');
          if (valueStr.isNotEmpty) valueStr = '• $valueStr';
        } else {
          valueStr = value.toString();
        }
        
        if (valueStr.trim().isNotEmpty) {
          buffer.writeln('## $title');
          buffer.writeln(valueStr);
          buffer.writeln();
        }
      }
    }

    return buffer.toString().isEmpty ? contentMap.toString() : buffer.toString();
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

              // Filter Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _filterType == 'all',
                      onTap: () => setState(() => _filterType = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Archived',
                      isSelected: _filterType == 'archived',
                      onTap: () => setState(() => _filterType = 'archived'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                      final isArchived = data['isArchived'] ?? false;
                      if (_filterType == 'archived') {
                        return isArchived == true;
                      }
                      return isArchived != true;
                    }).toList();

                    if (tasks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            _filterType == 'archived' 
                                ? 'No archived modules'
                                : 'No learning modules yet',
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

                        // Check if completed and archived
                        final isCompleted = data['isCompleted'] ?? false;
                        final isArchived = data['isArchived'] ?? false;
                        final taskId = doc.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isArchived ? Colors.grey.shade300 : Colors.grey.shade100,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: isArchived ? 0.6 : 1.0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                if (contentString.isNotEmpty) {
                                  // Convert Map content to formatted string if needed
                                  String formattedContent = contentString;
                                  if (content is Map) {
                                    formattedContent = _formatMapContentToMarkdown(content as Map<String, dynamic>);
                                  } else if (contentString.startsWith('{') || contentString.contains('whatThisIs')) {
                                    // Already handled in detail screen
                                    formattedContent = contentString;
                                  }
                                  
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LearningModuleDetailScreen(
                                        title: title,
                                        content: formattedContent,
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
                                    // Checkbox
                                    Checkbox(
                                      value: isCompleted,
                                      onChanged: isArchived ? null : (value) async {
                                        if (value == true) {
                                          // When checked, mark as completed and archive
                                          await doc.reference.update({
                                            'isCompleted': true,
                                            'isArchived': true,
                                          });
                                        } else {
                                          // When unchecked, unmark as completed and unarchive
                                          await doc.reference.update({
                                            'isCompleted': false,
                                            'isArchived': false,
                                          });
                                        }
                                      },
                                      activeColor: const Color(0xFF663399),
                                    ),
                                    const SizedBox(width: 12),
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
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: isArchived ? Colors.grey[500] : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              if (isArchived)
                                                const Icon(
                                                  Icons.archive,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            description.isNotEmpty ? description : 'Learning module',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isArchived ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                          if (!isArchived && !isCompleted)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: () async {
                                                    await doc.reference.update({
                                                      'isCompleted': true,
                                                      'isArchived': true,
                                                    });
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: const Text(
                                                    'Mark Done & Archive',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF663399),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (isCompleted && !isArchived)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: () async {
                                                    await doc.reference.update({'isArchived': true});
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: Text(
                                                    'Archive',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
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
                          ),
                        );
                      },
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
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
