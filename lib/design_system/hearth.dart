// Hearth components (design/hearth/THEME_SPEC.md §4). Screens pass their own
// strings and callbacks in; nothing here holds copy, so restyling never changes
// what the app says or does.
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';

const _sans = AppTheme.sansFamily;
const _serif = AppTheme.serifFamily;

/// Shape of most Hearth cards.
const BorderRadius hearthCardRadius = BorderRadius.all(Radius.circular(24));

// ---------------------------------------------------------------------------
// Headers
// ---------------------------------------------------------------------------

/// Header for a tab root (Home, Learn, Journal, Community, You): 34px serif
/// title, subtitle, and a decorative warm circle in the top-right corner.
class HearthTabHeader extends StatelessWidget {
  const HearthTabHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.warmCircle = true,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 4),
  }) : assert(title != null || titleWidget != null);

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;

  /// Off in pregnancy-loss mode, which has no decorative accents.
  final bool warmCircle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final titleText = titleWidget ??
        Text(title!, style: Theme.of(context).textTheme.displayLarge);
    final sub = subtitleWidget ??
        (subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(
                  fontFamily: _sans,
                  fontSize: 16,
                  height: 23 / 16,
                  color: AppTheme.textSecondary,
                ),
              ));
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        if (warmCircle)
          const Positioned(
            top: -70,
            right: -60,
            child: IgnorePointer(
              child: SizedBox(
                width: 200,
                height: 200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.tintWarm,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleText),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
              if (sub != null) ...[
                const SizedBox(height: 12),
                sub,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 44px round button on the surface colour (back, close, header actions).
class HearthCircleButton extends StatelessWidget {
  const HearthCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconColor = AppTheme.ink,
    this.size = 44,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color iconColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppTheme.surface,
      shape: const CircleBorder(side: BorderSide(color: AppTheme.borderWarm)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Header for a pushed screen: back (or close) circle with an optional label,
/// trailing actions, then a 26px serif title.
class HearthPushedHeader extends StatelessWidget {
  const HearthPushedHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.onBack,
    this.backLabel,
    this.backTooltip,
    this.actions = const [],
    this.close = false,
    this.showBack = true,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 8),
  });

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;

  /// Defaults to popping the route.
  final VoidCallback? onBack;
  final String? backLabel;
  final String? backTooltip;
  final List<Widget> actions;

  /// Close (×) instead of back, for modal screens.
  final bool close;
  final bool showBack;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final back = onBack ?? () => Navigator.of(context).maybePop();
    final titleText = titleWidget ??
        (title == null
            ? null
            : Text(title!, style: Theme.of(context).textTheme.displaySmall));
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // The back group takes what the actions leave, so its label never
              // splits space evenly with a spacer.
              if (!showBack) const Spacer(),
              if (showBack)
                Expanded(
                  child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InkWell(
                    onTap: back,
                    borderRadius: BorderRadius.circular(22),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HearthCircleButton(
                          icon: close ? Icons.close : Icons.arrow_back_ios_new,
                          iconSize: close ? 20 : 18,
                          tooltip: backTooltip,
                          onPressed: back,
                        ),
                        if (backLabel != null) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              backLabel!,
                              style: const TextStyle(
                                fontFamily: _sans,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ),
                ),
              for (var i = 0; i < actions.length; i++) ...[
                const SizedBox(width: 8),
                actions[i],
              ],
            ],
          ),
          if (titleText != null) ...[
            const SizedBox(height: 12),
            titleText,
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                fontFamily: _sans,
                fontSize: 15,
                height: 22 / 15,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small text action for headers (e.g. a quiet delete).
class HearthTextAction extends StatelessWidget {
  const HearthTextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppTheme.textSecondary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: _sans,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 20/26 serif section heading.
class HearthSectionHeading extends StatelessWidget {
  const HearthSectionHeading(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final heading = Text(text, style: Theme.of(context).textTheme.headlineMedium);
    if (trailing == null) return heading;
    return Row(
      children: [
        Expanded(child: heading),
        const SizedBox(width: 12),
        trailing!,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

/// Standard card: surface fill, 1px warm border, radius 24, no shadow.
class HearthCard extends StatelessWidget {
  const HearthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color = AppTheme.surface,
    this.borderColor = AppTheme.borderWarm,
    this.borderWidth = 1,
    this.radius = hearthCardRadius,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}

enum HearthTone { tint, purple }

/// Feature card: warm tint, or the one purple card a screen may have.
class HearthFeatureCard extends StatelessWidget {
  const HearthFeatureCard({
    super.key,
    required this.child,
    this.tone = HearthTone.tint,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final HearthTone tone;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final purple = tone == HearthTone.purple;
    return HearthCard(
      color: purple ? AppTheme.brandPurple : AppTheme.tintWarm,
      borderColor: null,
      padding: padding,
      onTap: onTap,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: purple ? AppTheme.onPurple : AppTheme.ink),
        child: IconTheme.merge(
          data: IconThemeData(color: purple ? AppTheme.onPurple : AppTheme.brandPurple),
          child: child,
        ),
      ),
    );
  }
}

/// Feature-card title: 19/25 serif.
TextStyle hearthFeatureTitleStyle({bool onPurple = false}) => TextStyle(
      fontFamily: _serif,
      fontSize: 19,
      height: 25 / 19,
      fontWeight: FontWeight.w400,
      color: onPurple ? AppTheme.onPurple : AppTheme.ink,
    );

/// Card or row title: 16/22 bold ink.
const TextStyle hearthCardTitleStyle = TextStyle(
  fontFamily: _sans,
  fontSize: 16,
  height: 22 / 16,
  fontWeight: FontWeight.w700,
  color: AppTheme.ink,
);

/// Body inside a card: 14/21 secondary.
const TextStyle hearthCardBodyStyle = TextStyle(
  fontFamily: _sans,
  fontSize: 14,
  height: 21 / 14,
  fontWeight: FontWeight.w400,
  color: AppTheme.textSecondary,
);

/// Caption / meta: 13/18 muted.
const TextStyle hearthCaptionStyle = TextStyle(
  fontFamily: _sans,
  fontSize: 13,
  height: 18 / 13,
  fontWeight: FontWeight.w400,
  color: AppTheme.textMuted,
);

enum HearthChipTone { tint, surface, gold }

/// 46px circle holding a 22px icon.
class HearthIconChip extends StatelessWidget {
  const HearthIconChip(
    this.icon, {
    super.key,
    this.tone = HearthChipTone.tint,
    this.size = 46,
    this.iconSize = 22,
  });

  final IconData icon;
  final HearthChipTone tone;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final (fill, iconColor) = switch (tone) {
      HearthChipTone.tint => (AppTheme.tintWarm, AppTheme.brandPurple),
      HearthChipTone.surface => (AppTheme.surface, AppTheme.brandPurple),
      HearthChipTone.gold => (AppTheme.brandGold, AppTheme.ink),
    };
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}

/// Icon chip, title, subtitle and chevron in a card.
class HearthRowCard extends StatelessWidget {
  const HearthRowCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.chipTone = HearthChipTone.tint,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final HearthChipTone chipTone;

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          HearthIconChip(icon, tone: chipTone),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: hearthCardTitleStyle),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: hearthCaptionStyle),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              (onTap == null
                  ? const SizedBox.shrink()
                  : const Icon(Icons.chevron_right, size: 20, color: AppTheme.brandPurple)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

enum _HearthButtonKind { primary, encourage, secondary, destructive, text, emergency }

/// Hearth buttons. Keep whichever kind the code used before the restyle.
class HearthButton extends StatelessWidget {
  const HearthButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  })  : _kind = _HearthButtonKind.primary,
        chevron = false;

  /// Gold fill with ink text (encouragement / community actions).
  const HearthButton.encourage({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  })  : _kind = _HearthButtonKind.encourage,
        chevron = false;

  /// Purple outline.
  const HearthButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  })  : _kind = _HearthButtonKind.secondary,
        chevron = false;

  /// Ink outline (Delete, Sign out, Block). Destructive actions are not red.
  const HearthButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  })  : _kind = _HearthButtonKind.destructive,
        chevron = false;

  /// Purple text, optionally with a trailing chevron.
  const HearthButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.chevron = false,
  })  : _kind = _HearthButtonKind.text,
        expand = false,
        loading = false;

  /// Red. Reserved for a true emergency control.
  const HearthButton.emergency({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  })  : _kind = _HearthButtonKind.emergency,
        chevron = false;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool loading;
  final bool chevron;
  final _HearthButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    final fg = switch (_kind) {
      _HearthButtonKind.primary || _HearthButtonKind.emergency => AppTheme.onPurple,
      _HearthButtonKind.encourage || _HearthButtonKind.destructive => AppTheme.ink,
      _ => AppTheme.brandPurple,
    };
    final content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
              if (chevron) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ],
          );
    final pressed = loading ? null : onPressed;
    final Widget button = switch (_kind) {
      _HearthButtonKind.primary => ElevatedButton(onPressed: pressed, child: content),
      _HearthButtonKind.encourage => ElevatedButton(
          onPressed: pressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandGold,
            foregroundColor: AppTheme.ink,
          ),
          child: content,
        ),
      _HearthButtonKind.emergency => ElevatedButton(
          onPressed: pressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emergency,
            foregroundColor: AppTheme.onPurple,
          ),
          child: content,
        ),
      _HearthButtonKind.secondary => OutlinedButton(onPressed: pressed, child: content),
      _HearthButtonKind.destructive => OutlinedButton(
          onPressed: pressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.ink,
            side: const BorderSide(color: AppTheme.ink, width: 1.5),
          ),
          child: content,
        ),
      _HearthButtonKind.text => TextButton(
          onPressed: pressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            textStyle: const TextStyle(
              fontFamily: _sans,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: content,
        ),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// ---------------------------------------------------------------------------
// Chips, options, tags, notes
// ---------------------------------------------------------------------------

/// Pill chip. Selected: tint with a 2px purple border. [primary] filter tabs
/// (All / Modules / Archived) use solid purple when selected.
class HearthChoiceChip extends StatelessWidget {
  const HearthChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.primary = false,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final bool primary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final solid = primary && selected;
    final fill = solid
        ? AppTheme.brandPurple
        : selected
            ? AppTheme.tintWarm
            : AppTheme.surface;
    final border = solid
        ? BorderSide.none
        : selected
            ? const BorderSide(color: AppTheme.brandPurple, width: 2)
            : const BorderSide(color: AppTheme.borderWarm);
    final textColor = solid
        ? AppTheme.onPurple
        : selected
            ? AppTheme.brandPurple
            : AppTheme.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: fill,
        shape: StadiumBorder(side: border),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: textColor),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: _sans,
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: textColor,
                      ),
                    ),
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

