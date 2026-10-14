import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/ambient_background.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _navItems = <_NavItem>[
    _NavItem(path: '/', label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _NavItem(path: '/learning', label: 'Learn', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded),
    _NavItem(path: '/journal', label: 'Journal', icon: Icons.favorite_outline_rounded, activeIcon: Icons.favorite_rounded),
    _NavItem(path: '/community', label: 'Community', icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded),
    _NavItem(path: '/profile', label: 'You', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
  ];

  bool _isActive(String path, String navPath) {
    if (navPath == '/') {
      return path == '/' || path.isEmpty;
    }
    return path == navPath || path.startsWith('$navPath/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final path = GoRouterState.of(context).uri.path;
    final tc = ThemeScope.of(context);

    final activeColor = isDark ? AppColors.accent : AppColors.primary;
    final inactiveColor = isDark ? AppColors.navInactiveDark : AppColors.navInactiveLight;

    final barBg = isDark ? const Color(0xF02A2435) : const Color(0xF2FFFFFF);
    final borderColor = isDark ? const Color(0xFF3A3043) : const Color(0xFFE8E0F0);

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientBackground(),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 672),
                child: child,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 16,
            child: Material(
              color: isDark ? const Color(0xFF2A2435) : Colors.white,
              elevation: 0,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => tc.toggle(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                    size: 22,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: barBg,
        elevation: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 32,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final item in _navItems)
                    _NavBarItem(
                      label: item.label,
                      icon: item.icon,
                      activeIcon: item.activeIcon,
                      selected: _isActive(path, item.path),
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => context.go(item.path),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1,
              duration: const Duration(milliseconds: 220),
              child: Icon(selected ? activeIcon : icon, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.4,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
