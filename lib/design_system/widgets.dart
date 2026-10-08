import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../cors/ui_theme.dart';
import 'hearth.dart';

/// Older design-system helpers, kept for existing callers and drawn with
/// Hearth components.
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
    return HearthIconChip(Icons.favorite_border, size: size, iconSize: size * 0.55);
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
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }

  // Primary button
  static Widget cta(String label, {VoidCallback? onPressed, IconData? icon, bool fullWidth = true}) {
    return HearthButton.primary(label: label, onPressed: onPressed, icon: icon, expand: fullWidth);
  }

  // Secondary button
  static Widget secondary(String label, {VoidCallback? onPressed, IconData? icon, bool fullWidth = true}) {
    return HearthButton.secondary(label: label, onPressed: onPressed, icon: icon, expand: fullWidth);
  }

  // Text button
  static Widget textButton(String label, {VoidCallback? onPressed}) {
    return HearthButton.text(label: label, onPressed: onPressed);
  }

  // Section card with optional image header
  static Widget section({
    required String title,
    required Widget child,
    Widget? trailing,
    String? imageUrl,
  }) {
    return HearthCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.tintWarm,
                image: DecorationImage(
                  image: AssetImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HearthSectionHeading(title, trailing: trailing),
                const SizedBox(height: 12),
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
    // Kept for callers; Hearth icon chips are always purple on warm tint.
    Color? iconColor,
  }) {
    return HearthRowCard(icon: icon, title: title, subtitle: subtitle, onTap: onTap);
  }

  // Background images for each screen
  static const String authBackground = 'assets/images/Authscreen.jpeg';
  static const String homeBackground = 'assets/images/Homeimage.jpeg';
  static const String communityBackground = 'assets/images/babyfamily.jpeg';
  static const String feedbackBackground = 'assets/images/family.jpeg';
  static const String appointmentsBackground = 'assets/images/helpingheadjpg.jpeg';
  static const String transcriptionBackground = 'assets/images/braidinghair.png';

  // Random background image helper (legacy support)
  static String getRandomBackgroundImage() {
    final images = [
      authBackground,
      homeBackground,
      communityBackground,
      feedbackBackground,
      appointmentsBackground,
      transcriptionBackground,
    ];
    return images[math.Random().nextInt(images.length)];
  }

  // Hero header: warm tint panel with an optional faint photo behind the title.
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
        color: AppTheme.tintWarm,
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
                opacity: 0.15,
              )
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.displaySmall),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
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
    return HearthCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          HearthAvatar(avatarText ?? title[0].toUpperCase()),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: hearthCardTitleStyle),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: hearthCardBodyStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ?? const Icon(Icons.chevron_right, size: 20, color: AppTheme.brandPurple),
        ],
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
        child: Builder(
          builder: (context) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HearthIconChip(icon, size: 72, iconSize: 32),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 24),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
