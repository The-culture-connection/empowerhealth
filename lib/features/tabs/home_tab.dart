import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DS.appBarWithLogo(
        context,
        'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Text(
              'Welcome back, Sarah',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            DS.gapS,
            Text(
              'Here\'s an overview of your prenatal journey',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightForeground.withOpacity(0.6),
                  ),
            ),
            DS.gapXL,
            
            // Upcoming visit card
            DS.section(
              title: 'Upcoming Visit',
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
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OB Appointment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            DS.gapXS,
                            Text(
                              'Tuesday, Nov 12 • 10:30 AM',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.lightForeground.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  DS.gapM,
                  DS.cta(
                    'View Details',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      // Navigate to upcoming visit screen
                    },
                  ),
                ],
              ),
            ),
            DS.gapL,
            
            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            DS.gapM,
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.mic,
                    label: 'Record',
                    color: AppTheme.lightPrimary,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.school_outlined,
                    label: 'Learn',
                    color: AppTheme.lightAccent,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            DS.gapM,
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.forum_outlined,
                    label: 'Forums',
                    color: AppTheme.lightSecondary,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.message_outlined,
                    label: 'Messages',
                    color: AppTheme.lightPrimary,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            DS.gapXL,
            
            // Recent summaries
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Summaries',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See all'),
                ),
              ],
            ),
            DS.gapM,
            DS.messageTile(
              title: 'Visit 10/31 • 3 min summary',
              subtitle: 'Fundal height 28cm, GDM screen ordered. Everything looking good!',
              avatarText: 'V1',
              onTap: () {},
            ),
            DS.messageTile(
              title: 'Visit 10/15 • 2 min summary',
              subtitle: 'BP 118/72, fetal HR 140, next labs scheduled.',
              avatarText: 'V2',
              onTap: () {},
            ),
            DS.gapXL,
            
            // Health tracking section
            DS.section(
              title: 'This Week',
              child: Column(
                children: [
                  _HealthMetricRow(
                    icon: Icons.favorite,
                    label: 'Blood Pressure',
                    value: '118/72',
                    status: 'Normal',
                    statusColor: AppTheme.success,
                  ),
                  const Divider(height: AppTheme.spacingL),
                  _HealthMetricRow(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight',
                    value: '+2 lbs',
                    status: 'On track',
                    statusColor: AppTheme.success,
                  ),
                  const Divider(height: AppTheme.spacingL),
                  _HealthMetricRow(
                    icon: Icons.child_care,
                    label: 'Fetal Movement',
                    value: '12 times',
                    status: 'Active',
                    statusColor: AppTheme.success,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              DS.gapM,
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthMetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String status;
  final Color statusColor;

  const _HealthMetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.lightPrimary, size: 24),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.lightForeground.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
