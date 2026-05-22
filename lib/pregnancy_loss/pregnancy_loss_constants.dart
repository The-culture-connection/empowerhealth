/// Pregnancy-loss support preference option ids (stored on profile).
abstract final class PregnancyLossPreferenceId {
  static const emotionalGrief = 'emotional_grief';
  static const understanding = 'understanding';
  static const bodyCare = 'body_care';
  static const providerTalk = 'provider_talk';
  static const futureReady = 'future_ready';
  static const practical = 'practical';
  static const somethingElse = 'something_else';
}

class PregnancyLossPreferenceOption {
  const PregnancyLossPreferenceOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

const List<PregnancyLossPreferenceOption> kPregnancyLossPreferenceOptions = [
  PregnancyLossPreferenceOption(
    id: PregnancyLossPreferenceId.emotionalGrief,
    label: 'Emotional or grief support',
  ),
  PregnancyLossPreferenceOption(
    id: PregnancyLossPreferenceId.understanding,
    label: 'Understanding what happened',
  ),
  PregnancyLossPreferenceOption(
    id: PregnancyLossPreferenceId.bodyCare,
    label: 'Follow-up care for my body',
  ),
  PregnancyLossPreferenceOption(
    id: PregnancyLossPreferenceId.providerTalk,
    label: 'Help talking to my provider',
  ),
  PregnancyLossPreferenceOption(
    id: PregnancyLossPreferenceId.futureReady,
    label: 'Support for the future, if or when I’m ready',
  ),
  PregnancyLossPreferenceOption(
    id: PregnancyLossPreferenceId.practical,
    label: 'Practical support or resources',
  ),
  PregnancyLossPreferenceOption(
    id: PregnancyLossPreferenceId.somethingElse,
    label: 'Something else I need',
  ),
];

const List<String> kPregnancyLossCommunityCategories = [
  'All',
  'Grief and emotional support',
  'Follow-up care questions',
  'Talking to providers',
  'Remembering and reflecting',
  'Support for the future',
];

const List<String> kPregnancyLossProviderPrompts = [
  'What follow-up care do I need?',
  'What symptoms should I watch for?',
  'Can you explain what happened in plain language?',
  'What support resources are available?',
  'What should I know for the future, if or when I’m ready?',
];

/// Maps preference ids to home secondary card visibility.
const Map<String, List<String>> kPreferenceToHomeCardIds = {
  PregnancyLossPreferenceId.emotionalGrief: ['emotional', 'crisis'],
  PregnancyLossPreferenceId.understanding: ['learning'],
  PregnancyLossPreferenceId.bodyCare: ['body_care', 'learning'],
  PregnancyLossPreferenceId.providerTalk: ['provider_questions'],
  PregnancyLossPreferenceId.futureReady: ['future', 'learning'],
  PregnancyLossPreferenceId.practical: ['resources', 'crisis'],
  PregnancyLossPreferenceId.somethingElse: ['resources'],
};

/// Default cards when user skips preferences (gentle essentials only).
const List<String> kPregnancyLossDefaultHomeCardIds = [
  'primary',
  'emotional',
  'body_care',
  'provider_questions',
  'learning',
  'community',
  'crisis',
  'resources',
];

List<String> pregnancyLossVisibleHomeCards(List<String> preferences) {
  if (preferences.isEmpty) return kPregnancyLossDefaultHomeCardIds;
  final ids = <String>{'primary', 'learning', 'community', 'crisis', 'resources'};
  for (final pref in preferences) {
    ids.addAll(kPreferenceToHomeCardIds[pref] ?? []);
  }
  return ids.toList();
}