enum HearthControl { radio, checkbox }

/// Full-width choice row with the control on the left. Selected rows get a
/// 2px purple border on the warm tint.
class HearthOptionRow extends StatelessWidget {
  const HearthOptionRow({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.control = HearthControl.radio,
    this.subtitle,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final HearthControl control;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final icon = switch ((control, selected)) {
      (HearthControl.radio, true) => Icons.radio_button_checked,
      (HearthControl.radio, false) => Icons.radio_button_unchecked,
      (HearthControl.checkbox, true) => Icons.check_box,
      (HearthControl.checkbox, false) => Icons.check_box_outline_blank,
    };
    return Semantics(
      selected: selected,
      checked: control == HearthControl.checkbox ? selected : null,
      inMutuallyExclusiveGroup: control == HearthControl.radio ? true : null,
      child: HearthCard(
        onTap: onTap,
        color: selected ? AppTheme.tintWarm : AppTheme.surface,
        borderColor: selected ? AppTheme.brandPurple : AppTheme.borderWarm,
        borderWidth: selected ? 2 : 1,
        radius: BorderRadius.circular(AppTheme.fieldRadius),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 28),
          child: Row(
            children: [
              Icon(icon, size: 22, color: selected ? AppTheme.brandPurple : AppTheme.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: _sans,
                        fontSize: 15,
                        height: 22 / 15,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? AppTheme.ink : AppTheme.textSecondary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(subtitle!, style: hearthCaptionStyle),
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

enum HearthTagTone { tint, tintPurple, gold }

/// Small stadium tag. "Mama Approved" uses [HearthTag.mamaApproved].
class HearthTag extends StatelessWidget {
  const HearthTag(this.text, {super.key, this.tone = HearthTagTone.tint, this.icon});

  /// Gold tag with ink text and a heart, for the Mama Approved badge.
  const HearthTag.mamaApproved(this.text, {super.key})
      : tone = HearthTagTone.gold,
        icon = Icons.favorite_border;

  final String text;
  final HearthTagTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fill, fg) = switch (tone) {
      HearthTagTone.tint => (AppTheme.tintWarm, AppTheme.textSecondary),
      HearthTagTone.tintPurple => (AppTheme.tintWarm, AppTheme.brandPurple),
      HearthTagTone.gold => (AppTheme.brandGold, AppTheme.ink),
    };
    return DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: _sans,
                  fontSize: 12,
                  height: 18 / 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum HearthNoteTone { cream, lavender }

/// Info, privacy or disclaimer note. AI disclaimers use lavender.
class HearthNote extends StatelessWidget {
  const HearthNote({
    super.key,
    this.icon = Icons.info_outline,
    this.title,
    this.text,
    this.child,
    this.tone = HearthNoteTone.cream,
    this.padding = const EdgeInsets.all(16),
  });

  final IconData icon;
  final String? title;
  final String? text;
  final Widget? child;
  final HearthNoteTone tone;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final lavender = tone == HearthNoteTone.lavender;
    return HearthCard(
      color: lavender ? AppTheme.lavender : AppTheme.surface,
      borderColor: lavender ? null : AppTheme.borderWarm,
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 20, color: AppTheme.brandPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title!.isNotEmpty)
                  Text(
                    title!,
                    style: hearthCardBodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                if (title != null && text != null && text!.isNotEmpty) const SizedBox(height: 4),
                if (text != null && text!.isNotEmpty) Text(text!, style: hearthCardBodyStyle),
                if (child != null) child!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Step caption over a 6px progress bar. The caption comes from the screen.
class HearthStepProgress extends StatelessWidget {
  const HearthStepProgress({
    super.key,
    required this.step,
    required this.total,
    this.label,
  });

  /// 1-based current step.
  final int step;
  final int total;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (step / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: hearthCaptionStyle),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: fraction,
              color: AppTheme.brandPurple,
              backgroundColor: AppTheme.borderWarm,
            ),
          ),
        ),
      ],
    );
  }
}

/// Star rating: filled stars gold with a dark outline, empty stars terracotta.
class HearthStarRating extends StatelessWidget {
  const HearthStarRating({
    super.key,
    required this.value,
    this.max = 5,
    this.size = 46,
    this.onChanged,
    this.semanticLabelFor,
  });

  final int value;
  final int max;
  final double size;
  final ValueChanged<int>? onChanged;

  /// Screen-reader label for star N (copy stays with the screen).
  final String Function(int star)? semanticLabelFor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      children: List.generate(max, (i) {
        final star = i + 1;
        final filled = star <= value;
        final icon = filled
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.star_rounded, size: size, color: AppTheme.starStroke),
                  Icon(Icons.star_rounded, size: size * 0.84, color: AppTheme.brandGold),
                ],
              )
            : Icon(Icons.star_outline_rounded, size: size, color: AppTheme.brandTerracotta);
        final box = SizedBox(width: size + 6, height: size + 6, child: Center(child: icon));
        return Semantics(
          label: semanticLabelFor?.call(star),
          selected: filled,
          button: onChanged != null,
          child: onChanged == null
              ? box
              : InkResponse(onTap: () => onChanged!(star), radius: size / 2 + 4, child: box),
        );
      }),
    );
  }
}

