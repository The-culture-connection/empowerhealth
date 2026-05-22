import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';

/// Today's Guidance — emotionally supportive entry (distinct from educational cards).
class HomeEmotionalSupportCard extends StatelessWidget {
  const HomeEmotionalSupportCard({
    super.key,
    required this.onCheckIn,
    this.compact = false,
  });

  final VoidCallback onCheckIn;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCheckIn,
        borderRadius: BorderRadius.circular(compact ? 20 : 26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 20 : 26),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFEBE4F3),
                const Color(0xFFF5F0FA),
                const Color(0xFFE8DFF5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppTheme.brandPurple.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandPurple.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -8,
                right: 12,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 56,
                  color: AppTheme.brandPurple.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 20,
                child: Icon(
                  Icons.support_rounded,
                  size: 40,
                  color: AppTheme.brandPurple.withValues(alpha: 0.06),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 22,
                  compact ? 16 : 22,
                  compact ? 16 : 22,
                  compact ? 14 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: compact ? 40 : 52,
                          height: compact ? 40 : 52,
                          decoration: BoxDecoration(
                            color: AppTheme.brandWhite.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.shadowSoft(
                              opacity: 0.08,
                              blur: 12,
                              y: 4,
                            ),
                          ),
                          child: Icon(
                            Icons.volunteer_activism_rounded,
                            color: AppTheme.brandPurple,
                            size: compact ? 20 : 26,
                          ),
                        ),
                        SizedBox(width: compact ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I’m not doing okay',
                                style: TextStyle(
                                  fontSize: compact ? 16 : 20,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                  color: AppTheme.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                              SizedBox(height: compact ? 4 : 8),
                              Text(
                                'Whatever you’re feeling right now, you don’t have to go through it alone.',
                                style: TextStyle(
                                  fontSize: compact ? 13 : 15,
                                  fontWeight: FontWeight.w300,
                                  height: 1.45,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: onCheckIn,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandPurple,
                          foregroundColor: AppTheme.brandWhite,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 20 : 28,
                            vertical: compact ? 10 : 14,
                          ),
                          minimumSize: Size(0, compact ? 40 : 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Check in',
                          style: TextStyle(
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
