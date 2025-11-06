import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'features/landing/landing_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/tabs/main_tab_scaffold.dart';

class AppRouter {
  static const landing = Routes.landing;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.landing:
        return _page(const LandingScreen());
      case Routes.login:
        return _page(const LoginScreen());
      case Routes.signup:
        return _page(const SignupScreen());
      case Routes.tabs:
        return _page(const MainTabScaffold());
      default:
        return _page(const LandingScreen());
    }
  }

  static PageRoute _page(Widget child) => MaterialPageRoute(builder: (_) => child);
}