/// 46px initials avatar.
class HearthAvatar extends StatelessWidget {
  const HearthAvatar(this.initials, {super.key, this.size = 46});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppTheme.tintWarm, shape: BoxShape.circle),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontFamily: _serif,
              fontSize: size * 19 / 46,
              height: 1,
              color: AppTheme.brandPurple,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App chrome
// ---------------------------------------------------------------------------

/// One bottom-nav destination. The label comes from the screen.
class HearthNavItem {
  const HearthNavItem({required this.icon, required this.label, this.activeIcon});

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

/// Five-tab bottom nav: surface fill, top border, gold bar over the active tab.
/// Labels scale down rather than clip.
class HearthBottomNav extends StatelessWidget {
  const HearthBottomNav({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<HearthNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderWarm)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _HearthNavButton(
                      item: items[i],
                      selected: i == index,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HearthNavButton extends StatelessWidget {
  const _HearthNavButton({required this.item, required this.selected, required this.onTap});

  final HearthNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.brandPurple : AppTheme.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 3,
                margin: const EdgeInsets.only(bottom: 7),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.brandGold : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                ),
              ),
              Icon(selected ? (item.activeIcon ?? item.icon) : item.icon, size: 22, color: color),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: _sans,
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating Support button: 60px purple circle with a headset, a ground-coloured
/// ring and the only shadow in Hearth.
class HearthSupportFab extends StatelessWidget {
  const HearthSupportFab({super.key, required this.onPressed, this.semanticLabel});

  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.brandPurple,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.ground, width: 3),
          // Only the Support button has a shadow (THEME_SPEC §3).
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: const Center(
              child: Icon(Icons.headset_mic_outlined, color: AppTheme.onPurple, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheets and dialogs
// ---------------------------------------------------------------------------

/// Bottom sheet on the ground colour with a centred handle and Hearth padding.
Future<T?> showHearthSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = true,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 12, 20, 32),
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: HearthSheetHandle()),
            const SizedBox(height: 16),
            Flexible(child: builder(sheetContext)),
          ],
        ),
      ),
    ),
  );
}

/// 40×4 drag handle for sheets that draw their own content.
class HearthSheetHandle extends StatelessWidget {
  const HearthSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.sheetHandle,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Dialog shell: the theme supplies ground fill, radius 28 and serif title.
Future<T?> showHearthDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}
