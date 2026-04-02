/// Provider Type Codes for Ohio Medicaid API
/// Maps provider type IDs to display names
/// Based on official API: https://ohiomedicaidprovider.com/PublicSearchAPI.aspx
class ProviderTypes {
  // Provider type ID -> Display name
  // IMPORTANT: Single-digit codes (1-9) are stored WITH leading zeros ("01", "02", "09") to match API format
  static const Map<String, String> typeMap = {
    '23': 'Acupuncturist',
    '53': 'Adaptive Behavior Service Provider',
    '82': 'Ambulance',
    '46': 'Ambulatory Surgery Center',
    '68': 'Anesthesia Assistant Individual',
    '43': 'Audiologist Individual',
    '96': 'Behavioral Health Para-professionals',
    '73': 'Certified Registered Nurse Anesthetist Individual',
    '54': 'Chemical Dependency',
    '27': 'Chiropractor Individual',
    '50': 'Clinic',
    '47': 'Clinical Counseling',
    '65': 'Clinical Nurse Specialist Individual',
    '30': 'Dentist Individual',
    '85': 'Dodd Targeted Case Management',
    '09': 'Doula', // With leading zero to match API format
    '76': 'Durable Medical Equipment Supplier',
    '59': 'End-stage Renal Disease Clinic',
    '78': 'Enhanced Care Management',
    '12': 'Federally Qualified Health Center',
    '11': 'Free Standing Birth Center',
    '06': 'Help Me Grow', // With leading zero to match API format
    '74': 'Home And Community Based Oda Assisted Living',
    '44': 'Hospice',
    '01': 'Hospital', // With leading zero to match API format
    '79': 'Independent Diagnostic Testing Facility',
    '80': 'Independent Laboratory',
    '19': 'Managed Care Organization Panel Provider Only',
    '52': 'Marriage And Family Therapy',
    '28': 'Medicaid School Program',
    '60': 'Medicare Certified Home Health Agency',
    '51': 'Mental Health Clinic',
    '26': 'Non-agency Home Care Attendant',
    '38': 'Non-agency Nurse -- Rn Or Lpn',
    '25': 'Non-agency Personal Care Aide',
    '89': 'Non-state Operated Icf-dd',
    '71': 'Nurse Midwife Individual',
    '72': 'Nurse Practitioner Individual',
    '86': 'Nursing Facility',
    '41': 'Occupational Therapist, Individual',
    '84': 'Ohio Department Of Mental Health Provider',
    '95': 'Omhas Certified/licensed Treatment Program',
    '75': 'Optician/ocularist',
    '35': 'Optometrist Individual',
    '16': 'Other Accredited Home Health Agency',
    '04': 'Outpatient Health Facility', // With leading zero to match API format
    '08': 'Pace', // With leading zero to match API format
    '10': 'Pediatric Recovery Center',
    '69': 'Pharmacist',
    '70': 'Pharmacy',
    '39': 'Physical Therapist, Individual',
    '24': 'Physician Assistant',
    '20': 'Physician/osteopath Individual',
    '36': 'Podiatrist Individual',
    '81': 'Portable X-ray Supplier',
    '31': 'Professional Dental Group',
    '21': 'Professional Medical Group',
    '02': 'Psychiatric Hospital', // With leading zero to match API format
    '03': 'Psychiatric Residential Treatment Facility', // With leading zero to match API format
    '42': 'Psychology',
    '07': 'Registered Dietitian Nutritionist', // With leading zero to match API format
    '05': 'Rural Health Clinic', // With leading zero to match API format
    '37': 'Social Work',
    '40': 'Speech Language Pathologist Individual',
    '88': 'State Operated Icf-dd',
    '55': 'Waivered Services Individual',
    '45': 'Waivered Services Organization',
    '83': 'Wheelchair Van',
  };

  // Display name -> Provider type ID (reverse lookup)
  // Includes aliases for common search terms
  static final Map<String, String> displayToId = {
    for (var entry in typeMap.entries) entry.value: entry.key,
    // Aliases for common search terms
    'Therapist': '47', // Map to Clinical Counseling
    'Mental Health Therapist': '47',
    'Counselor': '47',
    'Therapy': '47',
  };

  // MVP Priority types (most commonly searched)
  // Updated to match official API codes (with leading zeros for single digits)
  static const List<String> mvpTypes = ['01', '71', '11', '09', '20', '72', '37', '39'];

  // Get display name for a provider type ID
  // Handles both single-digit (1-9) with leading zeros and double-digit (10+) codes
  static String? getDisplayName(String typeId) {
    // Normalize: ensure single digits have leading zeros to match API format
    final normalizedId = _normalizeTypeId(typeId);
    return typeMap[normalizedId];
  }

  // Get provider type ID for a display name
  static String? getTypeId(String displayName) {
    return displayToId[displayName];
  }

  // Normalize provider type ID (add leading zeros for single digits)
  // API uses single digits (1-9) WITH leading zeros ("01", "02", "09")
  static String _normalizeTypeId(String typeId) {
    final numId = int.tryParse(typeId);
    if (numId != null && numId >= 1 && numId <= 9) {
      return typeId.padLeft(2, '0'); // Add leading zero (API format: "01", "09")
    }
    return typeId; // Return as-is for double digits
  }

  // Validate known-good mappings (for debugging/testing)
  // Call this during development to verify mappings are correct
  static void validateMappings() {
    final assertions = [
      _assertMapping('Hospital', '01'),
      _assertMapping('Doula', '09'),
      _assertMapping('Nurse Midwife Individual', '71'),
      _assertMapping('Physician/osteopath Individual', '20'),
      _assertMapping('Free Standing Birth Center', '11'),
      _assertMapping('Social Work', '37'),
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
