// Beta-testing checklist: what testers should try, and which analytics events
// count as having tried it. Pure data and pure logic only, so tests can use it
// without Firebase.
import 'package:flutter/material.dart';

import '../app_router.dart';
import '../birthplan/birth_plans_list_screen.dart';
import '../cors/main_navigation_scope.dart';

/// Turn the whole beta checklist (icon, tracking, timer) on or off.
const bool kBetaTestingEnabled = true;

/// Daily goal: minutes of foreground use per local day.
const int kBetaDailyGoalSeconds = 600;

/// Days counted for "Days you hit 10 minutes".
const int kBetaGoalHistoryDays = 30;

typedef BetaOpenFeature = void Function(BuildContext context);

class BetaChecklistItem {
  const BetaChecklistItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.triggers,
    required this.open,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  /// Analytics event names that complete this item. Empty means the item is
  /// marked done directly with `BetaChecklistService.markDone`.
  final List<String> triggers;

  final BetaOpenFeature open;

  bool get isManual => triggers.isEmpty;
}

// Tabs switch in place when the tab scaffold is on the stack; otherwise the
// standalone route opens.
void _openTab(BuildContext context, int tab, String fallbackRoute) {
  if (!MainNavigationScope.goToTab(context, tab)) {
    Navigator.pushNamed(context, fallbackRoute);
  }
}

void _openAppointments(BuildContext c) =>
    Navigator.pushNamed(c, Routes.appointments);
void _openLearn(BuildContext c) =>
    _openTab(c, MainNavigationScope.tabLearn, Routes.learning);
void _openRights(BuildContext c) => Navigator.pushNamed(c, Routes.rights);
void _openJournal(BuildContext c) =>
    _openTab(c, MainNavigationScope.tabJournal, Routes.journal);
void _openCommunity(BuildContext c) =>
    _openTab(c, MainNavigationScope.tabCommunity, Routes.community);
void _openProviders(BuildContext c) => Navigator.pushNamed(c, Routes.providers);
void _openAssistant(BuildContext c) => Navigator.pushNamed(c, Routes.assistant);
void _openSupport(BuildContext c) => Navigator.pushNamed(
  c,
  Routes.immediateSupport,
  arguments: 'beta_checklist',
);
void _openCareSurvey(BuildContext c) =>
    Navigator.pushNamed(c, Routes.careSurvey);
void _openProfile(BuildContext c) =>
    _openTab(c, MainNavigationScope.tabProfile, Routes.editProfile);

// Same entry Home uses for "My Birth Choices".
void _openBirthPlans(BuildContext c) => Navigator.push(
  c,
  MaterialPageRoute(builder: (_) => const BirthPlansListScreen()),
);

