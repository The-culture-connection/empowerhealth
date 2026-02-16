import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_router.dart';
import '../cors/ui_theme.dart';
import '../birthplan/birth_plans_list_screen.dart';
import '../appointments/appointments_list_screen.dart';
import '../services/database_service.dart';
import '../services/firebase_functions_service.dart';
import '../utils/pregnancy_utils.dart';
import 'learning_todo_widget.dart';
import 'Learning Modules/learning_module_detail_screen.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userName;
  dynamic _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final profile = await _databaseService.getUserProfile(userId);
      if (mounted) {
        setState(() {
          _userName = profile?.name;
          _userProfile = profile;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _showGenerateModulesDialog(BuildContext context) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final profile = await _databaseService.getUserProfile(userId);
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first')),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModuleGenerationDialog(profile: profile),
    );
    
    if (mounted) {
      setState(() {});
    }
  }

  void _showTodoModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF663399), Color(0xFF8855BB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Learning Modules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: const LearningTodoWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueDate = _userProfile?.dueDate;
    final weeksPregnant = PregnancyUtils.calculateWeeksPregnant(dueDate);
    final trimester = PregnancyUtils.calculateTrimester(dueDate);
    final progress = weeksPregnant > 0 ? (weeksPregnant / 40) : 0.0;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Avatar and Greeting
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF663399), Color(0xFFCBBEC9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_userName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()},',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _userName ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, Routes.providers);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'Search topics, providers, or questions',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Pregnancy Journey Card
                if (dueDate != null && weeksPregnant > 0) ...[
                  const Text(
                    'Your Pregnancy Journey',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF663399), Color(0xFF8855BB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Week $weeksPregnant of 40',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$trimester Trimester',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "You're doing beautifully",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: const Center(
                                child: Text(
                                  '🤰',
                                  style: TextStyle(fontSize: 32),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Today's Support Section
                const Text(
                  "Today's Support",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Most Recent Appointment Analysis
                StreamBuilder<QuerySnapshot>(
                  stream: _auth.currentUser != null
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .collection('visit_summaries')
                          .orderBy('appointmentDate', descending: true)
                          .limit(1)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _SupportCard(
                        icon: Icons.calendar_today,
                        iconColor: const Color(0xFF663399),
                        iconBg: const Color(0xFF663399).withOpacity(0.1),
                        title: 'Loading...',
                        subtitle: 'Loading appointment',
                        onTap: () {},
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _SupportCard(
                        icon: Icons.calendar_today,
                        iconColor: const Color(0xFF663399),
                        iconBg: const Color(0xFF663399).withOpacity(0.1),
                        title: 'No appointments yet',
                        subtitle: 'Upload your first visit summary',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AppointmentsListScreen(),
                            ),
                          );
                        },
                      );
                    }

                    final doc = snapshot.data!.docs.first;
                    final data = doc.data() as Map<String, dynamic>;
                    final appointmentDate = data['appointmentDate'];
                    final summary = data['summary'];
                    final summaryString = summary is String 
                        ? summary 
                        : (summary is Map 
                            ? (data['summaryData'] is Map 
                                ? _formatSummaryFromMap(data['summaryData'] as Map<String, dynamic>)
                                : summary.toString())
                            : null);
                    
                    String dateText = 'Recent appointment';
                    if (appointmentDate != null) {
                      if (appointmentDate is Timestamp) {
                        dateText = DateFormat('MMMM d, yyyy').format(appointmentDate.toDate());
                      } else if (appointmentDate is String) {
                        try {
                          final dt = DateTime.parse(appointmentDate);
                          dateText = DateFormat('MMMM d, yyyy').format(dt);
                        } catch (e) {
                          dateText = 'Recent appointment';
                        }
                      }
                    }

                    String previewText = 'View your visit summary';
                    if (summaryString != null) {
                      final babyMatch = RegExp(r'## How Your Baby Is Doing\n(.*?)(?=\n## |$)', dotAll: true)
                          .firstMatch(summaryString);
                      if (babyMatch != null) {
                        final content = babyMatch.group(1)?.trim() ?? '';
                        previewText = content.length > 80 ? content.substring(0, 80) + '...' : content;
                      } else {
                        final lines = summaryString.split('\n');
                        for (final line in lines) {
                          if (line.trim().isNotEmpty && !line.startsWith('#')) {
                            previewText = line.trim();
                            if (previewText.length > 80) {
                              previewText = previewText.substring(0, 80) + '...';
                            }
                            break;
                          }
                        }
                      }
                    }

                    return _SupportCard(
                      icon: Icons.medical_information,
                      iconColor: const Color(0xFF663399),
                      iconBg: const Color(0xFF663399).withOpacity(0.1),
                      title: 'Visit on $dateText',
                      subtitle: previewText,
                      description: data['readingLevel'] ?? '8th grade',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentsListScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Emotional Check-in Card
                _SupportCard(
                  icon: Icons.favorite,
                  iconColor: Colors.red.shade500,
                  iconBg: Colors.red.shade50,
                  title: 'How are you feeling?',
                  subtitle: 'Take a moment to check in with yourself',
                  gradient: LinearGradient(
                    colors: [Colors.red.shade50, Colors.pink.shade50],
                  ),
                  borderColor: Colors.pink.shade100,
                  onTap: () => Navigator.pushNamed(context, Routes.journal),
                ),
                const SizedBox(height: 24),

                // Learning Modules Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Learning Modules',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, Routes.learning),
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          color: Color(0xFF663399),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Active Learning Modules Widget
                StreamBuilder<QuerySnapshot>(
                  stream: _auth.currentUser != null
                      ? FirebaseFirestore.instance
                          .collection('learning_tasks')
                          .where('userId', isEqualTo: _auth.currentUser!.uid)
                          .where('isGenerated', isEqualTo: true)
                          .orderBy('createdAt', descending: true)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          Expanded(child: _ModuleCard(
                            icon: Icons.book_outlined,
                            iconColor: Colors.blue.shade500,
                            iconBg: Colors.blue.shade50,
                            title: 'Loading...',
                            subtitle: 'Loading modules',
                            onTap: () {},
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _ModuleCard(
                            icon: Icons.book_outlined,
                            iconColor: Colors.blue.shade500,
                            iconBg: Colors.blue.shade50,
                            title: 'Loading...',
                            subtitle: 'Loading modules',
                            onTap: () {},
                          )),
                        ],
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Row(
                        children: [
                          Expanded(
                            child: _ModuleCard(
                              icon: Icons.book_outlined,
                              iconColor: Colors.blue.shade500,
                              iconBg: Colors.blue.shade50,
                              title: 'No modules yet',
                              subtitle: 'Generate modules to get started',
                              onTap: () => Navigator.pushNamed(context, Routes.learning),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModuleCard(
                              icon: Icons.add_circle_outline,
                              iconColor: const Color(0xFF663399),
                              iconBg: const Color(0xFF663399).withOpacity(0.1),
                              title: 'Get started',
                              subtitle: 'Create your first module',
                              onTap: () => Navigator.pushNamed(context, Routes.learning),
                            ),
                          ),
                        ],
                      );
                    }

                    // Filter out archived modules and get first 2 active ones
                    final activeModules = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isArchived = data['isArchived'] ?? false;
                      return isArchived != true;
                    }).take(2).toList();
                    
                    final module1 = activeModules.length > 0 ? activeModules[0] : null;
                    final module2 = activeModules.length > 1 ? activeModules[1] : null;

                    return Row(
                      children: [
                        Expanded(
                          child: module1 != null
                              ? _buildModuleCardFromData(
                                  module1.data() as Map<String, dynamic>,
                                  (title) {
                                    final lower = title.toLowerCase();
                                    if (lower.contains('right') || lower.contains('advocacy')) return Icons.scale;
                                    if (lower.contains('nutrition') || lower.contains('food')) return Icons.restaurant;
                                    if (lower.contains('medication')) return Icons.medication;
                                    if (lower.contains('mental') || lower.contains('emotional')) return Icons.favorite;
                                    if (lower.contains('birth') || lower.contains('labor')) return Icons.child_care;
                                    return Icons.book_outlined;
                                  },
                                  (title) {
                                    final lower = title.toLowerCase();
                                    if (lower.contains('right') || lower.contains('advocacy')) {
                                      return {'bg': Colors.red.shade50, 'icon': Colors.red.shade600};
                                    }
                                    if (lower.contains('nutrition') || lower.contains('food')) {
                                      return {'bg': Colors.green.shade50, 'icon': Colors.green.shade600};
                                    }
                                    if (lower.contains('medication')) {
                                      return {'bg': Colors.green.shade50, 'icon': Colors.green.shade600};
                                    }
                                    if (lower.contains('mental') || lower.contains('emotional')) {
                                      return {'bg': Colors.purple.shade50, 'icon': const Color(0xFF663399)};
                                    }
                                    return {'bg': Colors.blue.shade50, 'icon': Colors.blue.shade500};
                                  },
                                  context,
                                )
                              : _ModuleCard(
                                  icon: Icons.book_outlined,
                                  iconColor: Colors.blue.shade500,
                                  iconBg: Colors.blue.shade50,
                                  title: 'No modules',
                                  subtitle: 'Get started',
                                  onTap: () => Navigator.pushNamed(context, Routes.learning),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: module2 != null
                              ? _buildModuleCardFromData(
                                  module2.data() as Map<String, dynamic>,
                                  (title) {
                                    final lower = title.toLowerCase();
                                    if (lower.contains('right') || lower.contains('advocacy')) return Icons.scale;
                                    if (lower.contains('nutrition') || lower.contains('food')) return Icons.restaurant;
                                    if (lower.contains('medication')) return Icons.medication;
                                    if (lower.contains('mental') || lower.contains('emotional')) return Icons.favorite;
                                    if (lower.contains('birth') || lower.contains('labor')) return Icons.child_care;
                                    return Icons.book_outlined;
                                  },
                                  (title) {
                                    final lower = title.toLowerCase();
                                    if (lower.contains('right') || lower.contains('advocacy')) {
                                      return {'bg': Colors.red.shade50, 'icon': Colors.red.shade600};
                                    }
                                    if (lower.contains('nutrition') || lower.contains('food')) {
                                      return {'bg': Colors.green.shade50, 'icon': Colors.green.shade600};
                                    }
                                    if (lower.contains('medication')) {
                                      return {'bg': Colors.green.shade50, 'icon': Colors.green.shade600};
                                    }
                                    if (lower.contains('mental') || lower.contains('emotional')) {
                                      return {'bg': Colors.purple.shade50, 'icon': const Color(0xFF663399)};
                                    }
                                    return {'bg': Colors.blue.shade50, 'icon': Colors.blue.shade500};
                                  },
                                  context,
                                )
                              : _ModuleCard(
                                  icon: Icons.add_circle_outline,
                                  iconColor: const Color(0xFF663399),
                                  iconBg: const Color(0xFF663399).withOpacity(0.1),
                                  title: 'Add module',
                                  subtitle: 'Create new',
                                  onTap: () => Navigator.pushNamed(context, Routes.learning),
                                ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Quick Tools Section
                const Text(
                  'Quick Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _QuickToolCard(
                  icon: Icons.assignment,
                  iconColor: const Color(0xFF663399),
                  iconBg: const Color(0xFF663399).withOpacity(0.1),
                  title: 'Birth Plan Builder',
                  subtitle: 'Create your preferences',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BirthPlansListScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _QuickToolCard(
                  icon: Icons.description,
                  iconColor: Colors.green.shade600,
                  iconBg: Colors.green.shade50,
                  title: 'After Visit Summary',
                  subtitle: 'Understand your visit',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppointmentsListScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _QuickToolCard(
                  icon: Icons.favorite,
                  iconColor: Colors.amber.shade600,
                  iconBg: Colors.amber.shade50,
                  title: 'Journal Entry',
                  subtitle: 'Reflect on today',
                  onTap: () => Navigator.pushNamed(context, Routes.journal),
                ),
                const SizedBox(height: 80), // Space for bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper functions for home screen
  Widget _buildModuleCardFromData(
    Map<String, dynamic> data,
    IconData Function(String) getIcon,
    Map<String, Color> Function(String) getColors,
    BuildContext context,
  ) {
    final title = (data['title'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final content = data['content'];
    final contentString = content is String 
        ? content 
        : (content is Map ? content.toString() : '');
    final colors = getColors(title);
    final icon = getIcon(title);

    return InkWell(
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
        } else {
          Navigator.pushNamed(context, Routes.learning);
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors['bg']!,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: colors['icon']!, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description.isNotEmpty ? description : 'Learning module',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatSummaryFromMap(Map<String, dynamic> summaryMap) {
    final buffer = StringBuffer();
    
    if (summaryMap['howBabyIsDoing'] != null) {
      buffer.writeln('## How Your Baby Is Doing');
      buffer.writeln(summaryMap['howBabyIsDoing']);
      buffer.writeln();
    }
    
    if (summaryMap['howYouAreDoing'] != null) {
      buffer.writeln('## How You Are Doing');
      buffer.writeln(summaryMap['howYouAreDoing']);
      buffer.writeln();
    }
    
    if (summaryMap['nextSteps'] != null) {
      buffer.writeln('## Actions To Take');
      buffer.writeln(summaryMap['nextSteps']);
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? description;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback onTap;

  const _SupportCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.description,
    this.gradient,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.white : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor ?? Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
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
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickToolCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickToolCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _ModuleGenerationDialog extends StatefulWidget {
  final dynamic profile;
  const _ModuleGenerationDialog({required this.profile});

  @override
  State<_ModuleGenerationDialog> createState() => _ModuleGenerationDialogState();
}

class _ModuleGenerationDialogState extends State<_ModuleGenerationDialog> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  double _progress = 0.0;
  String _currentTask = 'Preparing your personalized learning plan...';
  int _completedModules = 0;
  int _totalModules = 4;

  @override
  void initState() {
    super.initState();
    _generateModules();
  }

  Future<void> _generateModules() async {
    final trimester = PregnancyUtils.calculateTrimester(widget.profile.dueDate);
    final userId = widget.profile.userId;

    final profileData = {
      'chronicConditions': widget.profile.chronicConditions ?? [],
      'healthLiteracyGoals': widget.profile.healthLiteracyGoals ?? [],
      'insuranceType': widget.profile.insuranceType ?? '',
      'providerPreferences': widget.profile.providerPreferences ?? [],
      'educationLevel': widget.profile.educationLevel ?? '',
    };

    final modules = [
      {'title': 'Your $trimester Trimester Guide', 'description': 'Essential information for your stage'},
      {'title': 'Nutrition & Wellness', 'description': 'What to eat and how to stay healthy'},
      {'title': 'Know Your Rights', 'description': 'Patient advocacy in maternity care'},
      {'title': 'Preparing for Appointments', 'description': 'Making the most of your visits'},
    ];

    if (widget.profile.chronicConditions != null && widget.profile.chronicConditions.isNotEmpty) {
      modules.add({
        'title': 'Managing ${widget.profile.chronicConditions.first}',
        'description': 'Special considerations during pregnancy',
      });
      _totalModules = 5;
    }

    for (int i = 0; i < modules.length; i++) {
      final module = modules[i];
      
      setState(() {
        _currentTask = 'Generating: ${module['title']}...';
        _progress = (i / modules.length);
      });

      try {
        final result = await _functionsService.generateLearningContent(
          topic: module['title']!,
          trimester: trimester,
          moduleType: 'personalized',
          userProfile: profileData,
        );

        await FirebaseFirestore.instance.collection('learning_tasks').add({
          'userId': userId,
          'title': module['title'],
          'description': module['description'],
          'trimester': trimester,
          'isGenerated': true,
          'content': result['content'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _completedModules = i + 1;
          _progress = ((i + 1) / modules.length);
        });

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Error generating module: $e');
      }
    }

    setState(() {
      _currentTask = 'Complete! Your learning plan is ready.';
      _progress = 1.0;
    });

    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 48,
              color: Color(0xFF663399),
            ),
            const SizedBox(height: 16),
            const Text(
              'Creating Your Learning Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF663399),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF663399)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentTask,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$_completedModules of $_totalModules modules generated',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
