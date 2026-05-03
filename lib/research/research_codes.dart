// Numeric codes aligned with admindash/functions/src/research/researchFieldSpec.ts

int recruitmentSourceCode(String? source) {
  switch (source) {
    case 'doula':
    case 'chw':
    case 'home_visitor':
    case 'cbo':
    case 'event':
      return 2;
    case 'social_media':
      return 3;
    case 'research_participant':
      return 4;
    case 'other':
      return 6;
    default:
      return 7;
  }
}

int recruitmentPathwayCode({required bool hasPrimaryProvider}) {
  return hasPrimaryProvider ? 1 : 2;
}

int insuranceTypeCodeFromProfileLabel(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.contains('medicaid')) return 1;
  if (s.contains('medicare')) return 2;
  if (s.contains('private')) return 3;
  if (s.contains('uninsured')) return 4;
  if (s.contains('other')) return 5;
  return 6;
}

/// UI order for baseline insurance (codes 1–6).
const List<MapEntry<int, String>> kInsuranceTypeOptions = [
  MapEntry(1, 'Medicaid'),
  MapEntry(2, 'Medicare'),
  MapEntry(3, 'Private / commercial'),
  MapEntry(4, 'Uninsured / self-pay'),
  MapEntry(5, 'Other (specify)'),
  MapEntry(6, 'Prefer not to say / unknown'),
];

const List<MapEntry<int, String>> kSupportPersonNavOptions = [
  MapEntry(1, 'Yes'),
  MapEntry(2, 'Partly'),
  MapEntry(3, 'No'),
  MapEntry(4, "Didn't try"),
  MapEntry(5, "Didn't know how"),
  MapEntry(6, "Couldn't access"),
];
