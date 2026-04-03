import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.textPrimaryDark : const Color(0xFF2D2733);
    final muted = isDark ? const Color(0xFFC9BFD4) : const Color(0xFF6B5C75);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: fg)),
          const SizedBox(height: 8),
          Text(
            'Manage your information and preferences',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: muted),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF2D2438), Color(0xFF352D40), Color(0xFF3A2F3D)]
                    : const [Color(0xFFEBE4F3), Color(0xFFE0D5EB), Color(0xFFE8DFE8)],
              ),
              border: Border.all(color: isDark ? const Color(0x4D4A4057) : const Color(0x80E0D3E8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.45),
                  ),
                  child: Text(
                    'S',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFB89FB5) : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sarah Mitchell', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: fg)),
                      const SizedBox(height: 4),
                      Text('sarah.mitchell@email.com', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: muted)),
                      const SizedBox(height: 8),
                      Text(
                        'Due date: June 15, 2026',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: isDark ? const Color(0xFFB89FB5) : muted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Edit', style: TextStyle(color: isDark ? const Color(0xFFB89FB5) : const Color(0xFF8B7A95))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _ProfileRow(icon: Icons.calendar_today_outlined, label: 'Appointments', isDark: isDark, fg: fg, muted: muted),
          _ProfileRow(icon: Icons.favorite_border_rounded, label: 'Care team', isDark: isDark, fg: fg, muted: muted),
          _ProfileRow(icon: Icons.shield_outlined, label: 'Privacy & security', isDark: isDark, fg: fg, muted: muted),
          _ProfileRow(icon: Icons.notifications_outlined, label: 'Notifications', isDark: isDark, fg: fg, muted: muted),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.fg,
    required this.muted,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          leading: Icon(icon, color: isDark ? AppColors.primaryDarkMode : AppColors.primary),
          title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: fg)),
          trailing: Icon(Icons.chevron_right_rounded, color: muted),
          onTap: () {},
        ),
      ),
    );
  }
}
