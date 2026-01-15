import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_router.dart';
import '../cors/ui_theme.dart';
import '../services/database_service.dart';
import '../birthplan/birth_plans_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final profile = await _databaseService.getUserProfile(userId);
      if (mounted) {
        setState(() {
          _userName = profile?.name;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E2F6), // #e8e2f6
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome and User Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontFamily: 'Primary',
                          fontSize: MediaQuery.of(context).size.width * 0.12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                      if (_userName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _userName!,
                          style: TextStyle(
                            fontFamily: 'Primary',
                            fontSize: MediaQuery.of(context).size.width * 0.08,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.brandPurple,
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    iconSize: 36,
                    icon: const Icon(
                      Icons.mic_none_rounded,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Square Buttons Section
              Row(
                children: [
                  Expanded(
                    child: _SquareButton(
                      icon: Icons.calendar_today,
                      label: 'Appointments',
                      onTap: () => Navigator.pushNamed(context, Routes.appointments),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SquareButton(
                      icon: Icons.favorite,
                      label: 'Birthplan',
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SquareButton(
                      icon: Icons.book,
                      label: 'Journal',
                      onTap: () => Navigator.pushNamed(context, Routes.journal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SquareButton(
                      icon: Icons.checklist,
                      label: 'Todo',
                      onTap: () => Navigator.pushNamed(context, Routes.learning),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Community Notifications Section
              Text(
                'Community Notifications',
                style: TextStyle(
                  fontFamily: 'Primary',
                  fontSize: MediaQuery.of(context).size.width * 0.06,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brandPurple,
                ),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: _CommunityNotificationsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: MediaQuery.of(context).size.width * 0.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppTheme.brandPurple,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.brandPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityNotificationsList extends StatelessWidget {
  final List<Map<String, String>> _mockNotifications = [
    {
      'title': 'New Community Event',
      'message': 'Join us for a virtual support group meeting this Friday at 6 PM',
      'time': '2 hours ago',
    },
    {
      'title': 'Resource Update',
      'message': 'New prenatal care resources are now available in your area',
      'time': '1 day ago',
    },
    {
      'title': 'Community Tip',
      'message': 'Remember to stay hydrated and take breaks throughout the day',
      'time': '2 days ago',
    },
    {
      'title': 'Welcome Message',
      'message': 'Welcome to the EmpowerHealth Watch community!',
      'time': '3 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _mockNotifications.length,
      itemBuilder: (context, index) {
        final notification = _mockNotifications[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                  ),
                  Text(
                    notification['time']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification['message']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

