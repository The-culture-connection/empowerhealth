import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/navigation/main_navigation_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/appointments/appointments_screen.dart';
import 'features/transcription/transcription_screen.dart';
import 'features/community/community_screen.dart';
import 'features/feedback/feedback_screen.dart';

class AppRouter {
  static const auth = Routes.auth;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.auth:
        return _page(const AuthScreen());
      case Routes.login:
        return _page(const LoginScreen());
      case Routes.signup:
        return _page(const SignupScreen());
      case Routes.mainNavigation:
        return _page(const MainNavigationScreen());
      case Routes.dashboard:
        return _page(const DashboardScreen());
      case Routes.appointments:
        return _page(const AppointmentsScreen());
      case Routes.transcription:
        return _page(const TranscriptionScreen());
      case Routes.community:
        return _page(const CommunityScreen());
      case Routes.feedback:
        return _page(const FeedbackScreen());
      default:
        return _page(const AuthScreen());
    }
  }

  static PageRoute _page(Widget child) => MaterialPageRoute(builder: (_) => child);
}
