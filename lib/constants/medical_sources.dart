import 'package:url_launcher/url_launcher.dart';

/// Curated, authoritative medical/health sources used for in-app citations.
///
/// App Store Guideline 1.4.1 (Physical Harm) requires that health and medical
/// information include citations to trusted sources. These references are
/// hand-curated (not AI-generated) so the links are accurate and stable.
///
/// [MedicalSource.defaults] is shown on every health-content screen.
/// Topic-specific sources are added on top via [MedicalSources.forTopic].
class MedicalSource {
  final String title;
  final String organization;
  final String url;

  const MedicalSource({
    required this.title,
    required this.organization,
    required this.url,
  });

  Uri get uri => Uri.parse(url);
}

abstract final class MedicalSources {
  /// Always-shown, broadly applicable maternal/general health authorities.
  static const List<MedicalSource> defaults = [
    MedicalSource(
      title: 'Pregnancy & maternal health information',
      organization: 'American College of Obstetricians and Gynecologists (ACOG)',
      url: 'https://www.acog.org/womens-health',
    ),
    MedicalSource(
      title: 'Pregnancy, maternal & infant health',
      organization: 'Centers for Disease Control and Prevention (CDC)',
      url: 'https://www.cdc.gov/reproductive-health/',
    ),
    MedicalSource(
      title: 'Health topics & medical encyclopedia',
      organization: 'MedlinePlus, U.S. National Library of Medicine (NIH)',
      url: 'https://medlineplus.gov/pregnancy.html',
    ),
    MedicalSource(
      title: "Women's health A–Z",
      organization: 'Office on Women’s Health, U.S. Dept. of Health & Human Services',
      url: 'https://www.womenshealth.gov/pregnancy',
    ),
  ];

  /// Topic keyword -> additional sources to surface alongside [defaults].
  static const Map<String, List<MedicalSource>> _byKeyword = {
    'loss': [
      MedicalSource(
        title: 'Pregnancy & infant loss support',
        organization: 'March of Dimes',
        url: 'https://www.marchofdimes.org/find-support/topics/miscarriage-loss-grief',
      ),
      MedicalSource(
        title: 'Miscarriage & stillbirth information',
        organization: 'ACOG',
        url: 'https://www.acog.org/womens-health/faqs/early-pregnancy-loss',
      ),
    ],
    'grief': [
      MedicalSource(
        title: 'Pregnancy & infant loss support',
        organization: 'March of Dimes',
        url: 'https://www.marchofdimes.org/find-support/topics/miscarriage-loss-grief',
      ),
    ],
    'mental': [
      MedicalSource(
        title: 'Maternal mental health & depression',
        organization: 'Office on Women’s Health',
        url: 'https://www.womenshealth.gov/mental-health/mental-health-conditions/postpartum-depression',
      ),
      MedicalSource(
        title: '988 Suicide & Crisis Lifeline',
        organization: 'SAMHSA',
        url: 'https://988lifeline.org/',
      ),
    ],
    'emotional': [
      MedicalSource(
        title: 'Postpartum depression & emotional health',
        organization: 'Office on Women’s Health',
        url: 'https://www.womenshealth.gov/mental-health/mental-health-conditions/postpartum-depression',
      ),
      MedicalSource(
        title: '988 Suicide & Crisis Lifeline',
        organization: 'SAMHSA',
        url: 'https://988lifeline.org/',
      ),
    ],
    'depression': [
      MedicalSource(
        title: 'Perinatal depression',
        organization: 'National Institute of Mental Health (NIMH)',
        url: 'https://www.nimh.nih.gov/health/publications/perinatal-depression',
      ),
    ],
    'newborn': [
      MedicalSource(
        title: 'Newborn & infant care',
        organization: 'American Academy of Pediatrics (HealthyChildren.org)',
        url: 'https://www.healthychildren.org/English/ages-stages/baby/',
      ),
    ],
    'breastfeed': [
      MedicalSource(
        title: 'Breastfeeding guidance',
        organization: 'CDC',
        url: 'https://www.cdc.gov/breastfeeding/',
      ),
    ],
    'nutrition': [
      MedicalSource(
        title: 'Nutrition during pregnancy',
        organization: 'ACOG',
        url: 'https://www.acog.org/womens-health/faqs/nutrition-during-pregnancy',
      ),
    ],
    'labor': [
      MedicalSource(
        title: 'Labor, delivery & postpartum care',
        organization: 'ACOG',
        url: 'https://www.acog.org/womens-health/faqs/labor-and-delivery',
      ),
    ],
    'rights': [
      MedicalSource(
        title: 'Your rights as a patient',
        organization: 'U.S. Dept. of Health & Human Services',
        url: 'https://www.hhs.gov/hipaa/for-individuals/index.html',
      ),
    ],
  };

  /// Returns [defaults] plus any sources whose keyword appears in [topic].
  /// De-duplicates by URL while preserving order (topic-specific first).
  static List<MedicalSource> forTopic(String? topic) {
    final extras = <MedicalSource>[];
    final lower = (topic ?? '').toLowerCase();
    if (lower.isNotEmpty) {
      _byKeyword.forEach((keyword, sources) {
        if (lower.contains(keyword)) extras.addAll(sources);
      });
    }
    final combined = [...extras, ...defaults];
    final seen = <String>{};
    return [
      for (final s in combined)
        if (seen.add(s.url)) s,
    ];
  }
}

/// Opens a citation link in the external browser. Returns false on failure.
Future<bool> launchMedicalSource(MedicalSource source) {
  return launchUrl(source.uri, mode: LaunchMode.externalApplication);
}
