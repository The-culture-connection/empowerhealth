import 'package:cloud_firestore/cloud_firestore.dart';

class BirthPlan {
  final String? id;
  final String userId;
  
  // Section 1: Parent Information
  final String fullName;
  final DateTime? dueDate;
  final String? supportPersonName;
  final String? supportPersonRelationship;
  final String? contactInfo;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> pregnancyComplications;
  
  // Section 2: Labor & Delivery Environment
  final List<String> environmentPreferences; // calm/quiet, music, low light, etc.
  final bool? photographyAllowed;
  final bool? videographyAllowed;
  final String? preferredLanguage;
  final bool traumaInformedCare; // "Please tell me before touching/exams"
  
  // Section 3: Labor Preferences
  final List<String> preferredLaborPositions;
  final bool movementFreedom;
  final String? monitoringPreference; // intermittent, continuous, wireless
  final String? painManagementPreference; // unmedicated, epidural, nitrous, IV, comfort only
  final bool useDoula;
  final bool? waterLaborAvailable;
  final String? membraneSweepingPreference;
  final String? inductionPreference;
  final String? communicationStyle;
  
  // Section 4: Pushing & Birth
  final List<String> preferredPushingPositions;
  final String? pushingStyle; // guided vs spontaneous
  final bool? mirrorDuringPushing;
  final String? episiotomyPreference;
  final String? tearingPreference;
  final String? whoCatchesBaby;
  final bool? delayedPushingWithEpidural;
  
  // Section 5: Immediate Newborn Care
  final String? delayedCordClampingPreference; // how long
  final String? whoCutsCord;
  final bool immediateSkinToSkin;
  final bool babyStaysWithParent;
  final bool? vitaminK;
  final bool? eyeOintment;
  final bool? hepBVaccine;
  final bool? cordBloodBanking;
  final String? cordBloodCompany;
  
  // Section 6: Feeding Preferences
  final String? feedingPreference; // breastfeeding, formula, combo
  final bool lactationConsultantRequested;
  final bool? noPacifierUntilBreastfeeding;
  final bool? consentForDonorMilk;
  
  // Section 7: Postpartum Care
  final bool? roomingIn;
  final bool? mentalHealthSupport;
  final String? visitorPreference;
  final String? dietaryPreferences;
  final String? postpartumPainManagement;
  
  // Section 8: Cesarean Preferences
  final String? drapePreference; // clear vs standard
  final bool? partnerInOR;
  final bool? photosAllowedInOR;
  final bool? babyOnChestImmediately;
  final bool? delayNewbornCareUntilHolding;
  final String? anesthesiaPreference;
  final String? surgicalClosurePreference;
  
  // Section 9: Special Considerations
  final String? religiousConsiderations;
  final String? culturalConsiderations;
  final String? accessibilityNeeds;
  final String? traumaHistory; // only if they choose
  final List<String> anxietyTriggers;
  final bool consentBasedCare;
  final String? preferredBadNewsDelivery;
  final List<String> fearReductionRequests;
  
  // Section 10: In My Own Words
  final String? inMyOwnWords;
  
  // Generated content
  final String? formattedPlan;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? providerName;

