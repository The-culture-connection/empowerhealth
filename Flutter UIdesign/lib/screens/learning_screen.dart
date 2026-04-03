import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class _ModuleData {
  const _ModuleData({
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    this.gradientLight = const [Color(0xFFE8E0F0), Color(0xFFEDE7F3)],
    this.gradientDark = const [Color(0xFF3D3547), Color(0xFF4A4057)],
    this.iconColorLight = const Color(0xFF8B7AA8),
    this.iconColorDark = const Color(0xFFB89FB5),
    this.link,
  });

  final String title;
  final String description;
  final IconData icon;
  final int progress;
  final List<Color> gradientLight;
  final List<Color> gradientDark;
  final Color iconColorLight;
  final Color iconColorDark;
  final String? link;
}

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  static const _modules = <_ModuleData>[
    _ModuleData(
      title: 'Trimester learning',
      description: 'Week-by-week guidance for your journey',
      icon: Icons.menu_book_outlined,
      progress: 60,
      link: '/learning/week-24',
    ),
    _ModuleData(
      title: 'Understanding medications',
      description: "What you're taking and why it helps",
      icon: Icons.medication_outlined,
      progress: 30,
      gradientLight: [Color(0xFFDCE8E4), Color(0xFFE8F0ED)],
      gradientDark: [Color(0xFF2D3836), Color(0xFF354340)],
      iconColorLight: Color(0xFF7D9D92),
      iconColorDark: Color(0xFF89B5A6),
    ),
    _ModuleData(
      title: 'Prenatal health awareness',
      description: 'Making informed decisions with confidence',
      icon: Icons.shield_outlined,
      progress: 45,
      gradientLight: [Color(0xFFF9F2E8), Color(0xFFFEF9F5)],
      gradientDark: [Color(0xFF3D3540), Color(0xFF453D48)],
      iconColorLight: AppColors.accent,
      iconColorDark: AppColors.accentSoft,
    ),
    _ModuleData(
      title: 'Emotional wellbeing',
      description: 'Supporting your mental health',
      icon: Icons.psychology_outlined,
      progress: 20,
      gradientLight: [Color(0xFFF8EDF3), Color(0xFFFDF5F9)],
      gradientDark: [Color(0xFF3D3040), Color(0xFF433845)],
      iconColorLight: Color(0xFFC9A9C0),
      iconColorDark: Color(0xFFD4B5C9),
    ),
    _ModuleData(
      title: 'Know your rights',
      description: 'Healthcare advocacy and informed consent',
      icon: Icons.auto_awesome_outlined,
      progress: 15,
      link: '/know-your-rights',
      iconColorLight: Color(0xFF9D8FB5),
      iconColorDark: Color(0xFFB89FB5),
    ),
    _ModuleData(
      title: 'Birth preparation',
      description: 'Getting ready for labor and delivery',
      icon: Icons.favorite_border_rounded,
      progress: 0,
      gradientLight: [Color(0xFFF9F2E8), Color(0xFFFEF9F5)],
      gradientDark: [Color(0xFF3D3540), Color(0xFF453D48)],
      iconColorLight: AppColors.accent,
      iconColorDark: AppColors.accentSoft,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.textPrimaryDark : const Color(0xFF2D2733);
    final muted = isDark ? const Color(0xFFC9BFD4) : const Color(0xFF6B5C75);
    final heading = isDark ? const Color(0xFFC9BFD4) : const Color(0xFF4A3F52);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning center',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: fg),
          ),
          const SizedBox(height: 8),
          Text(
            'Knowledge that empowers your choices',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: muted),
          ),
          const SizedBox(height: 32),
          Text(
            'Continue learning',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: heading, letterSpacing: 0.3),
          ),
          const SizedBox(height: 16),
          _ContinueCard(isDark: isDark, fg: fg, muted: muted, onTap: () => context.push('/learning/week-24')),
          const SizedBox(height: 32),
          Text(
            'All topics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: heading, letterSpacing: 0.3),
          ),
          const SizedBox(height: 12),
          for (final m in _modules) ...[
            _ModuleRow(data: m, isDark: isDark, fg: fg, muted: muted),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          Text(
            'Our approach',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: heading, letterSpacing: 0.3),
          ),
          const SizedBox(height: 16),
          _ApproachCard(isDark: isDark, fg: fg, muted: muted),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.onTap,
  });

  final bool isDark;
  final Color fg;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF2D2438), Color(0xFF352D40), Color(0xFF3A2F3D)]
          : const [Color(0xFFEBE4F3), Color(0xFFE6D8ED), Color(0xFFEAD9E0)],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: gradient,
            border: Border.all(
              color: isDark ? const Color(0x4D4A4057) : const Color(0x80E0D3E8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: isDark ? 28 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -10,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? AppColors.primary : const Color(0xFFD4C5E0)).withValues(alpha: 0.35),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -20,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldBlur.withValues(alpha: isDark ? 0.25 : 0.35),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isDark ? const Color(0x993D3547) : const Color(0xCCFAF8F4),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: isDark ? const Color(0xFFB89FB5) : AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IN PROGRESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: isDark ? const Color(0xFFB89FB5) : const Color(0xFF7D6D85),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Second trimester guide',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: fg),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Week 24: Your baby's development",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Container(color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.5)),
                            FractionallySizedBox(
                              widthFactor: 0.6,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [Color(0xFF8B7AA8), AppColors.accent]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '60% complete • 5 min remaining',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: isDark ? const Color(0xFF9D8FB5) : const Color(0xFF7D6D85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.data,
    required this.isDark,
    required this.fg,
    required this.muted,
  });

  final _ModuleData data;
  final bool isDark;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    void onTap() {
      if (data.link != null) {
        context.push(data.link!);
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.link != null ? onTap : null,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? const Color(0xFF3D3547) : const Color(0x80E8E0F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: isDark ? data.gradientDark : data.gradientLight,
                  ),
                ),
                child: Icon(
                  data.icon,
                  color: isDark ? data.iconColorDark : data.iconColorLight,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: fg)),
                    const SizedBox(height: 4),
                    Text(
                      data.description,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: isDark ? const Color(0xFFB89FB5) : const Color(0xFF6B5C75),
                      ),
                    ),
                    if (data.progress > 0) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 4,
                          child: Stack(
                            children: [
                              Container(color: isDark ? const Color(0xFF3D3547) : const Color(0xFFF0E8F3)),
                              FractionallySizedBox(
                                widthFactor: data.progress / 100,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [Color(0xFF8B7AA8), AppColors.accent]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${data.progress}% complete',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF9D8FB5),
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Start learning →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFB89FB5) : const Color(0xFF8B7AA8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF9D8FB5) : const Color(0xFFB5A8C2)),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _ApproachCard extends StatelessWidget {
  const _ApproachCard({required this.isDark, required this.fg, required this.muted});

  final bool isDark;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF2D2438), Color(0xFF2A2435), Color(0xFF2F2638)]
              : const [Color(0xFFFAF8F4), Color(0xFFFDFBFC), Color(0xFFFEF9F5)],
        ),
        border: Border.all(color: isDark ? const Color(0xFF3D3547) : const Color(0x80E8E0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plain language promise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: fg)),
          const SizedBox(height: 8),
          Text(
            'All our content is written at a 6th grade reading level. No confusing medical jargon—just clear, supportive guidance that helps you understand your care.',
            style: TextStyle(fontSize: 14, height: 1.55, fontWeight: FontWeight.w300, color: muted),
          ),
        ],
      ),
    );
  }
}
