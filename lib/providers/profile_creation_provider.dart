import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class ProfileCreationProvider extends ChangeNotifier {
  int _currentStep = 0;
  
  // Basic Information
  String username = '';
  int age = 18;
  bool isPregnant = false;
  DateTime? dueDate;
  bool isPostpartum = false;
  DateTime? deliveryDate;
  int? childAgeMonths;
  String zipCode = '';
  String city = '';
  String state = 'OH'; // Default to Ohio
  String insuranceType = '';

  // Demographics
  String? raceEthnicity;
  String? languagePreference;
  String? maritalStatus;
  String? educationLevel;

  // Health Info
  String? pregnancyStage;
  List<String> chronicConditions = [];
  List<String> medications = [];
  List<String> allergies = [];

  // Support Network
  bool hasDoula = false;
  bool hasPartner = false;
  bool hasSupportPerson = false;
  bool hasPrimaryProvider = false;

  // Wellness & Access
  bool hasTransportation = false;
  bool needsChildcare = false;
  bool enrolledInWIC = false;
  bool hasMentalHealthSupport = false;
  bool hasAccessToFood = false;
  bool hasStableHousing = false;

  // Preferences
  List<String> providerPreferences = [];

  // Goals
  String? birthPreference;
  bool interestedInBreastfeeding = false;
  List<String> healthLiteracyGoals = [];

  int get currentStep => _currentStep;
  int get totalSteps => 7;

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  // Update methods
  void updateBasicInfo({
    String? username,
    int? age,
    bool? isPregnant,
    DateTime? dueDate,
    bool? isPostpartum,
    DateTime? deliveryDate,
    int? childAgeMonths,
    String? zipCode,
    String? city,
    String? state,
    String? insuranceType,
  }) {
    if (username != null) this.username = username;
    if (age != null) this.age = age;
    if (isPregnant != null) {
      this.isPregnant = isPregnant;
      if (isPregnant) {
        this.isPostpartum = false;
        this.deliveryDate = null;
        this.childAgeMonths = null;
      }
    }
    if (dueDate != null) {
      this.dueDate = dueDate;
      // Auto-update pregnancy stage when due date changes
      if (isPregnant ?? this.isPregnant) {
        this.pregnancyStage = _calculateTrimester(dueDate);
      }
    }
    if (isPostpartum != null) {
      this.isPostpartum = isPostpartum;
      if (isPostpartum) {
        this.isPregnant = false;
        this.dueDate = null;
      }
    }
    if (deliveryDate != null) {
      this.deliveryDate = deliveryDate;
      // Calculate child age in months
      final months = ((DateTime.now().difference(deliveryDate).inDays) / 30).floor();
      this.childAgeMonths = months;
    }
    if (childAgeMonths != null) this.childAgeMonths = childAgeMonths;
    if (zipCode != null) this.zipCode = zipCode;
    if (city != null) this.city = city;
    if (state != null) this.state = state;
    if (insuranceType != null) this.insuranceType = insuranceType;
    notifyListeners();
  }

  void updateDemographics({
    String? raceEthnicity,
    String? languagePreference,
    String? maritalStatus,
    String? educationLevel,
  }) {
    if (raceEthnicity != null) this.raceEthnicity = raceEthnicity;
    if (languagePreference != null) this.languagePreference = languagePreference;
    if (maritalStatus != null) this.maritalStatus = maritalStatus;
    if (educationLevel != null) this.educationLevel = educationLevel;
    notifyListeners();
  }

  void updateHealthInfo({
    String? pregnancyStage,
    List<String>? chronicConditions,
    List<String>? medications,
    List<String>? allergies,
  }) {
    if (pregnancyStage != null) this.pregnancyStage = pregnancyStage;
    if (chronicConditions != null) this.chronicConditions = chronicConditions;
    if (medications != null) this.medications = medications;
    if (allergies != null) this.allergies = allergies;
    notifyListeners();
  }

  void updateSupportNetwork({
    bool? hasDoula,
    bool? hasPartner,
    bool? hasSupportPerson,
    bool? hasPrimaryProvider,
  }) {
    if (hasDoula != null) this.hasDoula = hasDoula;
    if (hasPartner != null) this.hasPartner = hasPartner;
    if (hasSupportPerson != null) this.hasSupportPerson = hasSupportPerson;
    if (hasPrimaryProvider != null) this.hasPrimaryProvider = hasPrimaryProvider;
    notifyListeners();
  }

  void updateWellnessAccess({
    bool? hasTransportation,
    bool? needsChildcare,
    bool? enrolledInWIC,
    bool? hasMentalHealthSupport,
    bool? hasAccessToFood,
    bool? hasStableHousing,
  }) {
    if (hasTransportation != null) this.hasTransportation = hasTransportation;
    if (needsChildcare != null) this.needsChildcare = needsChildcare;
    if (enrolledInWIC != null) this.enrolledInWIC = enrolledInWIC;
    if (hasMentalHealthSupport != null) {
      this.hasMentalHealthSupport = hasMentalHealthSupport;
    }
    if (hasAccessToFood != null) this.hasAccessToFood = hasAccessToFood;
    if (hasStableHousing != null) this.hasStableHousing = hasStableHousing;
    notifyListeners();
  }

  void updatePreferences(List<String> preferences) {
    providerPreferences = preferences;
    notifyListeners();
  }

  void updateGoals({
    String? birthPreference,
    bool? interestedInBreastfeeding,
    List<String>? healthLiteracyGoals,
  }) {
    if (birthPreference != null) this.birthPreference = birthPreference;
    if (interestedInBreastfeeding != null) {
      this.interestedInBreastfeeding = interestedInBreastfeeding;
    }
    if (healthLiteracyGoals != null) {
      this.healthLiteracyGoals = healthLiteracyGoals;
    }
    notifyListeners();
  }

  // Create UserProfile from provider data
  UserProfile toUserProfile(String userId) {
    // Calculate trimester from due date
    final calculatedTrimester = _calculateTrimester(dueDate);
    
    return UserProfile(
      userId: userId,
      username: username,
      age: age,
      isPregnant: isPregnant,
      dueDate: dueDate,
      isPostpartum: isPostpartum,
      deliveryDate: deliveryDate,
      childAgeMonths: childAgeMonths,
      zipCode: zipCode,
      city: city,
      state: state,
      insuranceType: insuranceType,
      raceEthnicity: raceEthnicity,
      languagePreference: languagePreference,
      maritalStatus: maritalStatus,
      educationLevel: educationLevel,
      pregnancyStage: calculatedTrimester,
      chronicConditions: chronicConditions,
      medications: medications,
      allergies: allergies,
      hasDoula: hasDoula,
      hasPartner: hasPartner,
      hasSupportPerson: hasSupportPerson,
      hasPrimaryProvider: hasPrimaryProvider,
      hasTransportation: hasTransportation,
      needsChildcare: needsChildcare,
      enrolledInWIC: enrolledInWIC,
      hasMentalHealthSupport: hasMentalHealthSupport,
      hasAccessToFood: hasAccessToFood,
      hasStableHousing: hasStableHousing,
      providerPreferences: providerPreferences,
      birthPreference: birthPreference,
      interestedInBreastfeeding: interestedInBreastfeeding,
      healthLiteracyGoals: healthLiteracyGoals,
    );
  }

  void reset() {
    _currentStep = 0;
    username = '';
    age = 18;
    isPregnant = false;
    dueDate = null;
    isPostpartum = false;
    deliveryDate = null;
    childAgeMonths = null;
    zipCode = '';
    city = '';
    state = 'OH';
    insuranceType = '';
    raceEthnicity = null;
    languagePreference = null;
    maritalStatus = null;
    educationLevel = null;
    pregnancyStage = null;
    chronicConditions = [];
    medications = [];
    allergies = [];
    hasDoula = false;
    hasPartner = false;
    hasSupportPerson = false;
    hasPrimaryProvider = false;
    hasTransportation = false;
    needsChildcare = false;
    enrolledInWIC = false;
    hasMentalHealthSupport = false;
    hasAccessToFood = false;
    hasStableHousing = false;
    providerPreferences = [];
    birthPreference = null;
    interestedInBreastfeeding = false;
    healthLiteracyGoals = [];
    notifyListeners();
  }

  String _calculateTrimester(DateTime? dueDate) {
    if (dueDate == null) return 'First Trimester';
    
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    final weeksPregnant = 40 - (daysUntilDue / 7).floor();
    
    if (weeksPregnant <= 0) return 'First Trimester';
    if (weeksPregnant <= 13) return 'First Trimester';
    if (weeksPregnant <= 27) return 'Second Trimester';
    return 'Third Trimester';
  }
}






