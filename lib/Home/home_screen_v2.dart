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
import '../widgets/ai_disclaimer_banner.dart';

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
          _userName = profile?.username;
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
      backgroundColor: AppTheme.backgroundWarm,
      body: Stack(
        children: [
          // Subtle warm texture overlay (matching NewUI exactly)
          // Using CustomPaint instead of NetworkImage to avoid data URI issues
          Positioned.fill(
            child: Opacity(
              opacity: 0.02,
              child: CustomPaint(
                painter: _PatternPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24), // p-6 matching NewUI
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Avatar and Greeting (matching NewUI exactly)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24), // mb-8
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56, // w-14
                              height: 56, // h-14
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF8B7AA8), // from-[#8b7aa8]
                                    Color(0xFFD4A574), // to-[#d4a574]
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF663399).withOpacity(0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(_userName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18, // text-lg
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12), // gap-3
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getGreeting()},',
                                    style: const TextStyle(
                                      fontSize: 14, // text-sm
                                      color: Color(0xFF9D8FB5), // text-[#9d8fb5]
                                      fontWeight: FontWeight.w300, // font-light
                                    ),
                                  ),
                                  Text(
                                    _userName ?? 'User',
                                    style: const TextStyle(
                                      fontSize: 20, // text-xl
                                      fontWeight: FontWeight.w400, // font-normal
                                      color: Color(0xFF2D2733), // text-[#2d2733]
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24), // mb-6

                        // Search Bar (matching NewUI exactly)
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, Routes.providers);
                          },
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28), // rounded-[28px]
                              border: Border.all(
                                color: Color(0xFFE8DFE8), // border-[#e8dfe8]
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF663399).withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              enabled: false,
                              style: const TextStyle(
                                color: Color(0xFF2D2733), // text-[#2d2733]
                                fontWeight: FontWeight.w300, // font-light
                              ),
                              decoration: InputDecoration(
                                hintText: 'Find trusted providers near you',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFB5A8C2), // placeholder:text-[#b5a8c2]
                                  fontWeight: FontWeight.w300, // font-light
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFF9D8FB5), // text-[#9d8fb5]
                                  size: 20, // w-5 h-5
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, // pl-14 pr-5
                                  vertical: 16, // py-4
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pregnancy Journey (matching NewUI exactly)
                  if (dueDate != null && weeksPregnant > 0) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32), // mb-8
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16), // mb-4
                            child: Text(
                              'Your pregnancy journey',
                              style: TextStyle(
                                fontSize: 16, // text-base
                                fontWeight: FontWeight.w400, // font-normal
                                color: Color(0xFF4A3F52), // text-[#4a3f52]
                                letterSpacing: 0.5, // tracking-wide
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(28), // p-7
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFEBE4F3), // from-[#ebe4f3]
                                  Color(0xFFE6D8ED), // via-[#e6d8ed]
                                  Color(0xFFEAD9E0), // to-[#ead9e0]
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(32), // rounded-[32px]
                              border: Border.all(
                                color: Color(0xFFE0D3E8).withOpacity(0.5), // border-[#e0d3e8]/50
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF663399).withOpacity(0.12),
                                  blurRadius: 32,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Subtle background glow (matching NewUI)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            width: 160, // w-40
                                            height: 160, // h-40
                                            decoration: BoxDecoration(
                                              color: Color(0xFFD4C5E0), // bg-[#d4c5e0]
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          child: Container(
                                            width: 192, // w-48
                                            height: 192, // h-48
                                            decoration: BoxDecoration(
                                              color: Color(0xFFE6D5B8), // bg-[#e6d5b8]
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Content
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Week $weeksPregnant of 40',
                                                style: TextStyle(
                                                  fontSize: 14, // text-sm
                                                  color: Color(0xFF7D6D85), // text-[#7d6d85]
                                                  fontWeight: FontWeight.w300, // font-light
                                                ),
                                              ),
                                              const SizedBox(height: 8), // mb-2
                                              Text(
                                                "You're in your $trimester trimester",
                                                style: const TextStyle(
                                                  fontSize: 24, // text-2xl
                                                  fontWeight: FontWeight.w400, // font-normal
                                                  color: Color(0xFF2D2733), // text-[#2d2733]
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8), // mb-2
                                              Text(
                                                "You're doing beautifully",
                                                style: TextStyle(
                                                  fontSize: 14, // text-sm
                                                  color: Color(0xFFD4A574), // text-[#d4a574]
                                                  fontWeight: FontWeight.w500, // font-medium
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12), // Add spacing between text and icon
                                        Container(
                                          width: 64, // w-16
                                          height: 64, // h-16
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.6), // bg-white/60
                                            borderRadius: BorderRadius.circular(32),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFF663399).withOpacity(0.15),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Text(
                                              '🤰',
                                              style: TextStyle(fontSize: 32), // text-2xl
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24), // mb-6
                                    // Progress bar (matching NewUI exactly)
                                    Container(
                                      height: 6, // h-1.5
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.5), // bg-white/50
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: progress.clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF8B7AA8), // from-[#8b7aa8]
                                                Color(0xFFD4A574), // to-[#d4a574]
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFF8B7AA8).withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Support for Today (matching NewUI exactly)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32), // mb-8
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16), // mb-4
                          child: Text(
                            'Support for today',
                            style: TextStyle(
                              fontSize: 16, // text-base
                              fontWeight: FontWeight.w400, // font-normal
                              color: Color(0xFF4A3F52), // text-[#4a3f52]
                              letterSpacing: 0.5, // tracking-wide
                            ),
                          ),
                        ),
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
                              return _AppointmentCard(
                                title: 'Loading...',
                                subtitle: 'Loading appointment',
                                description: '',
                                onTap: () {},
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return _AppointmentCard(
                                title: 'No appointments yet',
                                subtitle: 'Upload your first visit summary',
                                description: '',
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

                            return _AppointmentCard(
                              title: 'Prenatal appointment',
                              subtitle: 'Visit on $dateText',
                              description: 'Dr. Johnson • Valley Health Center',
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
                        const SizedBox(height: 16), // mb-4

                        // Emotional Check-in Card (matching NewUI exactly)
                        InkWell(
                          onTap: () => Navigator.pushNamed(context, Routes.journal),
                          borderRadius: BorderRadius.circular(32),
                          child: Container(
                            padding: const EdgeInsets.all(24), // p-6
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFDFBFC), // from-[#fdfbfc]
                                  Colors.white, // via-white
                                  Color(0xFFFEF9F5), // to-[#fef9f5]
                                ],
                              ),
                              borderRadius: BorderRadius.circular(32), // rounded-[32px]
                              border: Border.all(
                                color: Color(0xFFF0E8F3), // border-[#f0e8f3]
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF663399).withOpacity(0.1),
                                  blurRadius: 24,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, // w-12
                                  height: 48, // h-12
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFF8EDF3), // from-[#f8edf3]
                                        Color(0xFFF9F2E8), // to-[#f9f2e8]
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20), // rounded-[20px]
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    color: Color(0xFFC9A9C0), // text-[#c9a9c0]
                                    size: 20, // w-5 h-5
                                  ),
                                ),
                                const SizedBox(width: 16), // gap-4
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Take a moment for yourself',
                                        style: TextStyle(
                                          fontSize: 16, // text-base
                                          fontWeight: FontWeight.w400, // font-normal
                                          color: Color(0xFF2D2733), // text-[#2d2733]
                                        ),
                                      ),
                                      const SizedBox(height: 4), // mb-1
                                      Text(
                                        'How are you feeling today? Your emotional wellbeing matters.',
                                        style: TextStyle(
                                          fontSize: 14, // text-sm
                                          color: Color(0xFF6B5C75), // text-[#6b5c75]
                                          fontWeight: FontWeight.w300, // font-light
                                          height: 1.5, // leading-relaxed
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFFD4A574), // text-[#d4a574]
                                  size: 20, // w-5 h-5
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Your Care Tools (matching NewUI exactly)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16), // mb-4
                        child: Text(
                          'Your care tools',
                          style: TextStyle(
                            fontSize: 16, // text-base
                            fontWeight: FontWeight.w400, // font-normal
                            color: Color(0xFF4A3F52), // text-[#4a3f52]
                            letterSpacing: 0.5, // tracking-wide
                          ),
                        ),
                      ),
                      // Grid of 4 cards (matching NewUI exactly)
                      Row(
                        children: [
                          Expanded(
                            child: _CareToolCard(
                              icon: Icons.book_outlined,
                              iconGradient: [
                                Color(0xFFE8E0F0), // from-[#e8e0f0]
                                Color(0xFFEDE7F3), // to-[#ede7f3]
                              ],
                              iconColor: Color(0xFF8B7AA8), // text-[#8b7aa8]
                              title: 'Learning',
                              subtitle: 'Week by week guides',
                              onTap: () => Navigator.pushNamed(context, Routes.learning),
                            ),
                          ),
                          const SizedBox(width: 16), // gap-4
                          Expanded(
                            child: _CareToolCard(
                              icon: Icons.edit,
                              iconGradient: [
                                Color(0xFFF9F2E8), // from-[#f9f2e8]
                                Color(0xFFFEF9F5), // to-[#fef9f5]
                              ],
                              iconColor: Color(0xFFD4A574), // text-[#d4a574]
                              title: 'Journal',
                              subtitle: 'Your private space',
                              onTap: () => Navigator.pushNamed(context, Routes.journal),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // gap-4
                      Row(
                        children: [
                          Expanded(
                            child: _CareToolCard(
                              icon: Icons.description,
                              iconGradient: [
                                Color(0xFFE8E0F0), // from-[#e8e0f0]
                                Color(0xFFEDE7F3), // to-[#ede7f3]
                              ],
                              iconColor: Color(0xFF8B7AA8), // text-[#8b7aa8]
                              title: 'Birth plan',
                              subtitle: 'Your preferences',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BirthPlansListScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16), // gap-4
                          Expanded(
                            child: _CareToolCard(
                              icon: Icons.people_outline,
                              iconGradient: [
                                Colors.white, // from-white
                                Color(0xFFFDFBFC), // via-[#fdfbfc]
                                Color(0xFFFEF9F5), // to-[#fef9f5]
                              ],
                              iconColor: Color(0xFFC9A9C0), // text-[#c9a9c0]
                              title: 'Community',
                              subtitle: 'Connect & share',
                              borderColor: Color(0xFFF0E8F3), // border-[#f0e8f3]
                              onTap: () => Navigator.pushNamed(context, Routes.community),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.white : null,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: borderColor ?? AppTheme.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPurple.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient == null
                    ? LinearGradient(
                        colors: [
                          AppTheme.gradientBeigeStart.withOpacity(0.6),
                          AppTheme.gradientBeigeEnd.withOpacity(0.6),
                        ],
                      )
                    : null,
                color: gradient == null ? iconBg : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textBarelyVisible, size: 20),
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
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPurple.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.gradientBeigeStart.withOpacity(0.6),
                    AppTheme.gradientBeigeEnd.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textLightest,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), // mb-4
        padding: const EdgeInsets.all(24), // p-6
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32), // rounded-[32px]
          border: Border.all(
            color: Color(0xFFE8DFE8), // border-[#e8dfe8]
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF663399).withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, // w-12
              height: 48, // h-12
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE8E0F0), // from-[#e8e0f0]
                    Color(0xFFEDE7F3), // to-[#ede7f3]
                  ],
                ),
                borderRadius: BorderRadius.circular(20), // rounded-[20px]
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.calendar_today,
                color: Color(0xFF8B7AA8), // text-[#8b7aa8]
                size: 20, // w-5 h-5
              ),
            ),
            const SizedBox(width: 16), // gap-4
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16, // text-base
                      fontWeight: FontWeight.w400, // font-normal
                      color: Color(0xFF2D2733), // text-[#2d2733]
                    ),
                  ),
                  const SizedBox(height: 4), // mb-1
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14, // text-sm
                      color: Color(0xFF6B5C75), // text-[#6b5c75]
                      fontWeight: FontWeight.w300, // font-light
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8), // mb-2
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14, // text-sm
                        color: Color(0xFF9D8FB5), // text-[#9d8fb5]
                        fontWeight: FontWeight.w300, // font-light
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Color(0xFFB5A8C2), // text-[#b5a8c2]
              size: 20, // w-5 h-5
            ),
          ],
        ),
      ),
    );
  }
}

