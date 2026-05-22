/// Emotional support check-in option ids (stored on profile + analytics).
abstract final class EmotionalSupportOptionId {
  static const notMyself = 'not_myself';
  static const pregnancyLoss = 'pregnancy_loss';
  static const healthWorry = 'health_worry';
  static const hardAdjusting = 'hard_adjusting';
  static const needTalk = 'need_talk';
  static const scaryThoughts = 'scary_thoughts';
  static const somethingElse = 'something_else';
}

const List<EmotionalSupportCheckInOption> kEmotionalSupportCheckInOptions = [
  EmotionalSupportCheckInOption(
    id: EmotionalSupportOptionId.notMyself,
    label: 'I haven’t felt like myself since my pregnancy or birth',
  ),
  EmotionalSupportCheckInOption(
    id: EmotionalSupportOptionId.pregnancyLoss,
    label: 'I experienced a pregnancy loss',
  ),
  EmotionalSupportCheckInOption(
    id: EmotionalSupportOptionId.healthWorry,
    label: 'I’m worried about my health or my baby’s health',
  ),
  EmotionalSupportCheckInOption(
    id: EmotionalSupportOptionId.hardAdjusting,
    label: 'I’m having a hard time adjusting to everything',
  ),
  EmotionalSupportCheckInOption(
    id: EmotionalSupportOptionId.needTalk,
    label: 'I need someone to talk to',
  ),
  EmotionalSupportCheckInOption(
    id: EmotionalSupportOptionId.scaryThoughts,
    label: 'I’m having thoughts that scare or worry me',
  ),
  EmotionalSupportCheckInOption(
    id: EmotionalSupportOptionId.somethingElse,
    label: 'Something else is going on',
  ),
];

class EmotionalSupportCheckInOption {
  const EmotionalSupportCheckInOption({required this.id, required this.label});
  final String id;
  final String label;
}

bool emotionalSupportShowsCrisisCard(Set<String> selected) {
  return selected.contains(EmotionalSupportOptionId.needTalk) ||
      selected.contains(EmotionalSupportOptionId.scaryThoughts);
}

const String kEmotionalValidationTitle = 'Thank you for checking in 💜';
const String kEmotionalValidationBody =
    'A lot of people go through moments like this. Let’s find support that feels helpful right now.';

/// Future pregnancy-loss features (placeholder TODOs in UI).
const List<String> kPregnancyLossFutureTodos = [
  'Grief support resources',
  'Follow-up care guidance',
  'Emotional support pathways',
  'Provider support connections',
  'Future pregnancy support when you\'re ready',
];