  BirthPlan({
    this.id,
    required this.userId,
    required this.fullName,
    this.dueDate,
    this.supportPersonName,
    this.supportPersonRelationship,
    this.contactInfo,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.pregnancyComplications = const [],
    this.environmentPreferences = const [],
    this.photographyAllowed,
    this.videographyAllowed,
    this.preferredLanguage,
    this.traumaInformedCare = false,
    this.preferredLaborPositions = const [],
    this.movementFreedom = true,
    this.monitoringPreference,
    this.painManagementPreference,
    this.useDoula = false,
    this.waterLaborAvailable,
    this.membraneSweepingPreference,
    this.inductionPreference,
    this.communicationStyle,
    this.preferredPushingPositions = const [],
    this.pushingStyle,
    this.mirrorDuringPushing,
    this.episiotomyPreference,
    this.tearingPreference,
    this.whoCatchesBaby,
    this.delayedPushingWithEpidural,
    this.delayedCordClampingPreference,
    this.whoCutsCord,
    this.immediateSkinToSkin = true,
    this.babyStaysWithParent = true,
    this.vitaminK,
    this.eyeOintment,
    this.hepBVaccine,
    this.cordBloodBanking,
    this.cordBloodCompany,
    this.feedingPreference,
    this.lactationConsultantRequested = false,
    this.noPacifierUntilBreastfeeding,
    this.consentForDonorMilk,
    this.roomingIn,
    this.mentalHealthSupport,
    this.visitorPreference,
    this.dietaryPreferences,
    this.postpartumPainManagement,
    this.drapePreference,
    this.partnerInOR,
    this.photosAllowedInOR,
    this.babyOnChestImmediately,
    this.delayNewbornCareUntilHolding,
    this.anesthesiaPreference,
    this.surgicalClosurePreference,
    this.religiousConsiderations,
    this.culturalConsiderations,
    this.accessibilityNeeds,
    this.traumaHistory,
    this.anxietyTriggers = const [],
    this.consentBasedCare = false,
    this.preferredBadNewsDelivery,
    this.fearReductionRequests = const [],
    this.inMyOwnWords,
    this.formattedPlan,
    DateTime? createdAt,
    this.updatedAt,
    this.providerName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'dueDate': dueDate?.toIso8601String(),
      'supportPersonName': supportPersonName,
      'supportPersonRelationship': supportPersonRelationship,
      'contactInfo': contactInfo,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'pregnancyComplications': pregnancyComplications,
      'environmentPreferences': environmentPreferences,
      'photographyAllowed': photographyAllowed,
      'videographyAllowed': videographyAllowed,
      'preferredLanguage': preferredLanguage,
      'traumaInformedCare': traumaInformedCare,
      'preferredLaborPositions': preferredLaborPositions,
      'movementFreedom': movementFreedom,
      'monitoringPreference': monitoringPreference,
      'painManagementPreference': painManagementPreference,
      'useDoula': useDoula,
      'waterLaborAvailable': waterLaborAvailable,
      'membraneSweepingPreference': membraneSweepingPreference,
      'inductionPreference': inductionPreference,
      'communicationStyle': communicationStyle,
      'preferredPushingPositions': preferredPushingPositions,
      'pushingStyle': pushingStyle,
      'mirrorDuringPushing': mirrorDuringPushing,
      'episiotomyPreference': episiotomyPreference,
      'tearingPreference': tearingPreference,
      'whoCatchesBaby': whoCatchesBaby,
      'delayedPushingWithEpidural': delayedPushingWithEpidural,
      'delayedCordClampingPreference': delayedCordClampingPreference,
      'whoCutsCord': whoCutsCord,
      'immediateSkinToSkin': immediateSkinToSkin,
      'babyStaysWithParent': babyStaysWithParent,
      'vitaminK': vitaminK,
      'eyeOintment': eyeOintment,
      'hepBVaccine': hepBVaccine,
      'cordBloodBanking': cordBloodBanking,
      'cordBloodCompany': cordBloodCompany,
      'feedingPreference': feedingPreference,
      'lactationConsultantRequested': lactationConsultantRequested,
      'noPacifierUntilBreastfeeding': noPacifierUntilBreastfeeding,
      'consentForDonorMilk': consentForDonorMilk,
      'roomingIn': roomingIn,
      'mentalHealthSupport': mentalHealthSupport,
      'visitorPreference': visitorPreference,
      'dietaryPreferences': dietaryPreferences,
      'postpartumPainManagement': postpartumPainManagement,
      'drapePreference': drapePreference,
      'partnerInOR': partnerInOR,
      'photosAllowedInOR': photosAllowedInOR,
      'babyOnChestImmediately': babyOnChestImmediately,
      'delayNewbornCareUntilHolding': delayNewbornCareUntilHolding,
      'anesthesiaPreference': anesthesiaPreference,
      'surgicalClosurePreference': surgicalClosurePreference,
      'religiousConsiderations': religiousConsiderations,
      'culturalConsiderations': culturalConsiderations,
      'accessibilityNeeds': accessibilityNeeds,
      'traumaHistory': traumaHistory,
      'anxietyTriggers': anxietyTriggers,
      'consentBasedCare': consentBasedCare,
      'preferredBadNewsDelivery': preferredBadNewsDelivery,
      'fearReductionRequests': fearReductionRequests,
      'inMyOwnWords': inMyOwnWords,
      'formattedPlan': formattedPlan,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'providerName': providerName,
    };
  }

