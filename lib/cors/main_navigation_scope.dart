import 'package:flutter/material.dart';

/// Exposes main bottom-nav tab switching to routes pushed above [MainNavigationScaffold].
class MainNavigationScope extends InheritedWidget {
  const MainNavigationScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final ValueChanged<int> selectTab;

  @override
  bool updateShouldNotify(MainNavigationScope oldWidget) =>
      oldWidget.selectTab != selectTab;

  static MainNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainNavigationScope>();
  }

  /// Pops overlay routes (e.g. care check-in) and selects a main tab (0 = Home … 4 = You).
  static bool goToTab(BuildContext context, int tabIndex) {
    final scope = maybeOf(context);
    if (scope == null) return false;
    // Close only routes above the one holding the tabs. After login the app
    // pushes the tab scaffold above the auth route, so popping while canPop()
    // would remove the tabs too and drop the user on the sign-in screen.
    final tabsRoute = ModalRoute.of(context);
    if (tabsRoute != null) {
      Navigator.of(context).popUntil((route) => route == tabsRoute);
    }
    scope.selectTab(tabIndex);
    return true;
  }

  static const int tabHome = 0;
  static const int tabLearn = 1;
  static const int tabJournal = 2;
  static const int tabCommunity = 3;
  static const int tabProfile = 4;
}
