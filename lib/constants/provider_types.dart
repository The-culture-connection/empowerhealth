/// Provider Type Codes for Ohio Medicaid API
/// Maps provider type IDs to display names
class ProviderTypes {
  // Provider type ID -> Display name
  static const Map<String, String> typeMap = {
    '23': 'Advanced Practice Registered Nurse',
    '53': 'Audiologist',
    '82': 'Behavioral Health Provider',
    '46': 'Certified Nurse Midwife',
    '68': 'Certified Registered Nurse Anesthetist',
    '43': 'Chiropractor',
    '96': 'Clinical Nurse Specialist',
    '73': 'Community Health Worker',
    '54': 'Dentist',
    '27': 'Dietitian/Nutritionist',
    '50': 'Doula',
    '47': 'Emergency Medical Technician',
    '65': 'Family Nurse Practitioner',
    '30': 'Health Educator',
    '85': 'Home Health Agency',
    '01': 'Hospital',
    '76': 'Licensed Clinical Social Worker',
    '59': 'Licensed Independent Social Worker',
    '78': 'Licensed Professional Clinical Counselor',
    '12': 'Licensed Practical Nurse',
    '11': 'Free Standing Birth Center',
    '06': 'Medical Doctor',
    '74': 'Mental Health Counselor',
    '44': 'Nurse Practitioner',
    '09': 'OB-GYN',
    '79': 'Occupational Therapist',
    '80': 'Optometrist',
    '19': 'Osteopathic Physician',
    '52': 'Paramedic',
    '28': 'Pharmacist',
    '60': 'Physical Therapist',
    '51': 'Physician Assistant',
    '26': 'Podiatrist',
    '38': 'Psychiatric Nurse',
    '25': 'Psychiatrist',
    '89': 'Psychologist',
    '71': 'Nurse Midwife Individual',
    '72': 'Registered Nurse',
    '86': 'Respiratory Therapist',
    '41': 'Speech-Language Pathologist',
    '84': 'Substance Use Disorder Counselor',
    '95': 'Therapist',
    '75': 'Vision Care Provider',
    '35': 'Women\'s Health Nurse Practitioner',
    '16': 'X-Ray Technician',
    '04': 'Certified Professional Midwife',
    '08': 'Community Midwife',
    '10': 'Lay Midwife',
    '69': 'Nurse Midwife Group',
    '70': 'Nurse Midwife Practice',
    '39': 'Perinatal Nurse',
    '24': 'Lactation Consultant',
    '20': 'Physician / Osteopath Individual',
    '36': 'Postpartum Doula',
    '81': 'Antepartum Doula',
    '31': 'Prenatal Educator',
    '21': 'Childbirth Educator',
    '02': 'Maternal-Fetal Medicine Specialist',
    '03': 'Reproductive Endocrinologist',
    '42': 'Gynecologic Oncologist',
    '07': 'Urogynecologist',
    '05': 'Reproductive Surgeon',
    '37': 'Perinatal Social Worker',
    '40': 'Perinatal Mental Health Specialist',
    '88': 'Perinatal Nutritionist',
    '55': 'Perinatal Physical Therapist',
    '45': 'Perinatal Occupational Therapist',
    '83': 'Perinatal Massage Therapist',
  };

  // Display name -> Provider type ID (reverse lookup)
  static final Map<String, String> displayToId = {
    for (var entry in typeMap.entries) entry.value: entry.key
  };

  // MVP Priority types (most commonly searched)
  static const List<String> mvpTypes = ['01', '71', '11', '09', '50', '46', '44', '20'];

  // Get display name for a provider type ID
  static String? getDisplayName(String typeId) {
    return typeMap[typeId];
  }

  // Get provider type ID for a display name
  static String? getTypeId(String displayName) {
    return displayToId[displayName];
  }

  // Validate known-good mappings (for debugging/testing)
  // Call this during development to verify mappings are correct
  static void validateMappings() {
    final assertions = [
      _assertMapping('Hospital', '01'),
      _assertMapping('OB-GYN', '09'),
      _assertMapping('Doula', '50'),
      _assertMapping('Nurse Midwife Individual', '71'),
      _assertMapping('Physician / Osteopath Individual', '20'),
      _assertMapping('Free Standing Birth Center', '11'),
    ];
    
    final failures = assertions.where((a) => !a['passed'] as bool).toList();
    if (failures.isNotEmpty) {
      print('❌ Provider type mapping validation failed:');
      for (var failure in failures) {
        print('   ${failure['message']}');
      }
      throw AssertionError('Provider type mappings are incorrect');
    }
    print('✅ Provider type mappings validated successfully');
  }

  static Map<String, dynamic> _assertMapping(String displayName, String expectedId) {
    final actualId = getTypeId(displayName);
    final passed = actualId == expectedId;
    return {
      'passed': passed,
      'message': passed 
        ? '✅ "$displayName" → "$expectedId"'
        : '❌ "$displayName" → expected "$expectedId" but got "$actualId"',
    };
  }

  // Get all provider types as list of {id, name} maps
  static List<Map<String, String>> getAllTypes() {
    return typeMap.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
  }

  // Get MVP types as list
  static List<Map<String, String>> getMvpTypes() {
    return mvpTypes
        .map((id) => {
              'id': id,
              'name': typeMap[id] ?? 'Unknown',
            })
        .toList();
  }
}

/// Health Plan options for Ohio Medicaid
class HealthPlans {
  static const List<String> plans = [
    'Buckeye',
    'CareSource',
    'Molina',
    'UnitedHealthcare',
    'Anthem',
    'Aetna',
  ];

  static bool isValid(String plan) {
    return plans.contains(plan);
  }
}

/// Specialty options (curated list for typeahead)
class Specialties {
  static const List<String> specialties = [
    'Obstetrics',
    'Gynecology',
    'OB-GYN',
    'Maternal-Fetal Medicine',
    'Reproductive Endocrinology',
    'Gynecologic Oncology',
    'Urogynecology',
    'Midwifery',
    'Doula Services',
    'Lactation Consulting',
    'Perinatal Mental Health',
    'High-Risk Pregnancy',
    'VBAC Support',
    'Birth Trauma',
    'Postpartum Care',
    'Prenatal Care',
    'Family Planning',
    'Infertility',
    'Menopause',
    'Pelvic Health',
  ];

  static List<String> search(String query) {
    if (query.isEmpty) return specialties;
    final lowerQuery = query.toLowerCase();
    return specialties
        .where((s) => s.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
