import 'dart:async';

import 'package:flutter/material.dart';

import '../app_router.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../navigation/overlay_navigation.dart';
import '../providers/provider_search_entry_screen.dart';
import '../resources/app_external_resources.dart';
import '../resources/open_app_resource.dart';
import '../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import 'pregnancy_loss_entry_exception.dart';
import 'pregnancy_loss_learning_screen.dart';
import 'pregnancy_loss_provider_questions_screen.dart';
import 'pregnancy_loss_service.dart';
import 'pregnancy_loss_transition_screen.dart';

/// Persists pregnancy-loss mode, closes check-in, then shows transition flow.
/// Returns true when profile was saved and onboarding was started.
Future<bool> startPregnancyLossFlowFromCheckIn(
  BuildContext context, {
  required List<String> selectedOptionIds,
  String? somethingElseText,
}) async {
  try {
    await PregnancyLossService.instance.enterPregnancyLossMode(
      checkInOptionIds: selectedOptionIds,
      somethingElseText: somethingElseText,
    );
  } on PregnancyLossEntryException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
    }
    return false;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong saving your settings. Please try again.',
          ),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
    }
    return false;
  }

  if (!context.mounted) return true;

  final rootNav = Navigator.of(context, rootNavigator: true);
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop(true);
  }

  if (!context.mounted) return true;

  await rootNav.push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const PregnancyLossTransitionScreen(),
    ),
  );
  return true;
}

/// Closes onboarding overlays and lands on the pregnancy-loss home tab.
void finishPregnancyLossOnboarding(BuildContext context) {
  popAllOverlayRoutes(context);
  MainNavigationScope.goToTab(context, MainNavigationScope.tabHome);
}

/// @deprecated Use [startPregnancyLossFlowFromCheckIn].
Future<bool> enterPregnancyLossAndShowHome(
  BuildContext context, {
  required List<String> selectedOptionIds,
  String? somethingElseText,
}) =>
    startPregnancyLossFlowFromCheckIn(
      context,
      selectedOptionIds: selectedOptionIds,
      somethingElseText: somethingElseText,
    );

/// Main app destinations from pregnancy-loss home.
abstract final class PregnancyLossNavId {
  static const learn = 'learn';
  static const journal = 'journal';
  static const community = 'community';
  static const providers = 'providers';
  static const resources = 'resources';
  static const providerQuestions = 'provider_questions';
}

class PregnancyLossNavDestination {
  const PregnancyLossNavDestination({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Future<void> Function(BuildContext context) onTap;
}

Future<void> openPregnancyLossProviderSearch(BuildContext context) async {
  await PregnancyLossService.instance.logResourceOpened('providers_search');

  final uid = FirebaseAuth.instance.currentUser?.uid;
  UserProfile? profile;
  if (uid != null) {
    profile = await DatabaseService().getUserProfile(uid);
  }

  final zip = profile?.zipCode;
  final city = profile?.city;

  if (!context.mounted) return;

  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ProviderSearchEntryScreen(
        prefill: ProviderSearchPrefill(
          zip: zip != null && zip.isNotEmpty ? zip : null,
          city: city != null && city.isNotEmpty ? city : null,
          providerTypeDisplayNames: const [
            'Obstetrics And Gynecology',
            'Clinical Counseling',
            'Psychology',
            'Social Work',
            'Mental Health Clinic',
            'Marriage And Family Therapy',
          ],
          specialtyQuery:
              'pregnancy loss miscarriage grief maternal mental health',
          includeNpi: true,
        ),
      ),
    ),
  );
}

Future<void> openPregnancyLossHelpfulLinks(BuildContext context) async {
  await PregnancyLossService.instance.logResourceOpened('helpful_links');
  await openAppResourcesScreen(context);
}

Future<void> openPregnancyLossLearn(BuildContext context) async {
  await PregnancyLossService.instance.logModuleOpened('learning_tab');
  if (!MainNavigationScope.goToTab(context, MainNavigationScope.tabLearn)) {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const PregnancyLossLearningScreen(),
      ),
    );
  }
}

Future<void> openPregnancyLossJournal(BuildContext context) async {
  await PregnancyLossService.instance.logResourceOpened('journal');
  if (!MainNavigationScope.goToTab(context, MainNavigationScope.tabJournal)) {
    await Navigator.pushNamed(context, Routes.journal);
  }
}

Future<void> openPregnancyLossCommunity(BuildContext context) async {
  await PregnancyLossService.instance.logCommunityOpened();
  MainNavigationScope.goToTab(context, MainNavigationScope.tabCommunity);
}

Future<void> openPregnancyLossProviderQuestions(BuildContext context) async {
  await PregnancyLossService.instance.logResourceOpened('provider_questions');
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => const PregnancyLossProviderQuestionsScreen(),
    ),
  );
}

Future<void> openPregnancyLossMaternalMentalHealthHotline(
  BuildContext context,
) async {
  await PregnancyLossService.instance.logResourceOpened(
    'maternal_mental_health_hotline',
  );
  await openAppResourceById(context, 'maternal_mental_health_hotline');
}

Future<void> openPregnancyLossPsi(BuildContext context) async {
  await PregnancyLossService.instance.logResourceOpened('postpartum_psi');
  await openAppResourceById(context, 'postpartum_psi');
}

List<PregnancyLossNavDestination> pregnancyLossNavDestinations(
  BuildContext context,
) {
  return [
    PregnancyLossNavDestination(
      id: PregnancyLossNavId.learn,
      title: 'Learning guides',
      subtitle: 'Plain-language modules on recovery, visits, and follow-up care',
      icon: Icons.menu_book_outlined,
      onTap: openPregnancyLossLearn,
    ),
    PregnancyLossNavDestination(
      id: PregnancyLossNavId.journal,
      title: 'My journal',
      subtitle: 'Private notes, symptoms, and questions for your next visit',
      icon: Icons.edit_note_outlined,
      onTap: openPregnancyLossJournal,
    ),
    PregnancyLossNavDestination(
      id: PregnancyLossNavId.providerQuestions,
      title: 'Questions for my provider',
      subtitle: 'Visit prompts you can copy into your journal',
      icon: Icons.checklist_outlined,
      onTap: openPregnancyLossProviderQuestions,
    ),
    PregnancyLossNavDestination(
      id: PregnancyLossNavId.community,
      title: 'Pregnancy loss community',
      subtitle: 'Connect with others in the support space',
      icon: Icons.people_outline_rounded,
      onTap: openPregnancyLossCommunity,
    ),
    PregnancyLossNavDestination(
      id: PregnancyLossNavId.providers,
      title: 'Find a provider',
      subtitle: 'Search OB, mental health, and counseling near you',
      icon: Icons.person_search_outlined,
      onTap: openPregnancyLossProviderSearch,
    ),
    PregnancyLossNavDestination(
      id: PregnancyLossNavId.resources,
      title: 'Helpful links',
      subtitle: '988, maternal mental health hotline, 211, WIC, and more',
      icon: Icons.link_rounded,
      onTap: openPregnancyLossHelpfulLinks,
    ),
  ];
}

List<AppExternalResource> pregnancyLossQuickExternalResources() {
  return [
    appExternalResourceById('maternal_mental_health_hotline')!,
    appExternalResourceById('postpartum_psi')!,
    appExternalResourceById('211')!,
  ];
}
