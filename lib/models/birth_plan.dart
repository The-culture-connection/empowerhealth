import 'package:cloud_firestore/cloud_firestore.dart';

class BirthPlan {
  final String? id;
  final String userId;
  
  // Section 1: Basic Information
  final String fullName;
  final DateTime? dueDate;
  final String? supportPersonName;
  final String? supportPersonRelationship;
  final String? doulaName;
  final String? preferredHospital;
  final String? providerName; // OB/midwife provider name
  final String? emergencyContact;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> pregnancyComplications;
  
  // Section 2: Labor Preferences - Environment
  final String? lightingPreference; // dim, bright
  final String? noisePreference; // quiet, music, affirmations
  final bool? visitorsAllowed;
  final bool? photographyAllowed;
  final bool? videographyAllowed;
  final String? preferredLanguage;
  final bool traumaInformedCare; // "Please tell me before touching/exams"
  
  // Section 3: Labor Preferences - Comfort & Pain Management
  final List<String> preferredLaborPositions;
  final List<String> naturalComfortMeasures; // massage, counter-pressure, hydrotherapy
  final String? painManagementPreference; // none, epidural, nitrous oxide, etc.
  final String? whenToOfferPainMedication; // only if requested / whenever appropriate
  final bool movementFreedom;
  final String? monitoringPreference; // intermittent, continuous, wireless
  final String? ivFluidsPreference; // saline lock vs continuous fluids
  final bool useDoula;
  final bool? waterLaborAvailable;
  final String? communicationStyle;
  
  // Section 4: Medical Interventions (Prefer / Open to if needed / Do not want unless medically necessary)
  final String? inductionMethodsPreference;
  final String? augmentationPreference; // Pitocin, membrane sweep, breaking water
  final String? vaginalExamsPreference; // frequency, consent each time
  final String? membraneRupturePreference; // AROM
  final String? episiotomyPreference;
  final String? vacuumForcepsPreference;
  final String? cesareanPreference;
  
  // Section 5: Delivery Preferences
  final List<String> preferredPushingPositions;
  final String? coachingStyle; // quiet, guided, minimal talking
  final bool? seeTouchBabyHeadDuringCrowning;
  final bool? mirrorDuringPushing;
  final String? whoCatchesBaby;
  final String? cordCuttingPreference; // immediate vs delayed (golden minute, 60-120 seconds)
  final String? whoCutsCord;
  final bool? delayedPushingWithEpidural;
  
  // Section 6: After Birth (Immediate Postpartum) - Baby Care
  final bool immediateSkinToSkin;
  final String? delayedCordClampingPreference; // golden minute, 60-120 seconds
  final bool? delayedNewbornProcedures; // weight, eye ointment, bath
  final bool? vitaminK;
  final bool? hepBVaccine;
  final String? nicuTransferInstructions; // partner goes with baby, no decisions without mom
  
  // Placenta
  final String? placentaPreference; // save (encapsulation or cultural reasons), hospital disposal
  
  // Section 7: Feeding
  final String? feedingPreference; // breastfeeding only, breastfeeding + formula, formula feeding
  final bool lactationConsultantRequested;
  final bool? noPacifierUntilBreastfeeding;
  final bool? consentForDonorMilk;
  
  // Section 8: Cesarean Birth Preferences
  final String? cesareanDrapePreference; // clear drape / viewing option
  final bool? immediateSkinToSkinInOR;
  final bool? supportPersonInOR;
  final bool? gentleCesarean; // slow delivery of baby
  final bool? musicAllowedInOR;
  final bool? delayCordClampingInCesarean;
  final bool? partnerCutsCordInCesarean;
  final bool? goldenHourHonoredIfStable;
  
  // Section 9: Cultural, Personal, & Safety Preferences
  final String? culturalReligiousRituals;
  final String? traumaInformedCareNotes; // history of loss, assault → want consent before touch
  final String? preferredCommunicationStyle; // explain first, ask before touching, etc.
  final String? genderPreferenceForProviders;
  final String? racialBiasConcerns;
  final String? stopWordOrPhrase; // signaling patient feels unsafe
  final String? advocacyPreferences; // e.g., "Please include my doula in decisions"
  
  // Section 10: Postpartum Care Preferences
  final bool? roomingIn;
  final String? postpartumPainControlPlan;
  final String? visitorsAfterBirth;
  final bool? mentalHealthScreeningPreference;
  final bool? socialWorkConsultIfNeeded;
  final String? dietaryPreferences;
  