const List<BetaChecklistItem> kBetaChecklistItems = [
  BetaChecklistItem(
    id: 'visit_summary',
    title: 'Upload a visit summary',
    subtitle: 'Add notes from a visit and see what they mean',
    icon: Icons.article_outlined,
    triggers: ['visit_summary_created'],
    open: _openAppointments,
  ),
  BetaChecklistItem(
    id: 'learning_module',
    title: 'Read a learning module',
    subtitle: 'Open any guide in Learn',
    icon: Icons.menu_book_outlined,
    triggers: ['learning_module_viewed', 'learning_module_completed'],
    open: _openLearn,
  ),
  BetaChecklistItem(
    id: 'know_rights',
    title: 'Explore Know your rights',
    subtitle: 'Read about your rights in care',
    icon: Icons.gavel_outlined,
    triggers: ['know_your_rights_viewed'],
    open: _openRights,
  ),
  BetaChecklistItem(
    id: 'journal_checkin',
    title: 'Do a quick journal check-in',
    subtitle: 'Pick how you are feeling today',
    icon: Icons.mood_outlined,
    triggers: ['journal_mood_selected'],
    open: _openJournal,
  ),
  BetaChecklistItem(
    id: 'journal_entry',
    title: 'Write a journal entry',
    subtitle: 'Save a private note in your journal',
    icon: Icons.edit_note_outlined,
    triggers: ['journal_entry_created'],
    open: _openJournal,
  ),
  BetaChecklistItem(
    id: 'community_read',
    title: 'Read a community post',
    subtitle: 'Open a post in Community',
    icon: Icons.forum_outlined,
    triggers: ['community_post_viewed'],
    open: _openCommunity,
  ),
  BetaChecklistItem(
    id: 'community_post',
    title: 'Post or reply in the community',
    subtitle: 'Share a post or answer someone',
    icon: Icons.chat_bubble_outline,
    triggers: [
      'community_post_created',
      'community_post_replied',
      'community_reply_created',
    ],
    open: _openCommunity,
  ),
  BetaChecklistItem(
    id: 'provider_search',
    title: 'Search for a provider',
    subtitle: 'Look for care near you',
    icon: Icons.search,
    triggers: ['provider_search_initiated'],
    open: _openProviders,
  ),
  BetaChecklistItem(
    id: 'provider_profile',
    title: 'View a provider profile',
    subtitle: 'Open a provider from search results',
    icon: Icons.person_search_outlined,
    triggers: ['provider_profile_viewed'],
    open: _openProviders,
  ),
  BetaChecklistItem(
    id: 'provider_review',
    title: 'Write a provider review',
    subtitle: 'Share how a provider treated you',
    icon: Icons.rate_review_outlined,
    triggers: ['provider_review_submitted'],
    open: _openProviders,
  ),
  BetaChecklistItem(
    id: 'birth_plan',
    title: 'Create a birth plan',
    subtitle: 'Write down your birth preferences',
    icon: Icons.description_outlined,
    triggers: ['birth_plan_completed'],
    open: _openBirthPlans,
  ),
  BetaChecklistItem(
    id: 'assistant',
    title: 'Ask the AI assistant a question',
    subtitle: 'Get a plain-language answer',
    icon: Icons.auto_awesome_outlined,
    triggers: [],
    open: _openAssistant,
  ),
  BetaChecklistItem(
    id: 'support',
    title: 'Open Support for you',
    subtitle: 'See the help available right now',
    icon: Icons.favorite_border,
    // The current support flow logs immediate_support_*; the support_* names
    // come from the older emotional-support flow.
    triggers: [
      'immediate_support_opened',
      'immediate_support_completed',
      'immediate_support_hub_viewed',
      'support_checkin_opened',
      'support_checkin_completed',
      'support_option_selected',
    ],
    open: _openSupport,
  ),
  BetaChecklistItem(
    id: 'care_checkin',
    title: 'Complete a care check-in',
    subtitle: 'Tell us what you need and what helped',
    icon: Icons.fact_check_outlined,
    triggers: [],
    open: _openCareSurvey,
  ),
  BetaChecklistItem(
    id: 'profile',
    title: 'Review your profile',
    subtitle: 'Check and update your details',
    icon: Icons.person_outline,
    triggers: ['profile_updated'],
    open: _openProfile,
  ),
];

/// Items completed by [eventName].
List<BetaChecklistItem> betaItemsForEvent(String eventName) => [
  for (final item in kBetaChecklistItems)
    if (item.triggers.contains(eventName)) item,
];

BetaChecklistItem? betaItemById(String id) {
  for (final item in kBetaChecklistItems) {
    if (item.id == id) return item;
  }
  return null;
}

bool betaDailyGoalMet(int todaySeconds) =>
    todaySeconds >= kBetaDailyGoalSeconds;

/// Feature items not yet done, plus one for today's goal while it is unmet.
/// Ids that are not checklist items are ignored.
int betaRemainingCount(Set<String> completedIds, int todaySeconds) {
  final itemsLeft = kBetaChecklistItems
      .where((i) => !completedIds.contains(i.id))
      .length;
  return itemsLeft + (betaDailyGoalMet(todaySeconds) ? 0 : 1);
}

/// Local calendar day as yyyy-MM-dd.
String betaDateKey(DateTime local) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}
