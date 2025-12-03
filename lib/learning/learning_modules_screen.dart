import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import '../cors/ui_theme.dart';
import 'module_detail_screen.dart';

class LearningModulesScreen extends StatefulWidget {
  const LearningModulesScreen({super.key});

  @override
  State<LearningModulesScreen> createState() => _LearningModulesScreenState();
}

class _LearningModulesScreenState extends State<LearningModulesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserProfile? _userProfile;

  // Predefined learning topics for each trimester
  final Map<String, List<Map<String, String>>> _topics = {
    'First': [
      {'title': 'Early Pregnancy Signs', 'type': 'basic'},
      {'title': 'Prenatal Vitamins', 'type': 'basic'},
      {'title': 'First Doctor Visit', 'type': 'basic'},
      {'title': 'Morning Sickness', 'type': 'basic'},
      {'title': 'Know Your Rights', 'type': 'rights'},
    ],
    'Second': [
      {'title': 'Baby Development', 'type': 'basic'},
      {'title': 'Nutrition Guide', 'type': 'basic'},
      {'title': 'Exercise Safety', 'type': 'basic'},
      {'title': 'Ultrasound Explained', 'type': 'basic'},
      {'title': 'Know Your Rights', 'type': 'rights'},
    ],
    'Third': [
      {'title': 'Labor Signs', 'type': 'basic'},
      {'title': 'Hospital Bag Checklist', 'type': 'basic'},
      {'title': 'Pain Management Options', 'type': 'basic'},
      {'title': 'Birth Plan Basics', 'type': 'basic'},
      {'title': 'Know Your Rights', 'type': 'rights'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final profile = await _databaseService.getUserProfile(userId);
      setState(() {
        _userProfile = profile;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _currentTrimester {
    switch (_tabController.index) {
      case 0:
        return 'First';
      case 1:
        return 'Second';
      case 2:
        return 'Third';
      default:
        return 'First';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Modules'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('learning_tasks')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No learning modules yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Modules will be generated when you complete your profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return _buildTasksList(snapshot.data!.docs);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomTopicDialog,
        backgroundColor: AppTheme.brandPurple,
        icon: const Icon(Icons.add),
        label: const Text('Add Topic'),
      ),
    );
  }

  Widget _buildTasksList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.check_circle_outline,
              color: AppTheme.brandPurple,
              size: 28,
            ),
            title: Text(
              data['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  data['description'] ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'AI Generated',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModuleDetailScreen(
                    title: data['title'] ?? '',
                    trimester: data['trimester'] ?? 'First',
                    type: 'personalized',
                    preloadedContent: data['content'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModuleList(String trimester) {
    final topics = _topics[trimester] ?? [];
    
    return Column(
      children: [
        // Banked modules
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return _buildModuleCard(
                title: topic['title']!,
                trimester: trimester,
                type: topic['type']!,
                isCustom: false,
              );
            },
          ),
        ),
        
        // User's custom generated modules
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('learning_modules')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .where('trimester', isEqualTo: trimester)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Custom Modules',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildModuleCard(
                      title: data['topic'],
                      trimester: trimester,
                      type: 'custom',
                      isCustom: true,
                      content: data['content'],
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String trimester,
    required String type,
    required bool isCustom,
    String? content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type == 'rights' ? Colors.amber[700] : AppTheme.brandPurple,
          child: Icon(
            type == 'rights' ? Icons.gavel : Icons.book,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(isCustom ? 'AI Generated' : 'Curated Content'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (type == 'rights') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModuleDetailScreen(
                  title: title,
                  trimester: trimester,
                  type: 'rights',
                ),
              ),
            );
          } else if (isCustom && content != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModuleDetailScreen(
                  title: title,
                  trimester: trimester,
                  type: type,
                  preloadedContent: content,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModuleDetailScreen(
                  title: title,
                  trimester: trimester,
                  type: type,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showCustomTopicDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Custom Learning Module'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What would you like to learn about?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Gestational diabetes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final topic = controller.text.trim();
              if (topic.isEmpty) return;
              
              Navigator.pop(context);
              _generateCustomModule(topic);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateCustomModule(String topic) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating your custom module...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Prepare user profile data for personalization
      Map<String, dynamic>? profileData;
      if (_userProfile != null) {
        profileData = {
          'chronicConditions': _userProfile!.chronicConditions,
          'healthLiteracyGoals': _userProfile!.healthLiteracyGoals,
          'insuranceType': _userProfile!.insuranceType,
          'providerPreferences': _userProfile!.providerPreferences,
          'educationLevel': _userProfile!.educationLevel,
        };
      }

      await _functionsService.generateLearningContent(
        topic: topic,
        trimester: _currentTrimester,
        moduleType: 'custom',
        userProfile: profileData,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Module created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

