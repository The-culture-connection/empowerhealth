import 'package:flutter/material.dart';

/// Canonical external support links used across care check-in, emotional support, and profile flows.
class AppExternalResource {
  const AppExternalResource({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.category,
    this.icon,
    this.phoneDisplay,
    this.phoneTelUri,
  });

  final String id;
  final String title;
  final String description;
  final String url;
  final String category;
  final IconData? icon;
  /// Human-readable phone line (e.g. 1-833-TLC-MAMA).
  final String? phoneDisplay;
  /// `tel:` URI for [launchAppExternalPhone].
  final String? phoneTelUri;
}

abstract final class AppResourceCategory {
  static const benefits = 'Benefits & essentials';
  static const navigation = 'Care navigation';
  static const mentalHealth = 'Mental health & wellness';
  static const crisis = 'Crisis support';
  static const advocacy = 'Maternal health & advocacy';
  static const healthEducation = 'Health education';

  static const List<String> all = [
    benefits,
    navigation,
    mentalHealth,
    crisis,
    advocacy,
    healthEducation,
  ];
}

const List<AppExternalResource> kAppExternalResources = [
  // Benefits & essentials
  AppExternalResource(
    id: 'wic',
    title: 'WIC — nutrition support',
    description:
        'USDA’s Special Supplemental Nutrition Program for Women, Infants, and Children — healthy foods, nutrition education, and breastfeeding support.',
    url: 'https://www.fns.usda.gov/wic',
    category: AppResourceCategory.benefits,
    icon: Icons.restaurant_rounded,
  ),
  AppExternalResource(
    id: 'medicaid',
    title: 'Medicaid information',
    description: 'Learn about Medicaid coverage and how to apply.',
    url: 'https://www.medicaid.gov/',
    category: AppResourceCategory.benefits,
    icon: Icons.health_and_safety_outlined,
  ),

  // Care navigation
  AppExternalResource(
    id: '211',
    title: '211 — community help',
    description:
        'Free, confidential connection to local help with housing, utilities, food, transportation, and more.',
    url: 'https://www.211.org/',
    category: AppResourceCategory.navigation,
    icon: Icons.place_outlined,
  ),
  AppExternalResource(
    id: '211_local',
    title: 'Find your local 211',
    description: 'Look up 211 services in your area.',
    url: 'https://www.211.org/about-us/your-local-211',
    category: AppResourceCategory.navigation,
    icon: Icons.map_outlined,
  ),

  // Mental health & wellness
  AppExternalResource(
    id: 'maternal_mental_health_hotline',
    title: 'National Maternal Mental Health Hotline',
    description:
        'Free, confidential, 24/7 support for pregnant and new moms in English and Spanish. Call, text, or chat.',
    url:
        'https://mchb.hrsa.gov/programs-impact/national-maternal-mental-health-hotline',
    category: AppResourceCategory.mentalHealth,
    icon: Icons.support_agent_rounded,
    phoneDisplay: '1-833-TLC-MAMA (1-833-853-6262)',
    phoneTelUri: 'tel:+18338536262',
  ),
  AppExternalResource(
    id: 'hrsa_healthy_start',
    title: 'HRSA Healthy Start & maternal health',
    description:
        'Federal programs that support healthy pregnancies, births, and early childhood in underserved communities.',
    url: 'https://mchb.hrsa.gov/programs-impact/focus-areas/maternal-health',
    category: AppResourceCategory.mentalHealth,
    icon: Icons.pregnant_woman_rounded,
  ),
  AppExternalResource(
    id: 'postpartum_psi',
    title: 'Postpartum Support International',
    description:
        'Peer support and resources for pregnancy and postpartum mental health.',
    url: 'https://www.postpartum.net/',
    category: AppResourceCategory.mentalHealth,
    icon: Icons.favorite_border_rounded,
  ),
  AppExternalResource(
    id: 'hhs_womens_health_pp',
    title: 'Postpartum depression — HHS Office on Women’s Health',
    description:
        'Information and support for finding help with postpartum depression.',
    url: 'https://www.womenshealth.gov/mental-health/postpartum-depression',
    category: AppResourceCategory.mentalHealth,
    icon: Icons.psychology_outlined,
  ),
  AppExternalResource(
    id: 'samhsa_helpline',
    title: 'SAMHSA National Helpline',
    description:
        '24-hour free, confidential treatment referral and information about mental health and substance use (English & Spanish).',
    url: 'https://www.samhsa.gov/find-help/national-helpline',
    category: AppResourceCategory.mentalHealth,
    icon: Icons.call_outlined,
    phoneDisplay: '1-800-662-HELP (4357)',
    phoneTelUri: 'tel:+18006624357',
  ),

  // Crisis support
  AppExternalResource(
    id: '988',
    title: '988 Suicide & Crisis Lifeline',
    description:
        'Free, confidential support by call, text, or chat — available 24/7.',
    url: 'https://988lifeline.org/',
    category: AppResourceCategory.crisis,
    icon: Icons.emergency_rounded,
    phoneDisplay: 'Call or text 988',
    phoneTelUri: 'tel:988',
  ),
  AppExternalResource(
    id: '988_chat',
    title: '988 — online chat',
    description: 'Chat with a trained counselor (external site).',
    url: 'https://988lifeline.org/chat/',
    category: AppResourceCategory.crisis,
    icon: Icons.chat_bubble_outline_rounded,
  ),

  // Maternal health & advocacy
  AppExternalResource(
    id: 'black_maternal_health_resources',
    title: 'Resources for new & pregnant moms',
    description:
        'Black Maternal Health Caucus — maternal mental health hotline info, warning signs, and trusted support links.',
    url:
        'https://blackmaternalhealthcaucus-underwood.house.gov/resources-new-and-pregnant-moms',
    category: AppResourceCategory.advocacy,
    icon: Icons.groups_rounded,
  ),
  AppExternalResource(
    id: 'cdc_hear_her',
    title: 'CDC Hear Her campaign',
    description:
        'Urgent maternal warning signs during and after pregnancy — know when to get help.',
    url: 'https://www.cdc.gov/hearher/index.html',
    category: AppResourceCategory.advocacy,
    icon: Icons.campaign_outlined,
  ),

  // Health education (CDC)
  AppExternalResource(
    id: 'cdc_breastfeeding',
    title: 'Breastfeeding guidance (CDC)',
    description: 'Evidence-based breastfeeding information.',
    url: 'https://www.cdc.gov/breastfeeding/',
    category: AppResourceCategory.healthEducation,
    icon: Icons.child_care_outlined,
  ),
  AppExternalResource(
    id: 'cdc_pumping',
    title: 'Pumping support (CDC)',
    description: 'How to pump and store breast milk safely.',
    url: 'https://www.cdc.gov/breastfeeding/pumping/index.htm',
    category: AppResourceCategory.healthEducation,
    icon: Icons.water_drop_outlined,
  ),
  AppExternalResource(
    id: 'cdc_formula',
    title: 'Formula feeding (CDC)',
    description: 'Formula feeding basics for infants.',
    url:
        'https://www.cdc.gov/nutrition/infantandtoddlernutrition/formula-feeding/index.html',
    category: AppResourceCategory.healthEducation,
    icon: Icons.local_drink_outlined,
  ),
  AppExternalResource(
    id: 'cdc_well_child',
    title: 'Well-child visits (CDC)',
    description: 'What to expect at pediatric checkups.',
    url: 'https://www.cdc.gov/parents/infants/visits/index.html',
    category: AppResourceCategory.healthEducation,
    icon: Icons.medical_services_outlined,
  ),
];

AppExternalResource? appExternalResourceById(String id) {
  for (final r in kAppExternalResources) {
    if (r.id == id) return r;
  }
  return null;
}

List<AppExternalResource> appExternalResourcesInCategory(String category) {
  return kAppExternalResources.where((r) => r.category == category).toList();
}

/// Maps a catalog [resourceId] to a section filter for deep-linked opens.
String? appResourceCategoryForResourceId(String? resourceId) {
  if (resourceId == null) return null;
  final resource = appExternalResourceById(resourceId);
  return resource?.category;
}

IconData appResourceIcon(AppExternalResource resource) {
  if (resource.icon != null) return resource.icon!;
  switch (resource.category) {
    case AppResourceCategory.benefits:
      return Icons.card_giftcard_outlined;
    case AppResourceCategory.navigation:
      return Icons.explore_outlined;
    case AppResourceCategory.mentalHealth:
      return Icons.self_improvement_outlined;
    case AppResourceCategory.crisis:
      return Icons.emergency_outlined;
    case AppResourceCategory.advocacy:
      return Icons.volunteer_activism_outlined;
    default:
      return Icons.menu_book_outlined;
  }
}