class _CareToolCard extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? borderColor;
  final VoidCallback onTap;

  const _CareToolCard({
    required this.icon,
    required this.iconGradient,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20), // p-5
        decoration: BoxDecoration(
          gradient: borderColor != null
              ? LinearGradient(
                  colors: iconGradient,
                )
              : null,
          color: borderColor == null ? Colors.white : null,
          borderRadius: BorderRadius.circular(28), // rounded-[28px]
          border: Border.all(
            color: borderColor ?? Color(0xFFE8DFE8), // border-[#e8dfe8]
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF663399).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, // w-11
              height: 44, // h-11
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconGradient,
                ),
                borderRadius: BorderRadius.circular(18), // rounded-[18px]
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20, // w-5 h-5
              ),
            ),
            const SizedBox(height: 12), // mb-3
            Text(
              title,
              style: TextStyle(
                fontSize: 14, // text-sm
                fontWeight: FontWeight.w400, // font-normal
                color: Color(0xFF2D2733), // text-[#2d2733]
              ),
            ),
            const SizedBox(height: 4), // mb-1
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12, // text-xs
                color: Color(0xFF9D8FB5), // text-[#9d8fb5]
                fontWeight: FontWeight.w300, // font-light
              ),
            ),
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
            const SizedBox(height: 16),
            // AI Disclaimer Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AIDisclaimerBanner(
                customMessage: 'This tool helps you understand your care.',
                customSubMessage: 'It does not replace your provider.',
              ),
            ),
            const SizedBox(height: 16),
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

// Custom painter for the subtle pattern overlay (replaces SVG data URI)
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF663399)
      ..style = PaintingStyle.fill;

    const tileSize = 60.0;
    final tileCountX = (size.width / tileSize).ceil() + 1;
    final tileCountY = (size.height / tileSize).ceil() + 1;

    for (int x = 0; x < tileCountX; x++) {
      for (int y = 0; y < tileCountY; y++) {
        final offsetX = x * tileSize;
        final offsetY = y * tileSize;
        
        // Draw the pattern (simplified version of the SVG pattern)
        // This creates a subtle dot pattern
        canvas.drawCircle(
          Offset(offsetX + 6, offsetY + 6),
          2,
          paint,
        );
        canvas.drawCircle(
          Offset(offsetX + 36, offsetY + 6),
          2,
          paint,
        );
        canvas.drawCircle(
          Offset(offsetX + 6, offsetY + 36),
          2,
          paint,
        );
        canvas.drawCircle(
          Offset(offsetX + 36, offsetY + 36),
          2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
