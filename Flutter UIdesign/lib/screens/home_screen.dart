import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final sectionLabel = isDark ? AppColors.mutedDark : AppColors.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Mama 🤍',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: fg,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're supported every step of the way.",
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w300,
              color: muted,
            ),
          ),
          const SizedBox(height: 32),
          _JourneyCard(isDark: isDark, onTap: () => context.push('/pregnancy-journey')),
          const SizedBox(height: 40),
          _SectionLabel(text: "💜 Today's Support", color: sectionLabel),
          const SizedBox(height: 16),
          _SupportCard(
            isDark: isDark,
            fg: fg,
            muted: muted,
            onTap: () => context.push('/care-check-in'),
          ),
          const SizedBox(height: 20),
          _AppointmentCard(isDark: isDark, fg: fg, muted: muted),
          const SizedBox(height: 40),
          _SectionLabel(text: 'Your space', color: sectionLabel),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.05,
            children: [
              _SpaceTile(
                isDark: isDark,
                fg: fg,
                icon: Icons.calendar_today_outlined,
                iconTint: isDark ? AppColors.primaryDarkMode : AppColors.primary,
                title: 'My Visits',
                subtitle: 'Your appointments',
                onTap: () => context.push('/my-visits'),
              ),
              _SpaceTile(
                isDark: isDark,
                fg: fg,
                icon: Icons.favorite_border_rounded,
                iconTint: AppColors.accent,
                gradientIconBg: true,
                title: "How I'm Feeling",
                subtitle: 'Your private space',
                onTap: () => context.push('/journal'),
              ),
              _SpaceTile(
                isDark: isDark,
                fg: fg,
                icon: Icons.description_outlined,
                iconTint: isDark ? AppColors.primaryDarkMode : AppColors.primary,
                title: 'My Birth Preferences',
                subtitle: "What's right for you",
                onTap: () => context.push('/birth-plan-builder'),
              ),
              _SpaceTile(
                isDark: isDark,
                fg: fg,
                icon: Icons.menu_book_outlined,
                iconTint: isDark ? AppColors.primaryDarkMode : AppColors.primary,
                title: 'My Next Steps',
                subtitle: 'Your personalized path',
                onTap: () => context.push('/care-plan'),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _SectionLabel(text: 'From the Community 💬', color: sectionLabel),
          const SizedBox(height: 16),
          _CommunityCard(
            isDark: isDark,
            fg: fg,
            muted: muted,
            onTap: () => context.push('/community'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: color,
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [
              AppColors.journeyDarkStart,
              AppColors.journeyDarkMid,
              AppColors.journeyDarkEnd,
            ]
          : const [
              AppColors.journeyGradientStart,
              AppColors.journeyGradientMid,
              AppColors.journeyGradientEnd,
            ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                blurRadius: isDark ? 48 : 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -20,
                        left: 80,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldBlur.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        right: 20,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.purpleBlur.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Week 24',
                            style: TextStyle(
                              color: AppColors.textPrimaryDark.withValues(alpha: 0.95),
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Second trimester',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.98),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "You're doing beautifully. This is a time of steady growth and settling in.",
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFFE8DFF0),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 3,
                        child: Stack(
                          children: [
                            Container(color: Colors.white.withValues(alpha: 0.2)),
                            FractionallySizedBox(
                              widthFactor: 0.6,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.accent,
                                      Color(0xFFE0B589),
                                      Color(0xFFEDC799),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '24 of 40 weeks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFFE8DFF0),
                        letterSpacing: 0.5,
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

class _SupportCard extends StatelessWidget {
  const _SupportCard({
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
          ? const [Color(0xFF2A2435), Color(0xFF2D2640), Color(0xFF3A3043)]
          : const [Color(0xFFF5EEE0), Color(0xFFFAF8F4), Color(0xFFEBE0D6)],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: gradient,
            border: Border.all(color: AppColors.borderLight.withValues(alpha: isDark ? 0.3 : 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.1),
                blurRadius: isDark ? 36 : 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldBlur.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [Color(0xFF3A3043), Color(0xFF4A3E5D)]
                                  : const [Color(0xFFF5EEE0), Color(0xFFEBE0D6)],
                            ),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 26),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prepare questions for your next visit',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: fg,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Take a moment to share what support you need. This helps us understand how to better assist you.',
                                style: TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w300, color: muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '2 minutes',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: muted),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 20, color: muted),
                      ],
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

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.isDark, required this.fg, required this.muted});

  final bool isDark;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: isDark ? 28 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF3A3043), Color(0xFF4A3E5D)]
                    : const [Color(0xFFE8E0F0), Color(0xFFD8CFE5)],
              ),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next appointment',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: muted, letterSpacing: 0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tomorrow • 2:00 PM',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: fg),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr. Maria Johnson',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: muted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: muted, size: 22),
        ],
      ),
    );
  }
}

class _SpaceTile extends StatelessWidget {
  const _SpaceTile({
    required this.isDark,
    required this.fg,
    required this.icon,
    required this.iconTint,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradientIconBg = false,
  });

  final bool isDark;
  final Color fg;
  final IconData icon;
  final Color iconTint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool gradientIconBg;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: isDark ? 24 : 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (gradientIconBg)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.goldBlur.withValues(alpha: 0.04),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: gradientIconBg
                              ? (isDark
                                  ? const [Color(0xFF3A3043), Color(0xFF4A3E5D)]
                                  : const [Color(0xFFF5EEE0), Color(0xFFEBE0D6)])
                              : (isDark
                                  ? const [Color(0xFF3A3043), Color(0xFF4A3E5D)]
                                  : const [Color(0xFFE8E0F0), Color(0xFFD8CFE5)]),
                        ),
                      ),
                      child: Icon(icon, color: iconTint, size: 22),
                    ),
                    const Spacer(),
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: fg)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: mutedFor(isDark)),
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

  Color mutedFor(bool dark) => const Color(0xFF9B8BA5);
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
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
          ? const [Color(0xFF2A2435), Color(0xFF2D2640), Color(0xFF332A3E)]
          : const [Color(0xFFFAF7F3), Color(0xFFF5F0EB), Color(0xFFF0EAD8)],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: gradient,
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0x66E8DFC8)),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldBlur.withValues(alpha: isDark ? 0.08 : 0.12),
                blurRadius: isDark ? 32 : 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldBlur.withValues(alpha: 0.05),
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
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [Color(0xFF3A3043), Color(0xFF4A3E5D)]
                                  : const [Color(0xFFF5EEE0), Color(0xFFEBE0D6)],
                            ),
                          ),
                          child: const Icon(Icons.favorite_border_rounded, color: AppColors.accent, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to EmpowerHealth Watch',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: fg),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "You're not alone here. Connect with other moms, share your journey, and find support from those who understand.",
                                style: TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w300, color: muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'Explore community',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: muted),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 18, color: muted),
                      ],
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
