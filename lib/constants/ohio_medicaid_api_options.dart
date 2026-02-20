/// Constants for Ohio Medicaid API dropdown options
/// Based on https://ohiomedicaidprovider.com/PublicSearchAPI.aspx#
class OhioMedicaidApiOptions {
  // Program options
  static const List<String> programs = ['1', '2', '3']; // Add actual program codes as needed

  // Facility Type options (from API documentation)
  static const List<String> facilityTypes = [
    'Hospital',
    'Free Standing Birth Center',
    'Clinic',
    'Private Practice',
    'Community Health Center',
  ];

  // Primary Care Providers
  static const List<String> primaryCareProviders = ['Yes', 'No'];

  // Patient Gender options
  static const List<String> patientGenders = [
    'Male',
    'Female',
    'Other',
  ];

  // Provider Gender options
  static const List<String> providerGenders = [
    'Male',
    'Female',
    'Other',
  ];

  // County options (Ohio counties - abbreviated list, add more as needed)
  static const List<String> ohioCounties = [
    'Adams',
    'Allen',
    'Ashland',
    'Ashtabula',
    'Athens',
    'Auglaize',
    'Belmont',
    'Brown',
    'Butler',
    'Carroll',
    'Champaign',
    'Clark',
    'Clermont',
    'Clinton',
    'Columbiana',
    'Coshocton',
    'Crawford',
    'Cuyahoga',
    'Darke',
    'Defiance',
    'Delaware',
    'Erie',
    'Fairfield',
    'Fayette',
    'Franklin',
    'Fulton',
    'Gallia',
    'Geauga',
    'Greene',
    'Guernsey',
    'Hamilton',
    'Hancock',
    'Hardin',
    'Harrison',
    'Henry',
    'Highland',
    'Hocking',
    'Holmes',
    'Huron',
    'Jackson',
    'Jefferson',
    'Knox',
    'Lake',
    'Lawrence',
    'Licking',
    'Logan',
    'Lorain',
    'Lucas',
    'Madison',
    'Mahoning',
    'Marion',
    'Medina',
    'Meigs',
    'Mercer',
    'Miami',
    'Monroe',
    'Montgomery',
    'Morgan',
    'Morrow',
    'Muskingum',
    'Noble',
    'Ottawa',
    'Paulding',
    'Perry',
    'Pickaway',
    'Pike',
    'Portage',
    'Preble',
    'Putnam',
    'Richland',
    'Ross',
    'Sandusky',
    'Scioto',
    'Seneca',
    'Shelby',
    'Stark',
    'Summit',
    'Trumbull',
    'Tuscarawas',
    'Union',
    'Van Wert',
    'Vinton',
    'Warren',
    'Washington',
    'Wayne',
    'Williams',
    'Wood',
    'Wyandot',
  ];

  // Languages Spoken (from API documentation - extensive list)
  static const List<String> languages = [
    'English',
    'Spanish',
    'Arabic',
    'French',
    'Mandarin',
    'Cantonese',
    'Vietnamese',
    'Tagalog',
    'Portuguese',
    'Russian',
    'German',
    'Italian',
    'Japanese',
    'Korean',
    'Hindi',
    'Polish',
    'Greek',
    'Hebrew',
    'Turkish',
    'Urdu',
    'Bengali',
    'Haitian Creole',
    'Somali',
    'Swahili',
    'Amharic',
    'Farsi',
    'Punjabi',
    'Gujarati',
    'Tamil',
    'Telugu',
    'American Sign Language',
    'Other',
  ];

  // Specialized Training (from API documentation)
  static const List<String> specializedTraining = [
    'Autism',
    'Blindness or visual impairment',
    'Child Welfare',
    'Chronic Illness',
    'Co-Occurring Disorders',
    'Deafness or hard-of-hearing',
    'Eating Disorders',
    'Foster Care',
    'HIV/AIDS',
    'Homelessness',
    'Intellectual and Developmental Disabilities',
    'Mental Illness',
    'Physical Disabilities',
    'Substance Abuse',
    'Substance Use',
    'Trauma Informed Care',
  ];

  // Cultural Competencies (from API documentation)
  static const List<String> culturalCompetencies = [
    'African-American',
    'Native American',
    'Hispanic/Latino',
    'Alaskan Native',
    'LGBTQ',
    'Pacific Islander',
    'Asian',
  ];

  // ADA Accommodations (from API documentation)
  static const List<String> adaAccommodations = [
    'Parking',
    'Exam Room',
    'Restroom',
    'Building Access',
    'Public Access',
    'Equipment',
    'Office Access',
  ];

  // Board Certifications (abbreviated list - full list is extensive)
  static const List<String> boardCertifications = [
    'American Board of Obstetrics and Gynecology',
    'American Board of Family Medicine',
    'American Board of Pediatrics',
    'American Board of Internal Medicine',
    'American Midwifery Certification Board',
    'American Nurses Credentialing Center',
    'National Certification Commission',
    'National Commission on Certification of Physician Assistants',
    'Other Board Certification',
  ];

  // DME Products and Services
  static const List<String> dmeProductsServices = [
    'Durable Medical Equipment',
    'Prosthetics',
    'Orthotics',
    'Supplies',
  ];
}
