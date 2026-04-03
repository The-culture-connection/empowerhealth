import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class _Discussion {
  const _Discussion({
    required this.title,
    required this.author,
    required this.replies,
    required this.category,
    required this.time,
    this.highlightTag = false,
  });

  final String title;
  final String author;
  final int replies;
  final String category;
  final String time;
  final bool highlightTag;
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static const _items = <_Discussion>[
    _Discussion(
      title: 'First time feeling movement - is this normal?',
      author: 'Maya K.',
      replies: 12,
      category: 'Questions',
      time: '2 hours ago',
    ),
    _Discussion(
      title: 'My unmedicated birth story - you CAN do this!',
      author: 'Jennifer R.',
      replies: 45,
      category: 'Birth Stories',
      time: '5 hours ago',
      highlightTag: true,
    ),
    _Discussion(
      title: 'Anxiety about upcoming glucose test',
      author: 'Sarah M.',
      replies: 8,
      category: 'Support',
      time: '1 day ago',
    ),
    _Discussion(
      title: 'Finding a doula who looks like me',
      author: 'Amara T.',
      replies: 23,
      category: 'Resources',
      time: '1 day ago',
      highlightTag: true,
    ),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Community', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: fg)),
                    const SizedBox(height: 6),
                    Text(
                      'EmpowerHealth Watch',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: muted),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => context.push('/community/new'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('New post'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < _items.length; i++) ...[
            _DiscussionTile(item: _items[i], isDark: isDark, fg: fg, muted: muted, index: i),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DiscussionTile extends StatelessWidget {
  const _DiscussionTile({
    required this.item,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.index,
  });

  final _Discussion item;
  final bool isDark;
  final Color fg;
  final Color muted;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/community/${index + 1}'),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.highlightTag)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Black Mamas Matter',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.accentSoft : const Color(0xFF6B4A2E),
                      ),
                    ),
                  ),
                Text(item.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: fg, height: 1.3)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(item.author, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: muted)),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: muted)),
                    const SizedBox(width: 8),
                    Text(item.category, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: muted)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Text('${item.replies} replies', style: TextStyle(fontSize: 12, color: muted)),
                    const Spacer(),
                    Text(item.time, style: TextStyle(fontSize: 12, color: muted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
