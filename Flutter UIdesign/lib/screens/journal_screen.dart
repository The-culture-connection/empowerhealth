import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  static const _prompts = [
    'How are you feeling today?',
    'What brought you peace this week?',
    'What concerns are on your mind?',
  ];

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
          Text(
            'Your journal',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: fg),
          ),
          const SizedBox(height: 8),
          Text(
            'A private space for how you feel',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: muted),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: isDark ? AppColors.primaryDarkMode : AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Private & secure',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Today’s prompt', style: TextStyle(fontSize: 12, letterSpacing: 0.5, color: muted)),
                const SizedBox(height: 8),
                Text(_prompts.first, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: fg, height: 1.35)),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 4,
                  style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w300),
                  decoration: InputDecoration(
                    hintText: 'Write freely…',
                    hintStyle: TextStyle(color: muted.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1A1520) : const Color(0xFFF3F0EB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? AppColors.primaryDarkMode : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save entry'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('More prompts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: muted)),
          const SizedBox(height: 12),
          for (final p in _prompts.skip(1))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.7),
                ),
                child: Text(p, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: fg)),
              ),
            ),
        ],
      ),
    );
  }
}
