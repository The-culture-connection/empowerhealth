import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

/// Pointer kinds that may drag a horizontal scrollable. Flutter's default
/// behavior on web and desktop leaves out the mouse, so a horizontal row
/// cannot be scrolled with a mouse that has no horizontal wheel.
const Set<PointerDeviceKind> kHorizontalDragDevices = {
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.trackpad,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

/// Wraps a horizontal scrollable so it can be dragged with a mouse, trackpad
/// or stylus as well as touch. Keeps every other part of the inherited
/// [ScrollBehavior] (scrollbars, overscroll, physics).
///
/// Use only around horizontal scrollables: on vertical lists, mouse drag
/// would fight with text selection.
class HorizontalDragScroll extends StatelessWidget {
  const HorizontalDragScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: kHorizontalDragDevices,
      ),
      child: child,
    );
  }
}
