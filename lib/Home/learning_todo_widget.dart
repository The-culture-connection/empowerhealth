import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import '../cors/ui_theme.dart';
import '../learning/module_detail_screen.dart';

class LearningTodoWidget extends StatefulWidget {
  const LearningTodoWidget({super.key});

  @override
  State<LearningTodoWidget> createState() => _LearningTodoWidgetState();
}

class _LearningTodoWidgetState extends State<LearningTodoWidget> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  List<LearningTask> _tasks = [];
  Set<String> _completedTasks = {};
  
  // Module generation progress
  bool _isGenerating = false;
  int _completedModules = 0;
  int _totalModules = 0;
  StreamSubscription? _generationStatusSubscription;
  StreamSubscription? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenForGenerationStatus();
    _listenForNewTasks();
  }

  @override
  void dispose() {
    _generationStatusSubscription?.cancel();
    _tasksSubscription?.cancel();
    super.dispose();
  }

  void _listenForGenerationStatus() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Listen to user profile for generation status
    _generationStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data();
          // Read flat structure fields
          final isGenerating = data?['moduleGen_isGenerating'] ?? false;
          final completedModules = data?['moduleGen_completedModules'] ?? 0;
          final totalModules = data?['moduleGen_totalModules'] ?? 0;
          
          if (totalModules > 0 || isGenerating) {
            setState(() {
              _isGenerating = isGenerating;
              _completedModules = completedModules;
              _totalModules = totalModules;
            });
          } else {
            // Fallback: calculate from learning tasks count
            _calculateProgressFromTasks();
          }
        }
      },
      onError: (error) {
        // Silently handle network errors from background listeners
        // These are expected when offline or network is unavailable
        print('Background listener error (expected when offline): $error');
      },
    );
  }

  Future<void> _calculateProgressFromTasks() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Count generated tasks created in the last hour (likely from current generation)
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('learning_tasks')
          .where('userId', isEqualTo: userId)
          .where('isGenerated', isEqualTo: true)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();

      final count = tasksSnapshot.docs.length;
      
      // If we have tasks but no status, estimate progress
      if (count > 0 && _totalModules == 0) {
        // Estimate total modules (typically 4-5)
        final estimatedTotal = count < 4 ? 4 : (count < 5 ? 5 : count);
        setState(() {
          _totalModules = estimatedTotal;
          _completedModules = count;
          _isGenerating = count < estimatedTotal;
        });
      }
    } catch (e) {
      print('Error calculating progress from tasks: $e');
    }
  }

  void _listenForNewTasks() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _tasksSubscription = FirebaseFirestore.instance
        .collection('learning_tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        if (mounted) {
      final loadedTasks = snapshot.docs.map((doc) {
        final data = doc.data();
        // Handle content as either String or Map
        final contentData = data['content'];
        final contentString = contentData is String 
            ? contentData 
            : (contentData is Map ? contentData.toString() : null);
        
        // Handle description as either String or Map
        final descData = data['description'];
        final descString = descData is String 
            ? descData 
            : (descData is Map ? descData.toString() : '');
        
        // Handle trimester as either String or dynamic
        final trimData = data['trimester'];
        final trimString = trimData is String 
            ? trimData 
            : (trimData?.toString() ?? 'First');
        
        return LearningTask(
          id: doc.id,
          title: (data['title'] ?? '').toString(),
          description: descString,
          trimester: trimString,
          isGenerated: data['isGenerated'] ?? false,
          moduleId: data['moduleId']?.toString(),
          content: contentString,
        );
      }).toList();

          setState(() {
            _tasks = loadedTasks.isEmpty ? _generateSuggestedTasks() : loadedTasks;
          });
          
          // Calculate progress from tasks if no status available
          if (!_isGenerating && _totalModules == 0) {
            _calculateProgressFromTasks();
          }
        }
      },
      onError: (error) {
        // Silently handle network errors from background listeners
        // These are expected when offline or network is unavailable
        print('Background listener error (expected when offline): $error');
      },
    );
  }

  Future<void> _loadData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Load user profile
      _userProfile = await _databaseService.getUserProfile(userId);
      
      // Load saved tasks from Firestore
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('learning_tasks')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final loadedTasks = tasksSnapshot.docs.map((doc) {
        final data = doc.data();
        // Handle content as either String or Map
        final contentData = data['content'];
        final contentString = contentData is String 
            ? contentData 
            : (contentData is Map ? contentData.toString() : null);
        
        // Handle description as either String or Map
        final descData = data['description'];
        final descString = descData is String 
            ? descData 
            : (descData is Map ? descData.toString() : '');
        
        // Handle trimester as either String or dynamic
        final trimData = data['trimester'];
        final trimString = trimData is String 
            ? trimData 
            : (trimData?.toString() ?? 'First');
        
        return LearningTask(
          id: doc.id,
          title: (data['title'] ?? '').toString(),
          description: descString,
          trimester: trimString,
          isGenerated: data['isGenerated'] ?? false,
          moduleId: data['moduleId']?.toString(),
          content: contentString,
        );
      }).toList();

      // Load completed tasks
      final completedSnapshot = await FirebaseFirestore.instance
          .collection('completed_tasks')
          .where('userId', isEqualTo: userId)
          .get();

      final completed = completedSnapshot.docs.map((doc) => doc.data()['taskId'] as String).toSet();

      setState(() {
        _tasks = loadedTasks.isEmpty ? _generateSuggestedTasks() : loadedTasks;
        _completedTasks = completed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  List<LearningTask> _generateSuggestedTasks() {
    final trimester = _getTrimesterFromProfile();
    return [
      LearningTask(
        id: 'task_1',
        title: 'Your $trimester Trimester Guide',
        description: 'Essential information for where you are now',
        trimester: trimester,
      ),
      LearningTask(
        id: 'task_2',
        title: 'Nutrition & Wellness',
        description: 'What to eat and how to stay healthy',
        trimester: trimester,
      ),
      LearningTask(
        id: 'task_3',
        title: 'Know Your Rights',
        description: 'Patient advocacy and your healthcare rights',
        trimester: trimester,
      ),
      if (_userProfile?.chronicConditions.isNotEmpty ?? false)
        LearningTask(
          id: 'task_4',
          title: 'Managing ${_userProfile!.chronicConditions.first}',
          description: 'Special considerations during pregnancy',
          trimester: trimester,
        ),
    ];
  }

  String _getTrimesterFromProfile() {
    if (_userProfile?.pregnancyStage != null) {
      final stage = _userProfile!.pregnancyStage!.toLowerCase();
      if (stage.contains('first') || stage.contains('1')) return 'First';
      if (stage.contains('second') || stage.contains('2')) return 'Second';
      if (stage.contains('third') || stage.contains('3')) return 'Third';
    }
    return 'First';
  }

  Future<void> _generateLearningModule(LearningTask task) async {
    setState(() => _isLoading = true);

    try {
      // Prepare user profile data
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

      // Generate learning module
      final result = await _functionsService.generateLearningContent(
        topic: task.title,
        trimester: task.trimester,
        moduleType: 'personalized',
        userProfile: profileData,
      );

      // Save the generated task
      final userId = _auth.currentUser!.uid;
      final docRef = await FirebaseFirestore.instance
          .collection('learning_tasks')
          .add({
        'userId': userId,
        'title': task.title,
        'description': task.description,
        'trimester': task.trimester,
        'isGenerated': true,
        'content': result['content'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update task with generated content
      final updatedTask = LearningTask(
        id: docRef.id,
        title: task.title,
        description: task.description,
        trimester: task.trimester,
        isGenerated: true,
        content: result['content'],
      );

      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
        }
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Learning module generated!')),
        );
      }

      // Navigate to view the module
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModuleDetailScreen(
              title: updatedTask.title,
              trimester: updatedTask.trimester,
              type: 'personalized',
              preloadedContent: updatedTask.content,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleTaskCompletion(LearningTask task) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final isCompleted = _completedTasks.contains(task.id);

    try {
      if (isCompleted) {
        // Mark as incomplete
        await FirebaseFirestore.instance
            .collection('completed_tasks')
            .where('userId', isEqualTo: userId)
            .where('taskId', isEqualTo: task.id)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
        
        setState(() {
          _completedTasks.remove(task.id);
        });
      } else {
        // Mark as complete
        await FirebaseFirestore.instance.collection('completed_tasks').add({
          'userId': userId,
          'taskId': task.id,
          'completedAt': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _completedTasks.add(task.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To Do',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandPurple,
                ),
              ),
              if (_isGenerating && _totalModules > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.brandPurple.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandPurple),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Generating personalized modules...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.brandPurple,
                              ),
                            ),
                          ),
                          Text(
                            '$_completedModules/$_totalModules',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brandPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _totalModules > 0 ? _completedModules / _totalModules : 0,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPurple),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            final isCompleted = _completedTasks.contains(task.id);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Checkbox(
                  value: isCompleted,
                  onChanged: (value) => _toggleTaskCompletion(task),
                  activeColor: AppTheme.brandPurple,
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.grey : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          task.isGenerated ? Icons.auto_awesome : Icons.lightbulb_outline,
                          size: 14,
                          color: task.isGenerated ? Colors.amber : AppTheme.brandPurple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.isGenerated ? 'AI Generated' : 'Tap to generate',
                          style: TextStyle(
                            fontSize: 11,
                            color: task.isGenerated ? Colors.amber[700] : AppTheme.brandPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: task.isGenerated
                    ? const Icon(Icons.arrow_forward_ios, size: 16)
                    : _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_circle_outline, 
                            color: AppTheme.brandPurple, size: 28),
                onTap: () {
                  if (task.isGenerated && task.content != null) {
                    // View existing module
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModuleDetailScreen(
                          title: task.title,
                          trimester: task.trimester,
                          type: 'personalized',
                          preloadedContent: task.content,
                        ),
                      ),
                    );
                  } else {
                    // Generate new module
                    _generateLearningModule(task);
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class LearningTask {
  final String id;
  final String title;
  final String description;
  final String trimester;
  final bool isGenerated;
  final String? moduleId;
  final String? content;

  LearningTask({
    required this.id,
    required this.title,
    required this.description,
    required this.trimester,
    this.isGenerated = false,
    this.moduleId,
    this.content,
  });
}

