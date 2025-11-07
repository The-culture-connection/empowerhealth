import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'theme.dart';

class DS {
  // Gap helpers
  static const gapXS = SizedBox(height: AppTheme.spacingXS);
  static const gapS = SizedBox(height: AppTheme.spacingS);
  static const gapM = SizedBox(height: AppTheme.spacingM);
  static const gapL = SizedBox(height: AppTheme.spacingL);
  static const gapXL = SizedBox(height: AppTheme.spacingXL);
  static const gapXXL = SizedBox(height: AppTheme.spacingXXL);

  // Horizontal gaps
  static const hGapXS = SizedBox(width: AppTheme.spacingXS);
  static const hGapS = SizedBox(width: AppTheme.spacingS);
  static const hGapM = SizedBox(width: AppTheme.spacingM);
  static const hGapL = SizedBox(width: AppTheme.spacingL);

  // Logo widget - secondary logo for headers
  static Widget logo({double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.lightPrimary,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: const Center(
        child: Icon(
          Icons.favorite,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // App bar with logo
  static AppBar appBarWithLogo(BuildContext context, String title, {List<Widget>? actions}) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(12.0),
        child: logo(size: 32),
      ),
      title: Text(title),
      actions: actions,
    );
  }

  // Primary button
  static Widget cta(String label, {VoidCallback? onPressed, IconData? icon, bool fullWidth = true}) {
    final button = ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  // Secondary button
  static Widget secondary(String label, {VoidCallback? onPressed, IconData? icon, bool fullWidth = true}) {
    final button = OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  // Text button
  static Widget textButton(String label, {VoidCallback? onPressed}) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  // Section card with optional image header
  static Widget section({
    required String title,
    required Widget child,
    Widget? trailing,
    String? imageUrl,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.lightMuted,
                image: DecorationImage(
                  image: AssetImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Info card for dashboard items
  static Widget infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.lightPrimary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppTheme.lightPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.lightForeground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.lightForeground.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Random background image helper
  static String? getRandomBackgroundImage() {
    final images = [
      'assets/images/bg1.png',
      'assets/images/bg2.png',
      'assets/images/bg3.png',
      'assets/images/bg4.png',
      'assets/images/bg5.png',
    ];
    // Return null if images don't exist, will use gradient fallback
    try {
      return images[math.Random().nextInt(images.length)];
    } catch (e) {
      return null;
    }
  }

  // Hero header with background image
  static Widget heroHeader({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? backgroundImage,
  }) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightPrimary,
            AppTheme.lightAccent,
          ],
        ),
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
                opacity: 0.3,
              )
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  logo(size: 40),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // List tile for messages/forums
  static Widget messageTile({
    required String title,
    required String subtitle,
    String? avatarText,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingS,
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.lightAccent,
          child: Text(
            avatarText ?? title[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.lightForeground.withOpacity(0.6),
            ),
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              color: AppTheme.lightForeground.withOpacity(0.3),
            ),
      ),
    );
  }

  // Empty state widget
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.lightMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppTheme.lightPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppTheme.spacingS),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.lightForeground.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingXL),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
