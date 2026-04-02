/// NPI Taxonomy Code mappings for maternal health specialties
/// Maps specialty display names to NPI taxonomy codes
class NpiTaxonomyCodes {
  // Specialty display name -> NPI taxonomy code
  static const Map<String, String> specialtyToCode = {
    'OB-GYN': '207V00000X', // Obstetrics & Gynecology
    'Obstetrics': '207V00000X',
    'Gynecology': '207V00000X',
    'Maternal-Fetal Medicine': '207VM0101X', // Maternal & Fetal Medicine
    'Reproductive Endocrinology': '207VE0102X', // Reproductive Endocrinology
    'Gynecologic Oncology': '207VX0201X', // Gynecologic Oncology
    'Urogynecology': '207VX0202X', // Female Pelvic Medicine and Reconstructive Surgery
    'Certified Nurse Midwife': '367A00000X', // Advanced Practice Midwife
    'Nurse Midwife Individual': '367A00000X',
    'Nurse Midwife (Individual)': '367A00000X',
    'Midwifery': '367A00000X',
    'Nurse Practitioner': '363L00000X', // Nurse Practitioner
    'Women\'s Health Nurse Practitioner': '363LW0102X', // Women's Health Nurse Practitioner
    'Family Nurse Practitioner': '363LF0000X', // Family Nurse Practitioner
    'Physician/Osteopath (OB-GYN)': '207V00000X',
    'Physician/Osteopath (Family Medicine)': '208D00000X', // General Practice
  };

  // Get taxonomy code for a specialty
  static String? getTaxonomyCode(String specialty) {
    // Try exact match first
    if (specialtyToCode.containsKey(specialty)) {
      return specialtyToCode[specialty];
    }
    
    // Try case-insensitive match
    final lowerSpecialty = specialty.toLowerCase();
    for (var entry in specialtyToCode.entries) {
      if (entry.key.toLowerCase() == lowerSpecialty) {
        return entry.value;
      }
    }
    
    // Try partial match for common variations
    if (lowerSpecialty.contains('ob') && lowerSpecialty.contains('gyn')) {
      return '207V00000X'; // OB-GYN
    }
    if (lowerSpecialty.contains('midwife')) {
      return '367A00000X'; // Midwife
    }
    if (lowerSpecialty.contains('nurse practitioner')) {
      return '363L00000X'; // Nurse Practitioner
    }
    
    return null;
  }

  // Check if specialty is mappable to NPI taxonomy
  static bool isMappable(String specialty) {
    return getTaxonomyCode(specialty) != null;
  }

  // Note: Doula is NOT in NPI taxonomy - must use Medicaid directory or user submissions
  static bool isDoula(String specialty) {
    final lower = specialty.toLowerCase();
    return lower.contains('doula');
  }
}
