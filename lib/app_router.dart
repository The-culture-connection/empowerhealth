import 'package:flutter/material.dart';

import 'auth/auth_screen.dart';
import 'auth/Login_screen.dart';
import 'auth/Sign_up_screen.dart';
import 'auth/terms_and_conditions_screen.dart';
import 'cors/main_navigation_scaffold.dart';
import 'Home/home_screen.dart';
import 'Journal/Journal_screen.dart';
import 'Community/community_screen.dart';
import 'assistant/assistant_screen.dart';
import 'editprofile/edit_profile_screen.dart';
import 'privacy/privacy_center_screen.dart';
import 'privacy/consent_screen.dart';
import 'appointments/appointments_list_screen.dart';
import 'learning/learning_route_gate.dart';
import 'Home/Messages/Messages_screen.dart';
import 'profile/profile_creation_screen.dart';
import 'providers/provider_search_screen.dart';
import 'providers/provider_search_entry_screen.dart';
import 'providers/add_provider_screen.dart';
import 'care_survey/care_navigation_survey_screen.dart';
import 'immediate_support/immediate_support_checkin_screen.dart';
import 'resources/app_resources_screen.dart';
import 'Home/pregnancy_journey_screen.dart';
import 'Home/Learning Modules/rights_screen.dart';

class Routes {
  static const auth = '/auth';
  static const login = '/login';
  static const signup = '/signup';
  static const terms = '/terms';
  static const profileCreation = '/profile-creation';
  static const main = '/main';

  // Tabs
  static const home = '/home';
  static const journal = '/journal';
  static const community = '/community';
  static const assistant = '/assistant';
  static const editProfile = '/edit-profile';
  static const privacyCenter = '/privacy-center';
  static const consent = '/consent';

  // Home subroutes
  static const appointments = '/appointments';
  static const learning = '/learning';
  static const messages = '/messages';
  static const providers = '/providers';
  static const providerSearch = '/providers/search';
  static const providerResults = '/providers/results';
  static const providerProfile = '/providers/profile';
  static const addProvider = '/providers/add';
  static const careSurvey = '/care-survey';
  static const immediateSupport = '/immediate-support';
  static const emotionalSupportCheckin = '/immediate-support';
  static const resources = '/resources';
  static const pregnancyJourney = '/pregnancy-journey';
  static const rights = '/rights';
}

class AppRouter {
  static String get auth => Routes.auth;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.auth:
        return _page(const AuthScreen());
      case Routes.login:
        return _page(const LoginScreen());
      case Routes.signup:
        return _page(const SignUpScreen());
      case Routes.terms:
        return _page(const TermsAndConditionsScreen());
      case Routes.profileCreation:
        return _page(const ProfileCreationScreen());
      case Routes.main:
        return _page(const MainNavigationScaffold());

      // Tabs (can be deep-linked if needed)
      case Routes.home:
        return _page(const HomeScreen());
      case Routes.journal:
        return _page(const JournalScreen());
      case Routes.community:
        return _page(const CommunityScreen());
      case Routes.assistant:
        final initialPrompt = settings.arguments is String
            ? settings.arguments as String
            : null;
        return _page(AssistantScreen(initialPrompt: initialPrompt));
      case Routes.editProfile:
        return _page(const EditProfileScreen());
      case Routes.privacyCenter:
        return _page(const PrivacyCenterScreen());
      case Routes.consent:
        return _page(const ConsentScreen());

      // Home subroutes
      case Routes.appointments:
        return _page(const AppointmentsListScreen());
      case Routes.learning:
        return _page(const LearningRouteGate());
      case Routes.messages:
        return _page(const MessagesScreen());
      case Routes.providers:
        return _page(const ProviderSearchScreen());
      case Routes.providerSearch:
        return _page(const ProviderSearchEntryScreen());
      case Routes.addProvider:
        return _page(const AddProviderScreen());
      case Routes.careSurvey:
        return _page(const CareNavigationSurveyScreen());
      case Routes.immediateSupport:
      case Routes.emotionalSupportCheckin:
        final entrySource = settings.arguments is String
            ? settings.arguments as String
            : 'route';
        return _page(ImmediateSupportCheckInScreen(entrySource: entrySource));
      case Routes.resources:
        final args = settings.arguments;
        String? highlightId;
        String? category;
        if (args is Map<String, dynamic>) {
          highlightId = args['highlightResourceId'] as String?;
          category = args['categoryFilter'] as String?;
        }
        return _page(AppResourcesScreen(
          highlightResourceId: highlightId,
          categoryFilter: category,
        ));
      case Routes.pregnancyJourney:
        return _page(const PregnancyJourneyScreen());
      case Routes.rights:
        return _page(const RightsScreen());
      default:
        return _page(const AuthScreen());
    }
  }

  static PageRoute _page(Widget child) => MaterialPageRoute(builder: (_) => child);
}
