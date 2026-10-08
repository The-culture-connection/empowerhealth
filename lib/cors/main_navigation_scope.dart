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
  ///
  /// Works from inside the tabs and from pages pushed above them (support hub,
  /// visit summaries, check-ins). Returns false only when no tab scaffold is
  /// on the navigation stack.
  static bool goToTab(BuildContext context, int tabIndex) {
    final scope = maybeOf(context);
    if (scope != null) {
      _closeRoutesAbove(ModalRoute.of(context));
      scope.selectTab(tabIndex);
      return true;
    }
    // Pushed routes are siblings of the tab scaffold, not descendants, so
    // the inherited lookup can't see it. Find the topmost live one instead.
    final element = _topmostScopeElement();
    if (element == null) return false;
    _closeRoutesAbove(ModalRoute.of(element));
    (element.widget as MainNavigationScope).selectTab(tabIndex);
    return true;
  }

  // Close only routes above the one holding the tabs. After login the app
  // pushes the tab scaffold above the auth route, so popping while canPop()
  // would remove the tabs too and drop the user on the sign-in screen.
  static void _closeRoutesAbove(ModalRoute<dynamic>? tabsRoute) {
    if (tabsRoute == null || !tabsRoute.isActive) return;
    tabsRoute.navigator?.popUntil((route) => route == tabsRoute);
  }

  static Element? _topmostScopeElement() {
    Element? found;
    void visit(Element e) {
      if (e.widget is MainNavigationScope) {
        final route = ModalRoute.of(e);
        // Later routes in the overlay are higher in the stack; keep the last.
        if (route == null || route.isActive) found = e;
        return;
      }
      e.visitChildElements(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildElements(visit);
    return found;
  }

  static const int tabHome = 0;
  static const int tabLearn = 1;
  static const int tabJournal = 2;
  static const int tabCommunity = 3;
  static const int tabProfile = 4;
}
