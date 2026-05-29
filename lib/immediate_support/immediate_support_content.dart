import 'package:flutter/material.dart';

import '../app_router.dart';
import '../emotional_support/emotional_support_navigation.dart';
import '../resources/open_app_resource.dart';
import 'immediate_support_constants.dart';

class ImmediateSupportSectionConfig {
  const ImmediateSupportSectionConfig({
    required this.optionId,
    required this.headline,
    required this.supportMessage,
    required this.bullets,
    required this.tiles,
    this.prioritize988 = false,
  });

  final String optionId;
  final String headline;
  final String supportMessage;
  final List<String> bullets;
  final List<ImmediateSupportTile> tiles;
  final bool prioritize988;
}

class ImmediateSupportTile {
  const ImmediateSupportTile({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String id;
  final String label;
  final String subtitle;
  final Future<void> Function(BuildContext context) onTap;
}

/// Curated, evidence-based support content (988, PSI, SAMHSA, CDC, 211, ACOG-style guidance).
/// Plain-language only — not clinical advice or diagnosis.
List<ImmediateSupportSectionConfig> immediateSupportSectionsFor(
  Set<String> selectedIds,
) {
  if (selectedIds.isEmpty) {
    return [_emotionalSection(), _findResourcesSection()];
  }

  final configs = <ImmediateSupportSectionConfig>[];
  for (final id in kImmediateSupportOptions.map((o) => o.id)) {
    if (!selectedIds.contains(id)) continue;
    final section = _sectionFor(id);
    if (section != null) configs.add(section);
  }
  return configs;
}

ImmediateSupportSectionConfig? _sectionFor(String id) {
  switch (id) {
    case ImmediateSupportOptionId.emotional:
      return _emotionalSection();
    case ImmediateSupportOptionId.understandNext:
      return _understandNextSection();
    case ImmediateSupportOptionId.followUpCare:
      return _followUpCareSection();
    case ImmediateSupportOptionId.providerTalk:
      return _providerTalkSection();
    case ImmediateSupportOptionId.findResources:
      return _findResourcesSection();
    case ImmediateSupportOptionId.transportation:
      return _transportationSection();
    case ImmediateSupportOptionId.somethingElse:
      return _somethingElseSection();
    default:
      return null;
  }
}

ImmediateSupportSectionConfig _emotionalSection() {
  return ImmediateSupportSectionConfig(
    optionId: ImmediateSupportOptionId.emotional,
    headline: 'Emotional support',
    supportMessage: 'Your feelings are valid. You do not have to go through this alone.',
    prioritize988: true,
    bullets: const [
      'Stress and coping support — small steps like rest, hydration, and asking for help with one task can matter.',
      'Ways to care for yourself today — reduce non-essential tasks if you can; limit triggers if helpful.',
      'Grounding can help when overwhelmed: notice five things you see, four you feel, three you hear.',
      'Talking to someone may help — peer or professional support is available through external services.',
    ],
    tiles: [
      ImmediateSupportTile(
        id: 'journal',
        label: 'Private journal space',
        subtitle: 'Write what you feel — only you can see it',
        onTap: (ctx) async => openJournalTab(ctx),
      ),
      ImmediateSupportTile(
        id: 'psi',
        label: 'Postpartum Support International',
        subtitle: 'Peer support and provider directory (external)',
        onTap: (ctx) async => openAppResourceById(ctx, 'postpartum_psi'),
      ),
      ImmediateSupportTile(
        id: 'samhsa',
        label: 'SAMHSA treatment locator',
        subtitle: 'Find mental health and substance use support (external)',
        onTap: (ctx) async => openAppResourceById(ctx, 'samhsa_helpline'),
      ),
      ImmediateSupportTile(
        id: 'maternal_hotline',
        label: 'Maternal mental health hotline',
        subtitle: 'Free, confidential 24/7 support (external)',
        onTap: (ctx) async =>
            openAppResourceById(ctx, 'maternal_mental_health_hotline'),
      ),
    ],
  );
}

ImmediateSupportSectionConfig _understandNextSection() {
  return ImmediateSupportSectionConfig(
    optionId: ImmediateSupportOptionId.understandNext,
    headline: 'Help understanding what to do next',
    supportMessage: 'You deserve clear, compassionate information and support.',
    bullets: const [
      'Plain-language explanations can help you prepare for conversations with your care team.',
      'It is okay to ask providers to explain things again in everyday words.',
      'Organizing one or two next steps — a call, an appointment, or a question list — can reduce overwhelm.',
      'CDC Hear Her and similar public health resources describe warning signs worth discussing with a provider.',
    ],
    tiles: [
      ImmediateSupportTile(
        id: 'assistant',
        label: 'Ask in plain language',
        subtitle: 'Use the assistant to simplify terms — educational only, not diagnosis',
        onTap: (ctx) async {
          await Navigator.pushNamed(
            ctx,
            Routes.assistant,
            arguments:
                'Help me understand what to do next in plain language. I do not need a diagnosis — just clear next steps and questions I can ask my care team.',
          );
        },
      ),
      ImmediateSupportTile(
        id: 'cdc_hear_her',
        label: 'CDC Hear Her',
        subtitle: 'Urgent maternal warning signs to discuss with a provider (external)',
        onTap: (ctx) async => openAppResourceById(ctx, 'cdc_hear_her'),
      ),
      ImmediateSupportTile(
        id: 'rights',
        label: 'Know your rights in care',
        subtitle: 'Questions, consent, and respectful care',
        onTap: (ctx) async => Navigator.pushNamed(ctx, Routes.rights),
      ),
      ImmediateSupportTile(
        id: 'journal_next',
        label: 'Notes for your next step',
        subtitle: 'Capture questions or worries in your journal',
        onTap: (ctx) async => openJournalTab(ctx),
      ),
    ],
  );
}

ImmediateSupportSectionConfig _followUpCareSection() {
  return ImmediateSupportSectionConfig(
    optionId: ImmediateSupportOptionId.followUpCare,
    headline: 'Follow-up care questions',
    supportMessage: 'You deserve care, attention, and clear communication.',
    bullets: const [
      'Follow-up visits may review symptoms, recovery, and what to watch for between appointments.',
      'You can ask when to call the office versus when to seek urgent care.',
      'Keeping a simple log of symptoms or questions can help at your next visit.',
      'ACOG-style guidance: contact your provider for heavy bleeding, fever, severe pain, or symptoms your team lists as urgent.',
    ],
    tiles: [
      ImmediateSupportTile(
        id: 'appointments',
        label: 'My visits & summaries',
        subtitle: 'Review visit notes and prepare for follow-up',
        onTap: (ctx) async => Navigator.pushNamed(ctx, Routes.appointments),
      ),
      ImmediateSupportTile(
        id: 'assistant_followup',
        label: 'Questions for follow-up',
        subtitle: 'Draft plain-language questions for your care team',
        onTap: (ctx) async {
          await Navigator.pushNamed(
            ctx,
            Routes.assistant,
            arguments:
                'Help me prepare follow-up care questions for my provider in plain language. What symptoms should I watch for, and when should I call?',
          );
        },
      ),
      ImmediateSupportTile(
        id: 'cdc_hear_her_followup',
        label: 'When to contact a provider',
        subtitle: 'CDC Hear Her — warning signs (external)',
        onTap: (ctx) async => openAppResourceById(ctx, 'cdc_hear_her'),
      ),
    ],
  );
}

ImmediateSupportSectionConfig _providerTalkSection() {
  return ImmediateSupportSectionConfig(
    optionId: ImmediateSupportOptionId.providerTalk,
    headline: 'Help talking to my provider',
    supportMessage: 'You deserve to be heard and treated with care.',
    bullets: const [
      'You can ask: "Can you explain that in simpler words?"',
      'You can request more time, written instructions, or a follow-up visit.',
      'Bringing a support person to appointments is often allowed if you want one.',
      'It is okay to ask for another opinion or referral if you need more support.',
    ],
    tiles: [
      ImmediateSupportTile(
        id: 'journal_provider',
        label: 'Save questions for your visit',
        subtitle: 'Private journal — copy prompts before you go',
        onTap: (ctx) async => openJournalTab(ctx),
      ),
      ImmediateSupportTile(
        id: 'providers',
        label: 'Find a provider',
        subtitle: 'Search by location and type of care',
        onTap: (ctx) async => Navigator.pushNamed(ctx, Routes.providers),
      ),
      ImmediateSupportTile(
        id: 'assistant_provider',
        label: 'Practice what to say',
        subtitle: 'Plain-language phrases for your next conversation',
        onTap: (ctx) async {
          await Navigator.pushNamed(
            ctx,
            Routes.assistant,
            arguments:
                'Help me prepare words to ask my provider for clearer explanations and more support. Keep it plain and non-clinical.',
          );
        },
      ),
    ],
  );
}

ImmediateSupportSectionConfig _findResourcesSection() {
  return ImmediateSupportSectionConfig(
    optionId: ImmediateSupportOptionId.findResources,
    headline: 'Help finding support or resources',
    supportMessage: 'Support may look different for everyone. We\'ll help you explore your options.',
    bullets: const [
      'Community programs, WIC, Medicaid, and 211 can help with practical needs.',
      'Mental health directories and PSI connect you to external support — not in-app counseling.',
      'Local organizations vary by area; 211 can help you find options near you.',
    ],
    tiles: [
      ImmediateSupportTile(
        id: 'resources_all',
        label: 'All helpful links',
        subtitle: 'WIC, Medicaid, 211, 988, PSI, SAMHSA, CDC',
        onTap: (ctx) async => openAppResourcesScreen(ctx),
      ),
      ImmediateSupportTile(
        id: '211',
        label: '211 — local help',
        subtitle: 'Food, housing, transportation, and more (external)',
        onTap: (ctx) async => openAppResourceById(ctx, '211'),
      ),
      ImmediateSupportTile(
        id: 'wic',
        label: 'WIC nutrition support',
        subtitle: 'USDA program information (external)',
        onTap: (ctx) async => openAppResourceById(ctx, 'wic'),
      ),
      ImmediateSupportTile(
        id: 'community',
        label: 'Community space',
        subtitle: 'Connect with others at your own pace',
        onTap: (ctx) async => openCommunityTab(ctx),
      ),
    ],
  );
}

ImmediateSupportSectionConfig _transportationSection() {
  return ImmediateSupportSectionConfig(
    optionId: ImmediateSupportOptionId.transportation,
    headline: 'Transportation or appointment help',
    supportMessage: 'Getting to care can be difficult sometimes. Support is available.',
    bullets: const [
      '211 may connect you to local transportation, Medicaid non-emergency medical transport, or ride programs in your area.',
      'If you miss an appointment, you can call the office to reschedule — ask what to do before your next visit.',
      'Questions to ask when rescheduling: "Do I need any labs or forms before I come in?"',
    ],
    tiles: [
      ImmediateSupportTile(
        id: '211_transport',
        label: '211 — transportation & local help',
        subtitle: 'Find programs near you (external)',
        onTap: (ctx) async => openAppResourceById(ctx, '211'),
      ),
      ImmediateSupportTile(
        id: 'medicaid_transport',
        label: 'Medicaid information',
        subtitle: 'Coverage and benefits may include transport (external)',
        onTap: (ctx) async => openAppResourceById(ctx, 'medicaid'),
      ),
      ImmediateSupportTile(
        id: 'appointments_transport',
        label: 'My appointments & visits',
        subtitle: 'Review visits and plan your next step',
        onTap: (ctx) async => Navigator.pushNamed(ctx, Routes.appointments),
      ),
    ],
  );
}

ImmediateSupportSectionConfig _somethingElseSection() {
  return ImmediateSupportSectionConfig(
    optionId: ImmediateSupportOptionId.somethingElse,
    headline: 'Something else I need',
    supportMessage: 'Tell us what would feel helpful right now.',
    bullets: const [
      'You can share only what feels comfortable — nothing is required.',
      'The assistant can help organize questions or next steps in plain language.',
      'External hotlines and 211 are available if you need to talk to someone now.',
    ],
    tiles: [
      ImmediateSupportTile(
        id: 'assistant_other',
        label: 'Talk with the assistant',
        subtitle: 'Educational support only — not counseling or emergency response',
        onTap: (ctx) async {
          await Navigator.pushNamed(
            ctx,
            Routes.assistant,
            arguments:
                'I need help figuring out what support might help me right now. Please use plain language and suggest gentle next steps — no diagnosis.',
          );
        },
      ),
      ImmediateSupportTile(
        id: 'journal_other',
        label: 'Write in your journal',
        subtitle: 'Private space for your thoughts',
        onTap: (ctx) async => openJournalTab(ctx),
      ),
      ImmediateSupportTile(
        id: 'resources_other',
        label: 'Browse helpful links',
        subtitle: 'Trusted external resources',
        onTap: (ctx) async => openAppResourcesScreen(ctx),
      ),
    ],
  );
}
