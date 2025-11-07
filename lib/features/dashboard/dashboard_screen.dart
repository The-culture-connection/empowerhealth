import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';
import '../../core/constants.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fixed background image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightBackground,
                    AppTheme.lightMuted,
                  ],
                ),
              ),
            ),
          ),
          
          // Scrollable content
          SafeArea(
            child: Column(
              children: [
                // App Bar with microphone
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Row(
                    children: [
                      DS.logo(size: 40),
                      const SizedBox(width: AppTheme.spacingM),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Welcome back!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Quick action: Transcription button (top right corner)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.lightPrimary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.cardShadowLight,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, Routes.transcription);
                          },
                          tooltip: 'Quick Transcription',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Appointments Widget with Calendar
                        Card(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.appointments);
                            },
                            borderRadius: BorderRadius.circular(AppTheme.radius),
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.lightPrimary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_today,
                                          color: AppTheme.lightPrimary,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spacingM),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Upcoming Appointments',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Tap to view calendar',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  DS.gapL,
                                  
                                  // Next appointment preview
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingM),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightMuted,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSmall,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.event,
                                          color: AppTheme.lightPrimary,
                                        ),
                                        const SizedBox(width: AppTheme.spacingM),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Dr. Smith - General Checkup',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Today at 2:00 PM',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.lightForeground
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        DS.gapL,
                        
                        // Two square widgets row: Community and Feedback
                        Row(
                          children: [
                            // Community Widget
                            Expanded(
                              child: Card(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(context, Routes.community);
                                  },
                                  borderRadius: BorderRadius.circular(AppTheme.radius),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppTheme.spacingL),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.people,
                                            color: AppTheme.success,
                                            size: 28,
                                          ),
                                        ),
                                        DS.gapM,
                                        const Text(
                                          'Community',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Most recent message',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.lightForeground
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        DS.gapS,
                                        Container(
                                          padding: const EdgeInsets.all(AppTheme.spacingS),
                                          decoration: BoxDecoration(
                                            color: AppTheme.lightMuted,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Sarah M.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Just finished my first PT session...',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.lightForeground
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '5 min ago',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.lightForeground
                                                      .withOpacity(0.4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: AppTheme.spacingM),
                            
                            // Feedback Widget
                            Expanded(
                              child: Card(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(context, Routes.feedback);
                                  },
                                  borderRadius: BorderRadius.circular(AppTheme.radius),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppTheme.spacingL),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warning.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.feedback,
                                            color: AppTheme.warning,
                                            size: 28,
                                          ),
                                        ),
                                        DS.gapM,
                                        const Text(
                                          'Feedback',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Recent feedback',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.lightForeground
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        DS.gapS,
                                        Container(
                                          padding: const EdgeInsets.all(AppTheme.spacingS),
                                          decoration: BoxDecoration(
                                            color: AppTheme.lightMuted,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'App Performance Issue',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.warning.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'In Progress',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.warning,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '2 days ago',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.lightForeground
                                                      .withOpacity(0.4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        DS.gapL,
                        
                        // Additional quick actions section
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        DS.gapM,
                        
                        Row(
                          children: [
                            Expanded(
                              child: DS.secondary(
                                'View Profile',
                                icon: Icons.person_outline,
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: DS.secondary(
                                'Settings',
                                icon: Icons.settings_outlined,
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
