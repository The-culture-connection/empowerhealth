import '../research/needs_checklist_screen.dart' show kCareNeedsChecklistItems;

/// Personalized support actions shown after care needs selection.
/// Care need [id]s match [kCareNeedsChecklistItems] / research `need_*` mapping.
enum CareSupportDestination {
  providers,
  /// My Visits list, or latest summary when [CareSupportAction.preferLatestVisitSummary].
  visitSummaries,
  assistant,
  pregnancyJourney,
  birthPlans,
  learnTab,
  rights,
  journal,
  community,
  externalUrl,
  /// In-app [AppResourcesScreen]; use [resourceId] when set.
  resources,
  birthLaborTopic,
  /// Calls Cloud Function and saves a personalized `learning_tasks` row.
  generateLearningModule,
}

class CareSupportAction {
  const CareSupportAction({
    required this.id,
    required this.label,
    required this.destination,
    this.assistantPrompt,
    this.externalUrl,
    this.birthLaborTopicId,
    this.preferLatestVisitSummary = false,
    this.learningModuleTopic,
    this.learningModuleDescription,
    this.resourceId,
  });

  final String id;
  final String label;
  final CareSupportDestination destination;
  final String? assistantPrompt;
  final String? externalUrl;
  final String? birthLaborTopicId;
  final bool preferLatestVisitSummary;
  final String? learningModuleTopic;
  final String? learningModuleDescription;
  final String? resourceId;
}

const String kCareCheckinReinforcementMessage =
    "We'll help you understand your options, prepare questions, and find support.";

/// Support tiles keyed by care need id (same ids as research checklist).
const Map<String, List<CareSupportAction>> kCareCheckinSupportByNeedId = {
  'prenatal-postpartum': [
    CareSupportAction(
      id: 'provider_find',
      label: 'Find a provider near me',
      destination: CareSupportDestination.providers,
    ),
    CareSupportAction(
      id: 'prepare_questions',
      label: 'Prepare questions for my next visit',
      destination: CareSupportDestination.visitSummaries,
      preferLatestVisitSummary: true,
    ),
    CareSupportAction(
      id: 'understand_symptoms',
      label: 'Understand my symptoms',
      destination: CareSupportDestination.assistant,
      assistantPrompt:
          'Help me understand my symptoms in plain language and what to ask my doctor or midwife.',
    ),
  ],
  'labor-delivery': [
    CareSupportAction(
      id: 'birth_plan',
      label: 'Create or review my birth plan',
      destination: CareSupportDestination.birthPlans,
    ),
    CareSupportAction(
      id: 'labor_expect',
      label: 'What to expect during labor',
      destination: CareSupportDestination.birthLaborTopic,
      birthLaborTopicId: 'labor-basics',
    ),
    CareSupportAction(
      id: 'labor_questions',
      label: 'Questions to ask my provider',
      destination: CareSupportDestination.birthLaborTopic,
      birthLaborTopicId: 'speak-up',
    ),
  ],
  'blood-pressure': [
    CareSupportAction(
      id: 'condition_meaning',
      label: 'What this condition means (plain language)',
      destination: CareSupportDestination.rights,
    ),
    CareSupportAction(
      id: 'track_symptoms',
      label: 'Track symptoms or health data (e.g., blood pressure)',
      destination: CareSupportDestination.journal,
    ),
    CareSupportAction(
      id: 'when_contact',
      label: 'When to contact a provider',
      destination: CareSupportDestination.rights,
    ),
  ],
  'mental-health': [
    CareSupportAction(
      id: 'talk_now',
      label: 'Talk to someone now',
      destination: CareSupportDestination.community,
    ),
    CareSupportAction(
      id: 'is_normal',
      label: 'What I’m feeling — is this normal?',
      destination: CareSupportDestination.pregnancyJourney,
    ),
    CareSupportAction(
      id: 'support_today',
      label: 'Simple ways to get support today',
      destination: CareSupportDestination.community,
    ),
  ],
  'lactation': [
    CareSupportAction(
      id: 'breastfeeding',
      label: 'Breastfeeding guidance',
      destination: CareSupportDestination.generateLearningModule,
      learningModuleTopic: 'Breastfeeding guidance',
      learningModuleDescription:
          'Plain-language breastfeeding support for you and your baby.',
    ),
    CareSupportAction(
      id: 'pumping',
      label: 'Pumping support',
      destination: CareSupportDestination.generateLearningModule,
      learningModuleTopic: 'Pumping support',
      learningModuleDescription:
          'How to pump safely and what to expect when expressing milk.',
    ),
    CareSupportAction(
      id: 'formula',
      label: 'Formula feeding guidance',
      destination: CareSupportDestination.generateLearningModule,
      learningModuleTopic: 'Formula feeding guidance',
      learningModuleDescription:
          'Formula feeding basics explained in simple, supportive language.',
    ),
  ],
  'infant-pediatric': [
    CareSupportAction(
      id: 'find_pediatric',
      label: 'Find a pediatric provider',
      destination: CareSupportDestination.providers,
    ),
    CareSupportAction(
      id: 'baby_visits',
      label: 'What happens at baby visits',
      destination: CareSupportDestination.assistant,
      assistantPrompt:
          'What usually happens at pediatric well-child visits for my baby? Explain in plain language what parents can expect.',
    ),
    CareSupportAction(
      id: 'questions_baby',
      label: 'Questions to ask',
      destination: CareSupportDestination.visitSummaries,
      preferLatestVisitSummary: true,
    ),
  ],
  'benefits': [
    CareSupportAction(
      id: 'wic_medicaid',
      label: 'Find WIC or Medicaid resources',
      destination: CareSupportDestination.resources,
      resourceId: 'wic',
    ),
    CareSupportAction(
      id: 'essentials',
      label: 'Access baby essentials (cribs, diapers, car seats)',
      destination: CareSupportDestination.resources,
      resourceId: '211',
    ),
    CareSupportAction(
      id: 'helpful_links',
      label: 'View all helpful links',
      destination: CareSupportDestination.resources,
    ),
    CareSupportAction(
      id: 'community_support',
      label: 'Connect with community support services',
      destination: CareSupportDestination.community,
    ),
  ],
  'transportation': [
    CareSupportAction(
      id: 'find_transport',
      label: 'Find transportation options',
      destination: CareSupportDestination.resources,
      resourceId: '211',
    ),
    CareSupportAction(
      id: 'plan_ride',
      label: 'Plan a ride',
      destination: CareSupportDestination.resources,
      resourceId: '211_local',
    ),
    CareSupportAction(
      id: 'missed_appt',
      label: 'What to do if you miss an appointment',
      destination: CareSupportDestination.visitSummaries,
    ),
  ],
  'other': [
    CareSupportAction(
      id: 'community_other',
      label: 'Connect with community',
      destination: CareSupportDestination.community,
    ),
  ],
};

List<CareSupportAction> careCheckinSupportActionsForNeeds(List<String> needIds) {
  final out = <CareSupportAction>[];
  final seen = <String>{};
  for (final id in needIds) {
    for (final action in kCareCheckinSupportByNeedId[id] ?? const []) {
      if (seen.add(action.id)) out.add(action);
    }
  }
  return out;
}

String? careCheckinSectionTitleForNeedId(String needId) {
  for (final n in kCareNeedsChecklistItems) {
    if (n['id'] == needId) return n['label'];
  }
  return null;
}
