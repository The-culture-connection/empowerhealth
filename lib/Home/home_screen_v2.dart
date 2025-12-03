import 'package:flutter/material.dart';
import '../app_router.dart';
import '../cors/ui_theme.dart';
import '../visits/visit_summary_screen.dart';
import '../birthplan/birth_plan_creator_screen.dart';
import '../appointments/appointment_checklist_screen.dart';
import '../learning/learning_modules_screen.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/homescreen.jpeg', fit: BoxFit.cover),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontFamily: 'Primary',
                          fontSize: 70,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.brandGold,
                        ),
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
                  const SizedBox(height: 12),

                  // Quick access grid
                  Row(
                    children: [
                      Expanded(
                        child: _GlassCard(
                          onTap: () => Navigator.pushNamed(context, Routes.appointments),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CardTitle('Appointments'),
                              SizedBox(height: 8),
                              Text('Nov, 29\n6:00pm\n\nFirst Trimester\nCheck-up',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _GlassCard(
                          onTap: () => Navigator.pushNamed(context, Routes.messages),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CardTitle('Messages'),
                              SizedBox(height: 8),
                              Text('PHP: Hey How\nis it going',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // AI-Powered Tools Section
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _CardTitle('AI Tools'),
                        const SizedBox(height: 12),
                        _ToolButton(
                          icon: Icons.summarize,
                          label: 'Visit Summary',
                          description: 'Understand your appointment notes',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VisitSummaryScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _ToolButton(
                          icon: Icons.checklist,
                          label: 'Appointment Checklist',
                          description: 'Prepare for your next visit',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AppointmentChecklistScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _ToolButton(
                          icon: Icons.assignment,
                          label: 'Birth Plan Creator',
                          description: 'Plan your perfect birth experience',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BirthPlanCreatorScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Learning section
                  _GlassCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LearningModulesScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.school, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CardTitle('Learning'),
                              SizedBox(height: 4),
                              Text(
                                'Trimester guides • Know your rights • Birth prep',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white70),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Primary',
        color: AppTheme.brandGold,
        fontSize: 30,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _GlassCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.brandPurple.withOpacity(0.65),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}

