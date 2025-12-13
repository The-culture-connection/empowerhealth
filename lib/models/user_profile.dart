import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  // Basic Information
  final String userId;
  final String name;
  final int age;
  final bool isPregnant;
  final DateTime? dueDate;
  final bool isPostpartum;
  final DateTime? deliveryDate;
  final int? childAgeMonths;
  final String zipCode;
  final String insuranceType;

  // Demographics
  final String? raceEthnicity;
  final String? languagePreference;
  final String? maritalStatus;
  final String? educationLevel;

  // Health Info
  final String? pregnancyStage; // trimester or weeks postpartum
  final List<String> chronicConditions;
  final List<String> medications;
  final List<String> allergies;

  // Support Network
  final bool hasDoula;
  final bool hasPartner;
  final bool hasSupportPerson;
  final bool hasPrimaryProvider;

  // Wellness & Access
  final bool hasTransportation;
  final bool needsChildcare;
  final bool enrolledInWIC;
  final bool hasMentalHealthSupport;
  final bool hasAccessToFood;
  final bool hasStableHousing;

  // Preferences
  final List<String> providerPreferences; // cultural match, gender, etc.

  // Goals
  final String? birthPreference; // hospital/home/birth center
  final bool interestedInBreastfeeding;
  final List<String> healthLiteracyGoals; // nutrition, exercise, etc.

  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.age,
    required this.isPregnant,
    this.dueDate,
    required this.isPostpartum,
    this.deliveryDate,
    this.childAgeMonths,
    required this.zipCode,
    required this.insuranceType,
    this.raceEthnicity,
    this.languagePreference,
    this.maritalStatus,
    this.educationLevel,
    this.pregnancyStage,
    this.chronicConditions = const [],
    this.medications = const [],
    this.allergies = const [],
    this.hasDoula = false,
    this.hasPartner = false,
    this.hasSupportPerson = false,
    this.hasPrimaryProvider = false,
    this.hasTransportation = false,
    this.needsChildcare = false,
    this.enrolledInWIC = false,
    this.hasMentalHealthSupport = false,
    this.hasAccessToFood = false,
    this.hasStableHousing = false,
    this.providerPreferences = const [],
    this.birthPreference,
    this.interestedInBreastfeeding = false,
    this.healthLiteracyGoals = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'age': age,
      'isPregnant': isPregnant,
      'dueDate': dueDate?.toIso8601String(),
      'isPostpartum': isPostpartum,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'childAgeMonths': childAgeMonths,
      'zipCode': zipCode,
      'insuranceType': insuranceType,
      'raceEthnicity': raceEthnicity,
      'languagePreference': languagePreference,
      'maritalStatus': maritalStatus,
      'educationLevel': educationLevel,
      'pregnancyStage': pregnancyStage,
      'chronicConditions': chronicConditions,
      'medications': medications,
      'allergies': allergies,
      'hasDoula': hasDoula,
      'hasPartner': hasPartner,
      'hasSupportPerson': hasSupportPerson,
      'hasPrimaryProvider': hasPrimaryProvider,
      'hasTransportation': hasTransportation,
      'needsChildcare': needsChildcare,
      'enrolledInWIC': enrolledInWIC,
      'hasMentalHealthSupport': hasMentalHealthSupport,
      'hasAccessToFood': hasAccessToFood,
      'hasStableHousing': hasStableHousing,
      'providerPreferences': providerPreferences,
      'birthPreference': birthPreference,
      'interestedInBreastfeeding': interestedInBreastfeeding,
      'healthLiteracyGoals': healthLiteracyGoals,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      isPregnant: map['isPregnant'] ?? false,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isPostpartum: map['isPostpartum'] ?? false,
      deliveryDate: map['deliveryDate'] != null ? DateTime.parse(map['deliveryDate']) : null,
      childAgeMonths: map['childAgeMonths'],
      zipCode: map['zipCode'] ?? '',
      insuranceType: map['insuranceType'] ?? '',
      raceEthnicity: map['raceEthnicity'],
      languagePreference: map['languagePreference'],
      maritalStatus: map['maritalStatus'],
      educationLevel: map['educationLevel'],
      pregnancyStage: map['pregnancyStage'],
      chronicConditions: List<String>.from(map['chronicConditions'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      hasDoula: map['hasDoula'] ?? false,
      hasPartner: map['hasPartner'] ?? false,
      hasSupportPerson: map['hasSupportPerson'] ?? false,
      hasPrimaryProvider: map['hasPrimaryProvider'] ?? false,
      hasTransportation: map['hasTransportation'] ?? false,
      needsChildcare: map['needsChildcare'] ?? false,
      enrolledInWIC: map['enrolledInWIC'] ?? false,
      hasMentalHealthSupport: map['hasMentalHealthSupport'] ?? false,
      hasAccessToFood: map['hasAccessToFood'] ?? false,
      hasStableHousing: map['hasStableHousing'] ?? false,
      providerPreferences: List<String>.from(map['providerPreferences'] ?? []),
      birthPreference: map['birthPreference'],
      interestedInBreastfeeding: map['interestedInBreastfeeding'] ?? false,
      healthLiteracyGoals: List<String>.from(map['healthLiteracyGoals'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy with updated fields
  UserProfile copyWith({
    String? userId,
    String? name,
    int? age,
    bool? isPregnant,
    DateTime? dueDate,
    bool? isPostpartum,
    int? childAgeMonths,
    String? zipCode,
    String? insuranceType,
    String? raceEthnicity,
    String? languagePreference,
    String? maritalStatus,
    String? educationLevel,
    String? pregnancyStage,
    List<String>? chronicConditions,
    List<String>? medications,
    List<String>? allergies,
    bool? hasDoula,
    bool? hasPartner,
    bool? hasSupportPerson,
    bool? hasPrimaryProvider,
    bool? hasTransportation,
    bool? needsChildcare,
    bool? enrolledInWIC,
    bool? hasMentalHealthSupport,
    bool? hasAccessToFood,
    bool? hasStableHousing,
    List<String>? providerPreferences,
    String? birthPreference,
    bool? interestedInBreastfeeding,
    List<String>? healthLiteracyGoals,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      isPregnant: isPregnant ?? this.isPregnant,
      dueDate: dueDate ?? this.dueDate,
      isPostpartum: isPostpartum ?? this.isPostpartum,
      childAgeMonths: childAgeMonths ?? this.childAgeMonths,
      zipCode: zipCode ?? this.zipCode,
      insuranceType: insuranceType ?? this.insuranceType,
      raceEthnicity: raceEthnicity ?? this.raceEthnicity,
      languagePreference: languagePreference ?? this.languagePreference,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      educationLevel: educationLevel ?? this.educationLevel,
      pregnancyStage: pregnancyStage ?? this.pregnancyStage,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
      hasDoula: hasDoula ?? this.hasDoula,
      hasPartner: hasPartner ?? this.hasPartner,
      hasSupportPerson: hasSupportPerson ?? this.hasSupportPerson,
      hasPrimaryProvider: hasPrimaryProvider ?? this.hasPrimaryProvider,
      hasTransportation: hasTransportation ?? this.hasTransportation,
      needsChildcare: needsChildcare ?? this.needsChildcare,
      enrolledInWIC: enrolledInWIC ?? this.enrolledInWIC,
      hasMentalHealthSupport: hasMentalHealthSupport ?? this.hasMentalHealthSupport,
      hasAccessToFood: hasAccessToFood ?? this.hasAccessToFood,
      hasStableHousing: hasStableHousing ?? this.hasStableHousing,
      providerPreferences: providerPreferences ?? this.providerPreferences,
      birthPreference: birthPreference ?? this.birthPreference,
      interestedInBreastfeeding: interestedInBreastfeeding ?? this.interestedInBreastfeeding,
      healthLiteracyGoals: healthLiteracyGoals ?? this.healthLiteracyGoals,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}






