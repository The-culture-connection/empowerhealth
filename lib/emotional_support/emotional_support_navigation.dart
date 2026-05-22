import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_router.dart';
import '../care_survey/care_checkin_learning_module.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../models/user_profile.dart';
import '../providers/provider_search_entry_screen.dart';
import '../resources/app_external_resources.dart';
import '../resources/open_app_resource.dart';
import '../services/database_service.dart';
import 'emotional_support_service.dart';

Future<void> launchCrisis988({
  required BuildContext context,
  required String action,
}) async {
  final profile = await _profile();
  await EmotionalSupportService.instance.logCrisisResourceOpened(
    action: action,
    profile: profile,
  );

  final Uri uri;
  switch (action) {
    case 'call':
      uri = Uri.parse('tel:988');
      break;
    case 'text':
      uri = Uri.parse('sms:988');
      break;
    case 'chat':
      uri = Uri.parse('https://988lifeline.org/chat/');
      break;
    default:
      return;
  }

  if (!await canLaunchUrl(uri)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this support option.')),
      );
    }
    return;
  }
  await launchUrl(
    uri,
    mode: action == 'chat'
        ? LaunchMode.externalApplication
        : LaunchMode.platformDefault,
  );
}

Future<UserProfile?> _profile() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  return DatabaseService().getUserProfile(uid);
}

/// Postpartum mental health provider search with profile autofill + loading UI.
Future<void> openPostpartumMentalHealthProviders(BuildContext context) async {
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.brandPurple),
            const SizedBox(height: 20),
            Text(
              'Opening provider search…',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  try {
    final profile = await _profile();
    await EmotionalSupportService.instance.logPpdSupportOpened(profile: profile);
    await EmotionalSupportService.instance.logResourceOpened(
      resourceId: 'ppd_providers',
      pathwayId: 'ppd',
      profile: profile,
    );

    final zip = profile?.zipCode;
    final city = profile?.city;

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProviderSearchEntryScreen(
          prefill: ProviderSearchPrefill(
            zip: zip != null && zip.isNotEmpty ? zip : null,
            city: city != null && city.isNotEmpty ? city : null,
            providerTypeDisplayNames: const [
              'Clinical Counseling',
              'Psychology',
              'Social Work',
              'Marriage And Family Therapy',
              'Mental Health Clinic',
              'Ohio Department Of Mental Health Provider',
            ],
            specialtyQuery: 'postpartum depression anxiety maternal mental health',
            includeNpi: true,
          ),
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open provider search: $e')),
      );
    }
  }
}

Future<void> openEmotionalSupportResource(
  BuildContext context, {
  required String resourceId,
  required String pathwayId,
  required Future<void> Function() action,
}) async {
  final profile = await _profile();
  await EmotionalSupportService.instance.logResourceOpened(
    resourceId: resourceId,
    pathwayId: pathwayId,
    profile: profile,
  );
  await action();
}

void openAssistant(BuildContext context, String prompt) {
  Navigator.pushNamed(context, Routes.assistant, arguments: prompt);
}

void openCommunityTab(BuildContext context) {
  if (!MainNavigationScope.goToTab(context, MainNavigationScope.tabCommunity)) {
    Navigator.pushNamed(context, Routes.community);
  }
}

void openJournalTab(BuildContext context) {
  if (!MainNavigationScope.goToTab(context, MainNavigationScope.tabJournal)) {
    Navigator.pushNamed(context, Routes.journal);
  }
}

void openRights(BuildContext context) {
  Navigator.pushNamed(context, Routes.rights);
}

void openPregnancyJourney(BuildContext context) {
  Navigator.pushNamed(context, Routes.pregnancyJourney);
}

Future<void> openPpdLearningModule(BuildContext context) async {
  await generateAndOpenCareCheckinLearningModule(
    context,
    topic: 'Postpartum emotional changes',
    description:
        'Emotional changes after birth, anxiety, overwhelm, and what support can look like.',
    sourceActionId: 'ppd_learning',
  );
}

Future<void> openAdjustmentLearningModule(BuildContext context) async {
  await generateAndOpenCareCheckinLearningModule(
    context,
    topic: 'Adjusting after a big life change',
    description:
        'Normalize overwhelm, identity shifts, and transition stress with supportive guidance.',
    sourceActionId: 'adjustment_learning',
  );
}

Future<void> openCareNavigationResources(BuildContext context) async {
  await openAppResourcesScreen(context);
}
