/// Neutral support-need ids for the universal immediate support pathway.
/// These do not describe reproductive events and are not persisted to Firestore.
abstract final class ImmediateSupportOptionId {
  static const emotional = 'emotional';
  static const understandNext = 'understand_next';
  static const followUpCare = 'follow_up_care';
  static const providerTalk = 'provider_talk';
  static const findResources = 'find_resources';
  static const transportation = 'transportation';
  static const somethingElse = 'something_else';
}

class ImmediateSupportOption {
  const ImmediateSupportOption({required this.id, required this.label});

  final String id;
  final String label;
}

const List<ImmediateSupportOption> kImmediateSupportOptions = [
  ImmediateSupportOption(
    id: ImmediateSupportOptionId.emotional,
    label: 'Emotional support',
  ),
  ImmediateSupportOption(
    id: ImmediateSupportOptionId.understandNext,
    label: 'Help understanding what to do next',
  ),
  ImmediateSupportOption(
    id: ImmediateSupportOptionId.followUpCare,
    label: 'Follow-up care questions',
  ),
  ImmediateSupportOption(
    id: ImmediateSupportOptionId.providerTalk,
    label: 'Help talking to my provider',
  ),
  ImmediateSupportOption(
    id: ImmediateSupportOptionId.findResources,
    label: 'Help finding support or resources',
  ),
  ImmediateSupportOption(
    id: ImmediateSupportOptionId.transportation,
    label: 'Transportation or appointment help',
  ),
  ImmediateSupportOption(
    id: ImmediateSupportOptionId.somethingElse,
    label: 'Something else I need',
  ),
];

const String kImmediateSupportDisclaimer =
    'Here are support options that may help right now. These are educational resources and external support services. EmpowerHealth Watch does not provide counseling or emergency response.';

const String kImmediateSupport988Disclaimer =
    'If you need to talk to someone now, you can contact 988 by call, text, or chat. This connects you to the 988 Suicide & Crisis Lifeline, not EmpowerHealth Watch.';

const String kImmediateSupportSafetyGuidance =
    'If you feel unsafe, have severe symptoms, or believe you need urgent medical care, contact your provider or seek emergency care.';

const String kImmediateSupportEmotionalSafetyGuidance =
    'If you feel like you may hurt yourself or cannot stay safe, call or text 988 for immediate support.';
