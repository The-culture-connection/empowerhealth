import 'package:flutter/material.dart';

import 'theme_controller.dart';

class ThemeScope extends InheritedWidget {
  const ThemeScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ThemeController controller;

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      oldWidget.controller != controller;
}
