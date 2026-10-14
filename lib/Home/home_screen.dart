import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_router.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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
          _userName = profile?.username;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome and User Name
            HearthTabHeader(
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome', style: textTheme.displayLarge),
                  if (_userName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _userName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineMedium,
                    ),
                  ],
                ],
              ),
              trailing: HearthCircleButton(
                icon: Icons.mic_none_rounded,
                onPressed: () {},
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Square Buttons Section
                    Row(
                      children: [
                        Expanded(
                          child: _SquareButton(
                            icon: Icons.calendar_today_outlined,
                            label: 'Appointments',
                            onTap: () => Navigator.pushNamed(context, Routes.appointments),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SquareButton(
                            icon: Icons.favorite_border,
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
                            icon: Icons.book_outlined,
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

                    const SizedBox(height: 28),

                    // Community Notifications Section
                    const HearthSectionHeading('Community Notifications'),
                    const SizedBox(height: 12),

                    Expanded(
                      child: _CommunityNotificationsList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    return HearthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: MediaQuery.of(context).size.width * 0.3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HearthIconChip(icon),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: hearthCardTitleStyle,
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
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _mockNotifications.length,
      itemBuilder: (context, index) {
        final notification = _mockNotifications[index];
        return HearthCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notification['title']!,
                      style: hearthCardTitleStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    notification['time']!,
                    style: hearthCaptionStyle,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notification['message']!,
                style: hearthCardBodyStyle,
              ),
            ],
          ),
        );
      },
    );
  }
}