  // Section 11: Special Considerations
  final String? highRiskPregnancyNotes;
  final List<String> chronicHealthConditions;
  final List<String> medications;
  final String? pastBirthTraumaOrComplications;
  final String? accessibilityNeeds;
  final List<String> anxietyTriggers;
  final bool consentBasedCare;
  final String? preferredBadNewsDelivery;
  final List<String> fearReductionRequests;
  
  // Section 12: In My Own Words
  final String? inMyOwnWords;
  
  // Generated content
  final String? formattedPlan;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BirthPlan({
    this.id,
    required this.userId,
    required this.fullName,
    this.dueDate,
    this.supportPersonName,
    this.supportPersonRelationship,
    this.doulaName,
    this.preferredHospital,
    this.providerName,
    this.emergencyContact,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.pregnancyComplications = const [],
    this.lightingPreference,
    this.noisePreference,
    this.visitorsAllowed,
    this.photographyAllowed,
    this.videographyAllowed,
    this.preferredLanguage,
    this.traumaInformedCare = false,
    this.preferredLaborPositions = const [],
    this.naturalComfortMeasures = const [],
    this.painManagementPreference,
    this.whenToOfferPainMedication,
    this.movementFreedom = true,
    this.monitoringPreference,
    this.ivFluidsPreference,
    this.useDoula = false,
    this.waterLaborAvailable,
    this.communicationStyle,
    this.inductionMethodsPreference,
    this.augmentationPreference,
    this.vaginalExamsPreference,
    this.membraneRupturePreference,
    this.episiotomyPreference,
    this.vacuumForcepsPreference,
    this.cesareanPreference,
    this.preferredPushingPositions = const [],
    this.coachingStyle,
    this.seeTouchBabyHeadDuringCrowning,
    this.mirrorDuringPushing,
    this.whoCatchesBaby,
    this.cordCuttingPreference,
    this.whoCutsCord,
    this.delayedPushingWithEpidural,
    this.immediateSkinToSkin = true,
    this.delayedCordClampingPreference,
    this.delayedNewbornProcedures,
    this.vitaminK,
    this.hepBVaccine,
    this.nicuTransferInstructions,
    this.placentaPreference,
    this.feedingPreference,
    this.lactationConsultantRequested = false,
    this.noPacifierUntilBreastfeeding,
    this.consentForDonorMilk,
    this.cesareanDrapePreference,
    this.immediateSkinToSkinInOR,
    this.supportPersonInOR,
    this.gentleCesarean,
    this.musicAllowedInOR,
    this.delayCordClampingInCesarean,
    this.partnerCutsCordInCesarean,
    this.goldenHourHonoredIfStable,
    this.culturalReligiousRituals,
    this.traumaInformedCareNotes,
    this.preferredCommunicationStyle,
    this.genderPreferenceForProviders,
    this.racialBiasConcerns,
    this.stopWordOrPhrase,
    this.advocacyPreferences,
    this.roomingIn,
    this.postpartumPainControlPlan,
    this.visitorsAfterBirth,
    this.mentalHealthScreeningPreference,
    this.socialWorkConsultIfNeeded,
    this.dietaryPreferences,
    this.highRiskPregnancyNotes,
    this.chronicHealthConditions = const [],
    this.medications = const [],
    this.pastBirthTraumaOrComplications,
    this.accessibilityNeeds,
    this.anxietyTriggers = const [],
    this.consentBasedCare = false,
    this.preferredBadNewsDelivery,
    this.fearReductionRequests = const [],
    this.inMyOwnWords,
    this.formattedPlan,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'dueDate': dueDate?.toIso8601String(),
      'supportPersonName': supportPersonName,
      'supportPersonRelationship': supportPersonRelationship,
      'doulaName': doulaName,
      'preferredHospital': preferredHospital,
      'providerName': providerName,
      'emergencyContact': emergencyContact,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'pregnancyComplications': pregnancyComplications,
      'lightingPreference': lightingPreference,
      'noisePreference': noisePreference,
      'visitorsAllowed': visitorsAllowed,
      'photographyAllowed': photographyAllowed,
      'videographyAllowed': videographyAllowed,
      'preferredLanguage': preferredLanguage,
      'traumaInformedCare': traumaInformedCare,
      'preferredLaborPositions': preferredLaborPositions,
      'naturalComfortMeasures': naturalComfortMeasures,
      'painManagementPreference': painManagementPreference,
      'whenToOfferPainMedication': whenToOfferPainMedication,
      'movementFreedom': movementFreedom,
      'monitoringPreference': monitoringPreference,
      'ivFluidsPreference': ivFluidsPreference,
      'useDoula': useDoula,
      'waterLaborAvailable': waterLaborAvailable,
      'communicationStyle': communicationStyle,
      'inductionMethodsPreference': inductionMethodsPreference,
      'augmentationPreference': augmentationPreference,
      'vaginalExamsPreference': vaginalExamsPreference,
      'membraneRupturePreference': membraneRupturePreference,
      'episiotomyPreference': episiotomyPreference,
      'vacuumForcepsPreference': vacuumForcepsPreference,
      'cesareanPreference': cesareanPreference,
      'preferredPushingPositions': preferredPushingPositions,
      'coachingStyle': coachingStyle,
      'seeTouchBabyHeadDuringCrowning': seeTouchBabyHeadDuringCrowning,
      'mirrorDuringPushing': mirrorDuringPushing,
      'whoCatchesBaby': whoCatchesBaby,
      'cordCuttingPreference': cordCuttingPreference,
      'whoCutsCord': whoCutsCord,
      'delayedPushingWithEpidural': delayedPushingWithEpidural,
      'immediateSkinToSkin': immediateSkinToSkin,
      'delayedCordClampingPreference': delayedCordClampingPreference,
      'delayedNewbornProcedures': delayedNewbornProcedures,
      'vitaminK': vitaminK,
      'hepBVaccine': hepBVaccine,
      'nicuTransferInstructions': nicuTransferInstructions,
      'placentaPreference': placentaPreference,
      'feedingPreference': feedingPreference,
      'lactationConsultantRequested': lactationConsultantRequested,
      'noPacifierUntilBreastfeeding': noPacifierUntilBreastfeeding,
      'consentForDonorMilk': consentForDonorMilk,
      'cesareanDrapePreference': cesareanDrapePreference,
      'immediateSkinToSkinInOR': immediateSkinToSkinInOR,
      'supportPersonInOR': supportPersonInOR,
      'gentleCesarean': gentleCesarean,
      'musicAllowedInOR': musicAllowedInOR,
      'delayCordClampingInCesarean': delayCordClampingInCesarean,
      'partnerCutsCordInCesarean': partnerCutsCordInCesarean,
      'goldenHourHonoredIfStable': goldenHourHonoredIfStable,
      'culturalReligiousRituals': culturalReligiousRituals,
      'traumaInformedCareNotes': traumaInformedCareNotes,
      'preferredCommunicationStyle': preferredCommunicationStyle,
      'genderPreferenceForProviders': genderPreferenceForProviders,
      'racialBiasConcerns': racialBiasConcerns,
      'stopWordOrPhrase': stopWordOrPhrase,
      'advocacyPreferences': advocacyPreferences,
      'roomingIn': roomingIn,
      'postpartumPainControlPlan': postpartumPainControlPlan,
      'visitorsAfterBirth': visitorsAfterBirth,
      'mentalHealthScreeningPreference': mentalHealthScreeningPreference,
      'socialWorkConsultIfNeeded': socialWorkConsultIfNeeded,
      'dietaryPreferences': dietaryPreferences,
      'highRiskPregnancyNotes': highRiskPregnancyNotes,
      'chronicHealthConditions': chronicHealthConditions,
      'medications': medications,
      'pastBirthTraumaOrComplications': pastBirthTraumaOrComplications,
      'accessibilityNeeds': accessibilityNeeds,
      'anxietyTriggers': anxietyTriggers,
      'consentBasedCare': consentBasedCare,
      'preferredBadNewsDelivery': preferredBadNewsDelivery,
      'fearReductionRequests': fearReductionRequests,
      'inMyOwnWords': inMyOwnWords,
      'formattedPlan': formattedPlan,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
      doulaName: data['doulaName'],
      preferredHospital: data['preferredHospital'],
      providerName: data['providerName'],
      emergencyContact: data['emergencyContact'],
      allergies: List<String>.from(data['allergies'] ?? []),
      medicalConditions: List<String>.from(data['medicalConditions'] ?? []),
      pregnancyComplications: List<String>.from(data['pregnancyComplications'] ?? []),
      lightingPreference: data['lightingPreference'],
      noisePreference: data['noisePreference'],
      visitorsAllowed: data['visitorsAllowed'],
      photographyAllowed: data['photographyAllowed'],
      videographyAllowed: data['videographyAllowed'],
      preferredLanguage: data['preferredLanguage'],
      traumaInformedCare: data['traumaInformedCare'] ?? false,
      preferredLaborPositions: List<String>.from(data['preferredLaborPositions'] ?? []),
      naturalComfortMeasures: List<String>.from(data['naturalComfortMeasures'] ?? []),
      painManagementPreference: data['painManagementPreference'],
      whenToOfferPainMedication: data['whenToOfferPainMedication'],
      movementFreedom: data['movementFreedom'] ?? true,
      monitoringPreference: data['monitoringPreference'],
      ivFluidsPreference: data['ivFluidsPreference'],
      useDoula: data['useDoula'] ?? false,
      waterLaborAvailable: data['waterLaborAvailable'],
      communicationStyle: data['communicationStyle'],
      inductionMethodsPreference: data['inductionMethodsPreference'],
      augmentationPreference: data['augmentationPreference'],
      vaginalExamsPreference: data['vaginalExamsPreference'],
      membraneRupturePreference: data['membraneRupturePreference'],
      episiotomyPreference: data['episiotomyPreference'],
      vacuumForcepsPreference: data['vacuumForcepsPreference'],
      cesareanPreference: data['cesareanPreference'],
      preferredPushingPositions: List<String>.from(data['preferredPushingPositions'] ?? []),
      coachingStyle: data['coachingStyle'],
      seeTouchBabyHeadDuringCrowning: data['seeTouchBabyHeadDuringCrowning'],
      mirrorDuringPushing: data['mirrorDuringPushing'],
      whoCatchesBaby: data['whoCatchesBaby'],
      cordCuttingPreference: data['cordCuttingPreference'],
      whoCutsCord: data['whoCutsCord'],
      delayedPushingWithEpidural: data['delayedPushingWithEpidural'],
      immediateSkinToSkin: data['immediateSkinToSkin'] ?? true,
      delayedCordClampingPreference: data['delayedCordClampingPreference'],
      delayedNewbornProcedures: data['delayedNewbornProcedures'],
      vitaminK: data['vitaminK'],
      hepBVaccine: data['hepBVaccine'],
      nicuTransferInstructions: data['nicuTransferInstructions'],
      placentaPreference: data['placentaPreference'],
      feedingPreference: data['feedingPreference'],
      lactationConsultantRequested: data['lactationConsultantRequested'] ?? false,
      noPacifierUntilBreastfeeding: data['noPacifierUntilBreastfeeding'],
      consentForDonorMilk: data['consentForDonorMilk'],
      cesareanDrapePreference: data['cesareanDrapePreference'],
      immediateSkinToSkinInOR: data['immediateSkinToSkinInOR'],
      supportPersonInOR: data['supportPersonInOR'],
      gentleCesarean: data['gentleCesarean'],
      musicAllowedInOR: data['musicAllowedInOR'],
      delayCordClampingInCesarean: data['delayCordClampingInCesarean'],
      partnerCutsCordInCesarean: data['partnerCutsCordInCesarean'],
      goldenHourHonoredIfStable: data['goldenHourHonoredIfStable'],
      culturalReligiousRituals: data['culturalReligiousRituals'],
      traumaInformedCareNotes: data['traumaInformedCareNotes'],
      preferredCommunicationStyle: data['preferredCommunicationStyle'],
      genderPreferenceForProviders: data['genderPreferenceForProviders'],
      racialBiasConcerns: data['racialBiasConcerns'],
      stopWordOrPhrase: data['stopWordOrPhrase'],
      advocacyPreferences: data['advocacyPreferences'],
      roomingIn: data['roomingIn'],
      postpartumPainControlPlan: data['postpartumPainControlPlan'],
      visitorsAfterBirth: data['visitorsAfterBirth'],
      mentalHealthScreeningPreference: data['mentalHealthScreeningPreference'],
      socialWorkConsultIfNeeded: data['socialWorkConsultIfNeeded'],
      dietaryPreferences: data['dietaryPreferences'],
      highRiskPregnancyNotes: data['highRiskPregnancyNotes'],
      chronicHealthConditions: List<String>.from(data['chronicHealthConditions'] ?? []),
      medications: List<String>.from(data['medications'] ?? []),
      pastBirthTraumaOrComplications: data['pastBirthTraumaOrComplications'],
      accessibilityNeeds: data['accessibilityNeeds'],
      anxietyTriggers: List<String>.from(data['anxietyTriggers'] ?? []),
      consentBasedCare: data['consentBasedCare'] ?? false,
      preferredBadNewsDelivery: data['preferredBadNewsDelivery'],
      fearReductionRequests: List<String>.from(data['fearReductionRequests'] ?? []),
      inMyOwnWords: data['inMyOwnWords'],
      formattedPlan: data['formattedPlan'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