  factory BirthPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BirthPlan(
      id: doc.id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
      supportPersonName: data['supportPersonName'],
      supportPersonRelationship: data['supportPersonRelationship'],
      contactInfo: data['contactInfo'],
      allergies: List<String>.from(data['allergies'] ?? []),
      medicalConditions: List<String>.from(data['medicalConditions'] ?? []),
      pregnancyComplications: List<String>.from(data['pregnancyComplications'] ?? []),
      environmentPreferences: List<String>.from(data['environmentPreferences'] ?? []),
      photographyAllowed: data['photographyAllowed'],
      videographyAllowed: data['videographyAllowed'],
      preferredLanguage: data['preferredLanguage'],
      traumaInformedCare: data['traumaInformedCare'] ?? false,
      preferredLaborPositions: List<String>.from(data['preferredLaborPositions'] ?? []),
      movementFreedom: data['movementFreedom'] ?? true,
      monitoringPreference: data['monitoringPreference'],
      painManagementPreference: data['painManagementPreference'],
      useDoula: data['useDoula'] ?? false,
      waterLaborAvailable: data['waterLaborAvailable'],
      membraneSweepingPreference: data['membraneSweepingPreference'],
      inductionPreference: data['inductionPreference'],
      communicationStyle: data['communicationStyle'],
      preferredPushingPositions: List<String>.from(data['preferredPushingPositions'] ?? []),
      pushingStyle: data['pushingStyle'],
      mirrorDuringPushing: data['mirrorDuringPushing'],
      episiotomyPreference: data['episiotomyPreference'],
      tearingPreference: data['tearingPreference'],
      whoCatchesBaby: data['whoCatchesBaby'],
      delayedPushingWithEpidural: data['delayedPushingWithEpidural'],
      delayedCordClampingPreference: data['delayedCordClampingPreference'],
      whoCutsCord: data['whoCutsCord'],
      immediateSkinToSkin: data['immediateSkinToSkin'] ?? true,
      babyStaysWithParent: data['babyStaysWithParent'] ?? true,
      vitaminK: data['vitaminK'],
      eyeOintment: data['eyeOintment'],
      hepBVaccine: data['hepBVaccine'],
      cordBloodBanking: data['cordBloodBanking'],
      cordBloodCompany: data['cordBloodCompany'],
      feedingPreference: data['feedingPreference'],
      lactationConsultantRequested: data['lactationConsultantRequested'] ?? false,
      noPacifierUntilBreastfeeding: data['noPacifierUntilBreastfeeding'],
      consentForDonorMilk: data['consentForDonorMilk'],
      roomingIn: data['roomingIn'],
      mentalHealthSupport: data['mentalHealthSupport'],
      visitorPreference: data['visitorPreference'],
      dietaryPreferences: data['dietaryPreferences'],
      postpartumPainManagement: data['postpartumPainManagement'],
      drapePreference: data['drapePreference'],
      partnerInOR: data['partnerInOR'],
      photosAllowedInOR: data['photosAllowedInOR'],
      babyOnChestImmediately: data['babyOnChestImmediately'],
      delayNewbornCareUntilHolding: data['delayNewbornCareUntilHolding'],
      anesthesiaPreference: data['anesthesiaPreference'],
      surgicalClosurePreference: data['surgicalClosurePreference'],
      religiousConsiderations: data['religiousConsiderations'],
      culturalConsiderations: data['culturalConsiderations'],
      accessibilityNeeds: data['accessibilityNeeds'],
      traumaHistory: data['traumaHistory'],
      anxietyTriggers: List<String>.from(data['anxietyTriggers'] ?? []),
      consentBasedCare: data['consentBasedCare'] ?? false,
      preferredBadNewsDelivery: data['preferredBadNewsDelivery'],
      fearReductionRequests: List<String>.from(data['fearReductionRequests'] ?? []),
      inMyOwnWords: data['inMyOwnWords'],
      formattedPlan: data['formattedPlan'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      providerName: data['providerName'],
    );
  }
}

