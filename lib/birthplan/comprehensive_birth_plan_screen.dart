import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/birth_plan.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../cors/ui_theme.dart';
import 'birth_plan_display_screen.dart';
import 'birth_plan_formatter.dart';

class ComprehensiveBirthPlanScreen extends StatefulWidget {
  const ComprehensiveBirthPlanScreen({super.key});

  @override
  State<ComprehensiveBirthPlanScreen> createState() => _ComprehensiveBirthPlanScreenState();
}

class _ComprehensiveBirthPlanScreenState extends State<ComprehensiveBirthPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  
  // Section 1: Parent Information
  final _supportPersonNameController = TextEditingController();
  final _supportPersonRelationshipController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _allergyController = TextEditingController();
  final _medicalConditionController = TextEditingController();
  final _complicationController = TextEditingController();
  
  DateTime? _dueDate;
  List<String> _allergies = [];
  List<String> _medicalConditions = [];
  List<String> _pregnancyComplications = [];
  
  // Section 2: Environment
  List<String> _environmentPreferences = [];
  bool? _photographyAllowed;
  bool? _videographyAllowed;
  String? _preferredLanguage;
  bool _traumaInformedCare = false;
  
  // Section 3: Labor
  List<String> _preferredLaborPositions = [];
  bool _movementFreedom = true;
  String? _monitoringPreference;
  String? _painManagementPreference;
  bool _useDoula = false;
  bool? _waterLaborAvailable;
  String? _membraneSweepingPreference;
  String? _inductionPreference;
  String? _communicationStyle;
  
  // Section 4: Pushing
  List<String> _preferredPushingPositions = [];
  String? _pushingStyle;
  bool? _mirrorDuringPushing;
  String? _episiotomyPreference;
  String? _tearingPreference;
  String? _whoCatchesBaby;
  bool? _delayedPushingWithEpidural;
  
  // Section 5: Newborn Care
  String? _delayedCordClampingPreference;
  String? _whoCutsCord;
  bool _immediateSkinToSkin = true;
  bool _babyStaysWithParent = true;
  bool? _vitaminK;
  bool? _eyeOintment;
  bool? _hepBVaccine;
  bool? _cordBloodBanking;
  final _cordBloodCompanyController = TextEditingController();
  
  // Section 6: Feeding
  String? _feedingPreference;
  bool _lactationConsultantRequested = false;
  bool? _noPacifierUntilBreastfeeding;
  bool? _consentForDonorMilk;
  
  // Section 7: Postpartum
  bool? _roomingIn;
  bool? _mentalHealthSupport;
  final _visitorPreferenceController = TextEditingController();
  final _dietaryPreferencesController = TextEditingController();
  final _postpartumPainManagementController = TextEditingController();
  
  // Section 8: Cesarean
  String? _drapePreference;
  bool? _partnerInOR;
  bool? _photosAllowedInOR;
  bool? _babyOnChestImmediately;
  bool? _delayNewbornCareUntilHolding;
  String? _anesthesiaPreference;
  String? _surgicalClosurePreference;
  
  // Section 9: Special Considerations
  final _religiousConsiderationsController = TextEditingController();
  final _culturalConsiderationsController = TextEditingController();
  final _accessibilityNeedsController = TextEditingController();
  final _traumaHistoryController = TextEditingController();
  final _anxietyTriggerController = TextEditingController();
  bool _consentBasedCare = false;
  String? _preferredBadNewsDelivery;
  final _fearReductionController = TextEditingController();
  
  List<String> _anxietyTriggers = [];
  List<String> _fearReductionRequests = [];
  
  // Section 10: In My Own Words
  final _inMyOwnWordsController = TextEditingController();
  
  final String? _providerName = null;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    final profile = await _databaseService.getUserProfile(userId);
    if (profile != null) {
      setState(() {
        _dueDate = profile.dueDate;
        _allergies = List.from(profile.allergies);
        _medicalConditions = List.from(profile.chronicConditions);
        _useDoula = profile.hasDoula;
      });
    }
  }

  @override
  void dispose() {
    _supportPersonNameController.dispose();
    _supportPersonRelationshipController.dispose();
    _contactInfoController.dispose();
    _allergyController.dispose();
    _medicalConditionController.dispose();
    _complicationController.dispose();
    _cordBloodCompanyController.dispose();
    _visitorPreferenceController.dispose();
    _dietaryPreferencesController.dispose();
    _postpartumPainManagementController.dispose();
    _religiousConsiderationsController.dispose();
    _culturalConsiderationsController.dispose();
    _accessibilityNeedsController.dispose();
    _traumaHistoryController.dispose();
    _anxietyTriggerController.dispose();
    _fearReductionController.dispose();
    _inMyOwnWordsController.dispose();
    super.dispose();
  }

  Future<void> _generateBirthPlan() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser!.uid;
      
      // Get user profile for name
      final profile = await _databaseService.getUserProfile(userId);
      if (profile == null) {
        throw Exception('User profile not found');
      }
      
      // Create birth plan object
      final birthPlan = BirthPlan(
        userId: userId,
        fullName: profile.name,
        dueDate: _dueDate,
        supportPersonName: _supportPersonNameController.text.trim().isEmpty 
            ? null 
            : _supportPersonNameController.text.trim(),
        supportPersonRelationship: _supportPersonRelationshipController.text.trim().isEmpty 
            ? null 
            : _supportPersonRelationshipController.text.trim(),
        emergencyContact: _contactInfoController.text.trim().isEmpty 
            ? null 
            : _contactInfoController.text.trim(),
        allergies: _allergies,
        medicalConditions: _medicalConditions,
        pregnancyComplications: _pregnancyComplications,
        // environmentPreferences removed - now using lightingPreference, noisePreference, visitorsAllowed
        photographyAllowed: _photographyAllowed,
        videographyAllowed: _videographyAllowed,
        preferredLanguage: _preferredLanguage,
        traumaInformedCare: _traumaInformedCare,
        preferredLaborPositions: _preferredLaborPositions,
        movementFreedom: _movementFreedom,
        monitoringPreference: _monitoringPreference,
        painManagementPreference: _painManagementPreference,
        useDoula: _useDoula,
        waterLaborAvailable: _waterLaborAvailable,
        augmentationPreference: _membraneSweepingPreference, // membrane sweep is now part of augmentation
        inductionMethodsPreference: _inductionPreference,
        communicationStyle: _communicationStyle,
        preferredPushingPositions: _preferredPushingPositions,
        coachingStyle: _pushingStyle, // pushingStyle renamed to coachingStyle
        mirrorDuringPushing: _mirrorDuringPushing,
        episiotomyPreference: _episiotomyPreference,
        // tearingPreference removed
        whoCatchesBaby: _whoCatchesBaby,
        delayedPushingWithEpidural: _delayedPushingWithEpidural,
        delayedCordClampingPreference: _delayedCordClampingPreference,
        whoCutsCord: _whoCutsCord,
        immediateSkinToSkin: _immediateSkinToSkin,
        delayedNewbornProcedures: _babyStaysWithParent, // babyStaysWithParent -> delayedNewbornProcedures
        vitaminK: _vitaminK,
        // eyeOintment removed
        hepBVaccine: _hepBVaccine,
        placentaPreference: _cordBloodBanking == true ? 'Save placenta' : null, // cordBloodBanking -> placentaPreference
        // cordBloodCompany removed
        feedingPreference: _feedingPreference,
        lactationConsultantRequested: _lactationConsultantRequested,
        noPacifierUntilBreastfeeding: _noPacifierUntilBreastfeeding,
        consentForDonorMilk: _consentForDonorMilk,
        roomingIn: _roomingIn,
        mentalHealthScreeningPreference: _mentalHealthSupport,
        visitorsAfterBirth: _visitorPreferenceController.text.trim().isEmpty 
            ? null 
            : _visitorPreferenceController.text.trim(),
        dietaryPreferences: _dietaryPreferencesController.text.trim().isEmpty 
            ? null 
            : _dietaryPreferencesController.text.trim(),
        postpartumPainControlPlan: _postpartumPainManagementController.text.trim().isEmpty 
            ? null 
            : _postpartumPainManagementController.text.trim(),
        cesareanDrapePreference: _drapePreference,
        supportPersonInOR: _partnerInOR,
        // photosAllowedInOR removed
        immediateSkinToSkinInOR: _babyOnChestImmediately,
        // delayNewbornCareUntilHolding removed
        // anesthesiaPreference removed
        // surgicalClosurePreference removed
        culturalReligiousRituals: _religiousConsiderationsController.text.trim().isEmpty 
            ? null 
            : _religiousConsiderationsController.text.trim(),
        // culturalConsiderations removed (now part of culturalReligiousRituals)
        accessibilityNeeds: _accessibilityNeedsController.text.trim().isEmpty 
            ? null 
            : _accessibilityNeedsController.text.trim(),
        pastBirthTraumaOrComplications: _traumaHistoryController.text.trim().isEmpty 
            ? null 
            : _traumaHistoryController.text.trim(),
        anxietyTriggers: _anxietyTriggers,
        consentBasedCare: _consentBasedCare,
        preferredBadNewsDelivery: _preferredBadNewsDelivery,
        fearReductionRequests: _fearReductionRequests,
        inMyOwnWords: _inMyOwnWordsController.text.trim().isEmpty 
            ? null 
            : _inMyOwnWordsController.text.trim(),
        providerName: _providerName,
      );

      // Format the birth plan
      final formatter = BirthPlanFormatter();
      final formattedPlan = formatter.format(birthPlan);
      
      // Update birth plan with formatted content
      final updatedPlan = BirthPlan(
        id: birthPlan.id,
        userId: birthPlan.userId,
        fullName: birthPlan.fullName,
        dueDate: birthPlan.dueDate,
        supportPersonName: birthPlan.supportPersonName,
        supportPersonRelationship: birthPlan.supportPersonRelationship,
        emergencyContact: birthPlan.emergencyContact,
        allergies: birthPlan.allergies,
        medicalConditions: birthPlan.medicalConditions,
        pregnancyComplications: birthPlan.pregnancyComplications,
        // environmentPreferences removed
        photographyAllowed: birthPlan.photographyAllowed,
        videographyAllowed: birthPlan.videographyAllowed,
        preferredLanguage: birthPlan.preferredLanguage,
        traumaInformedCare: birthPlan.traumaInformedCare,
        preferredLaborPositions: birthPlan.preferredLaborPositions,
        movementFreedom: birthPlan.movementFreedom,
        monitoringPreference: birthPlan.monitoringPreference,
        painManagementPreference: birthPlan.painManagementPreference,
        useDoula: birthPlan.useDoula,
        waterLaborAvailable: birthPlan.waterLaborAvailable,
        augmentationPreference: birthPlan.augmentationPreference,
        inductionMethodsPreference: birthPlan.inductionMethodsPreference,
        communicationStyle: birthPlan.communicationStyle,
        preferredPushingPositions: birthPlan.preferredPushingPositions,
        coachingStyle: birthPlan.coachingStyle,
        mirrorDuringPushing: birthPlan.mirrorDuringPushing,
        episiotomyPreference: birthPlan.episiotomyPreference,
        // tearingPreference removed
        whoCatchesBaby: birthPlan.whoCatchesBaby,
        delayedPushingWithEpidural: birthPlan.delayedPushingWithEpidural,
        delayedCordClampingPreference: birthPlan.delayedCordClampingPreference,
        whoCutsCord: birthPlan.whoCutsCord,
        immediateSkinToSkin: birthPlan.immediateSkinToSkin,
        delayedNewbornProcedures: birthPlan.delayedNewbornProcedures,
        vitaminK: birthPlan.vitaminK,
        // eyeOintment removed
        hepBVaccine: birthPlan.hepBVaccine,
        placentaPreference: birthPlan.placentaPreference,
        // cordBloodCompany removed
        feedingPreference: birthPlan.feedingPreference,
        lactationConsultantRequested: birthPlan.lactationConsultantRequested,
        noPacifierUntilBreastfeeding: birthPlan.noPacifierUntilBreastfeeding,
        consentForDonorMilk: birthPlan.consentForDonorMilk,
        roomingIn: birthPlan.roomingIn,
        mentalHealthScreeningPreference: birthPlan.mentalHealthScreeningPreference,
        visitorsAfterBirth: birthPlan.visitorsAfterBirth,
        dietaryPreferences: birthPlan.dietaryPreferences,
        postpartumPainControlPlan: birthPlan.postpartumPainControlPlan,
        cesareanDrapePreference: birthPlan.cesareanDrapePreference,
        supportPersonInOR: birthPlan.supportPersonInOR,
        // photosAllowedInOR removed
        immediateSkinToSkinInOR: birthPlan.immediateSkinToSkinInOR,
        // delayNewbornCareUntilHolding removed
        // anesthesiaPreference removed
        // surgicalClosurePreference removed
        culturalReligiousRituals: birthPlan.culturalReligiousRituals,
        // culturalConsiderations removed (now part of culturalReligiousRituals)
        accessibilityNeeds: birthPlan.accessibilityNeeds,
        pastBirthTraumaOrComplications: birthPlan.pastBirthTraumaOrComplications,
        anxietyTriggers: birthPlan.anxietyTriggers,
        consentBasedCare: birthPlan.consentBasedCare,
        preferredBadNewsDelivery: birthPlan.preferredBadNewsDelivery,
        fearReductionRequests: birthPlan.fearReductionRequests,
        inMyOwnWords: birthPlan.inMyOwnWords,
        formattedPlan: formattedPlan,
        createdAt: birthPlan.createdAt,
        providerName: birthPlan.providerName,
      );

      // Save to Firestore with complete status
      final planData = updatedPlan.toFirestore();
      planData['status'] = 'complete';
      final docRef = await FirebaseFirestore.instance
          .collection('birth_plans')
          .add(planData);

      // Generate and save todos
      await _generateTodos(updatedPlan);

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BirthPlanDisplayScreen(
              birthPlan: updatedPlan.copyWith(id: docRef.id),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _generateTodos(BirthPlan plan) async {
    final userId = _auth.currentUser!.uid;
    final todos = <Map<String, dynamic>>[];

    // Medical Preparation To-Dos
    if (plan.delayedCordClampingPreference != null) {
      todos.add({
        'title': 'Ask OB provider about delayed cord clamping policy',
        'description': 'Confirm hospital policy on delayed cord clamping',
        'category': 'Medical Preparation',
      });
    }
    if (plan.waterLaborAvailable == true) {
      todos.add({
        'title': 'Ask about water birth availability',
        'description': 'Confirm if hospital offers water birth option',
        'category': 'Medical Preparation',
      });
    }
    if (plan.monitoringPreference == 'Intermittent') {
      todos.add({
        'title': 'Confirm intermittent monitoring eligibility',
        'description': 'Ask if you qualify for intermittent monitoring during unmedicated birth',
        'category': 'Medical Preparation',
      });
    }
    if (plan.inductionMethodsPreference != null) {
      todos.add({
        'title': 'Ask when to arrive if planning scheduled induction',
        'description': 'Get specific instructions for induction day',
        'category': 'Medical Preparation',
      });
    }
    if (plan.useDoula) {
      todos.add({
        'title': 'Ask about doula support rules',
        'description': 'Confirm hospital policy on doula presence',
        'category': 'Medical Preparation',
      });
    }
    todos.addAll([
      {'title': 'Schedule your hospital tour', 'description': 'Tour the labor and delivery unit', 'category': 'Medical Preparation'},
      {'title': 'Complete pre-registration for your hospital', 'description': 'Fill out hospital pre-registration forms', 'category': 'Medical Preparation'},
      {'title': 'Confirm pediatrician selection', 'description': 'Choose and confirm pediatrician for baby', 'category': 'Medical Preparation'},
    ]);

    // Labor Comfort Prep To-Dos
    if (plan.painManagementPreference != null || plan.lightingPreference != null || plan.noisePreference != null) {
      todos.addAll([
        {'title': 'Pack labor comfort items', 'description': 'Playlist, dim lights, robe, heating pad', 'category': 'Labor Comfort Prep'},
        {'title': 'Download your birth playlist', 'description': 'Create and download music for labor', 'category': 'Labor Comfort Prep'},
        {'title': 'Buy snacks + electrolyte drinks for labor', 'description': 'Stock up on labor snacks', 'category': 'Labor Comfort Prep'},
      ]);
    }
    if (plan.preferredLaborPositions.contains('Birthing ball')) {
      todos.add({
        'title': 'Order or borrow a birthing ball',
        'description': 'Get birthing ball for labor positions',
        'category': 'Labor Comfort Prep',
      });
    }
    todos.add({
      'title': 'Practice breathing exercises / labor positions',
      'description': 'Practice comfort measures for labor',
      'category': 'Labor Comfort Prep',
    });

    // Paperwork & Permissions To-Dos
    if (plan.placentaPreference != null && plan.placentaPreference!.contains('Save')) {
      todos.add({
        'title': 'Complete paperwork for cord blood banking',
        'description': 'Fill out cord blood banking forms',
        'category': 'Paperwork & Permissions',
      });
    }
    todos.addAll([
      {'title': 'Add hospital to insurance notifications', 'description': 'Notify insurance of hospital choice', 'category': 'Paperwork & Permissions'},
      {'title': 'Fill out breast pump order forms', 'description': 'Order breast pump through insurance', 'category': 'Paperwork & Permissions'},
      {'title': 'Print 2 copies of the birth plan', 'description': 'Print birth plan for hospital bag', 'category': 'Paperwork & Permissions'},
      {'title': 'Arrange FMLA / maternity leave paperwork', 'description': 'Complete leave paperwork', 'category': 'Paperwork & Permissions'},
      {'title': 'Create a visitor list + boundaries', 'description': 'Prepare visitor guidelines for nurses', 'category': 'Paperwork & Permissions'},
    ]);

    // Baby Care To-Dos
    if (plan.feedingPreference == 'Breastfeeding' || plan.feedingPreference == 'Combo feeding') {
      todos.addAll([
        {'title': 'Purchase breastfeeding supplies', 'description': 'Nipple cream, pump parts, bottles as backup', 'category': 'Baby Care'},
        {'title': 'Confirm hospital has a lactation consultant', 'description': 'Verify lactation support availability', 'category': 'Baby Care'},
      ]);
    }
    if (plan.feedingPreference == 'Formula feeding' || plan.feedingPreference == 'Combo feeding') {
      todos.add({
        'title': 'Order formula samples',
        'description': 'Get formula samples if planning mixed or formula feeding',
        'category': 'Baby Care',
      });
    }
    todos.addAll([
      {'title': 'Buy newborn onesies, swaddles, diapers', 'description': 'Stock up on newborn essentials', 'category': 'Baby Care'},
      {'title': 'Install the car seat and get it inspected', 'description': 'Install and verify car seat installation', 'category': 'Baby Care'},
    ]);

    // Logistical To-Dos
    if (plan.supportPersonName != null) {
      todos.add({
        'title': 'Pack partner\'s hospital bag',
        'description': 'Prepare support person\'s bag',
        'category': 'Logistical',
      });
    }
    if (plan.photographyAllowed == true || plan.videographyAllowed == true) {
      todos.add({
        'title': 'Install phone chargers and camera/GoPro',
        'description': 'Prepare photography equipment',
        'category': 'Logistical',
      });
    }
    todos.addAll([
      {'title': 'Arrange child or pet care for day of labor', 'description': 'Plan childcare/pet care', 'category': 'Logistical'},
      {'title': 'Map fastest route to hospital', 'description': 'Plan routes at various times of day', 'category': 'Logistical'},
      {'title': 'Add doula/midwife/pediatrician contacts', 'description': 'Save important contacts in phone', 'category': 'Logistical'},
    ]);

    // Mental & Emotional Support To-Dos
    if (plan.traumaInformedCare || plan.pastBirthTraumaOrComplications != null) {
      todos.addAll([
        {'title': 'Identify grounding techniques', 'description': 'Practice techniques for medical exams', 'category': 'Mental & Emotional Support'},
        {'title': 'Share trauma-informed preferences with OB team', 'description': 'Communicate needs to care team', 'category': 'Mental & Emotional Support'},
        {'title': 'Create a "How to Support Me" card for partner', 'description': 'Prepare support instructions', 'category': 'Mental & Emotional Support'},
      ]);
    }
    if (plan.mentalHealthScreeningPreference == true) {
      todos.add({
        'title': 'Schedule a therapy check-in',
        'description': 'Prenatal mental health provider appointment',
        'category': 'Mental & Emotional Support',
      });
    }
    todos.add({
      'title': 'Plan 2–3 postpartum support people',
      'description': 'Arrange meals + house help',
      'category': 'Mental & Emotional Support',
    });

    // Home Preparation To-Dos
    todos.addAll([
      {'title': 'Prepare a postpartum recovery basket', 'description': 'Pads, pain spray, peri bottle', 'category': 'Home Preparation'},
      {'title': 'Set up baby sleep space', 'description': 'Prepare baby\'s sleeping area', 'category': 'Home Preparation'},
      {'title': 'Wash baby clothes + sheets', 'description': 'Prepare baby laundry', 'category': 'Home Preparation'},
      {'title': 'Stock freezer meals', 'description': 'Prepare meals for postpartum', 'category': 'Home Preparation'},
      {'title': 'Set aside comfortable postpartum clothing', 'description': 'Prepare recovery wardrobe', 'category': 'Home Preparation'},
      {'title': 'Prepare a feeding station', 'description': 'Burp cloths, water bottle, snacks', 'category': 'Home Preparation'},
    ]);

    // Time-Specific To-Dos
    final weeksPregnant = _calculateWeeksPregnant(plan.dueDate);
    if (weeksPregnant >= 30 && weeksPregnant < 35) {
      todos.addAll([
        {'title': 'Hospital tour', 'description': 'Tour labor and delivery unit', 'category': 'Time-Specific (30-34 weeks)'},
        {'title': 'Birth class', 'description': 'Attend childbirth education class', 'category': 'Time-Specific (30-34 weeks)'},
        {'title': 'Pediatrician selection', 'description': 'Choose pediatrician', 'category': 'Time-Specific (30-34 weeks)'},
      ]);
    } else if (weeksPregnant >= 35 && weeksPregnant < 38) {
      todos.addAll([
        {'title': 'Pack hospital bag', 'description': 'Prepare hospital bag', 'category': 'Time-Specific (35-37 weeks)'},
        {'title': 'Install car seat', 'description': 'Install and verify car seat', 'category': 'Time-Specific (35-37 weeks)'},
        {'title': 'Finalize birth plan', 'description': 'Review and finalize birth plan', 'category': 'Time-Specific (35-37 weeks)'},
      ]);
    } else if (weeksPregnant >= 38) {
      todos.addAll([
        {'title': 'Prepare home', 'description': 'Final home preparations', 'category': 'Time-Specific (38-40 weeks)'},
        {'title': 'Reduce schedule to lower stress', 'description': 'Simplify commitments', 'category': 'Time-Specific (38-40 weeks)'},
        {'title': 'Keep hospital bag by door', 'description': 'Ready to go at a moment\'s notice', 'category': 'Time-Specific (38-40 weeks)'},
      ]);
    }

    // Save todos to Firestore
    for (final todo in todos) {
      await FirebaseFirestore.instance.collection('learning_tasks').add({
        'userId': userId,
        'title': todo['title'],
        'description': todo['description'],
        'category': todo['category'],
        'trimester': _getTrimesterFromWeeks(weeksPregnant),
        'isGenerated': true,
        'createdAt': FieldValue.serverTimestamp(),
        'isBirthPlanTodo': true,
      });
    }
  }

  int _calculateWeeksPregnant(DateTime? dueDate) {
    if (dueDate == null) return 0;
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    return (40 - (daysUntilDue / 7)).floor();
  }

  String _getTrimesterFromWeeks(int weeks) {
    if (weeks <= 13) return 'First';
    if (weeks <= 27) return 'Second';
    return 'Third';
  }

  Future<Map<String, dynamic>> _getProgressData() {
    return {
      'supportPersonName': _supportPersonNameController.text,
      'supportPersonRelationship': _supportPersonRelationshipController.text,
      'contactInfo': _contactInfoController.text,
      'allergy': _allergyController.text,
      'medicalCondition': _medicalConditionController.text,
      'complication': _complicationController.text,
      'dueDate': _dueDate?.toIso8601String(),
      'allergies': _allergies,
      'medicalConditions': _medicalConditions,
      'pregnancyComplications': _pregnancyComplications,
      'environmentPreferences': _environmentPreferences,
      'photographyAllowed': _photographyAllowed,
      'videographyAllowed': _videographyAllowed,
      'preferredLanguage': _preferredLanguage,
      'traumaInformedCare': _traumaInformedCare,
      'preferredLaborPositions': _preferredLaborPositions,
      'movementFreedom': _movementFreedom,
      'monitoringPreference': _monitoringPreference,
      'painManagementPreference': _painManagementPreference,
      'useDoula': _useDoula,
      'waterLaborAvailable': _waterLaborAvailable,
      'membraneSweepingPreference': _membraneSweepingPreference,
      'inductionPreference': _inductionPreference,
      'communicationStyle': _communicationStyle,
      'preferredPushingPositions': _preferredPushingPositions,
      'pushingStyle': _pushingStyle,
      'mirrorDuringPushing': _mirrorDuringPushing,
      'episiotomyPreference': _episiotomyPreference,
      'tearingPreference': _tearingPreference,
      'whoCatchesBaby': _whoCatchesBaby,
      'delayedPushingWithEpidural': _delayedPushingWithEpidural,
      'delayedCordClampingPreference': _delayedCordClampingPreference,
      'whoCutsCord': _whoCutsCord,
      'immediateSkinToSkin': _immediateSkinToSkin,
      'babyStaysWithParent': _babyStaysWithParent,
      'vitaminK': _vitaminK,
      'eyeOintment': _eyeOintment,
      'hepBVaccine': _hepBVaccine,
      'cordBloodBanking': _cordBloodBanking,
      'cordBloodCompany': _cordBloodCompanyController.text,
      'feedingPreference': _feedingPreference,
      'lactationConsultantRequested': _lactationConsultantRequested,
      'noPacifierUntilBreastfeeding': _noPacifierUntilBreastfeeding,
      'consentForDonorMilk': _consentForDonorMilk,
      'roomingIn': _roomingIn,
      'mentalHealthSupport': _mentalHealthSupport,
      'visitorPreference': _visitorPreferenceController.text,
      'dietaryPreferences': _dietaryPreferencesController.text,
      'postpartumPainManagement': _postpartumPainManagementController.text,
      'drapePreference': _drapePreference,
      'partnerInOR': _partnerInOR,
      'photosAllowedInOR': _photosAllowedInOR,
      'babyOnChestImmediately': _babyOnChestImmediately,
      'delayNewbornCareUntilHolding': _delayNewbornCareUntilHolding,
      'anesthesiaPreference': _anesthesiaPreference,
      'surgicalClosurePreference': _surgicalClosurePreference,
      'religiousConsiderations': _religiousConsiderationsController.text,
      'culturalConsiderations': _culturalConsiderationsController.text,
      'accessibilityNeeds': _accessibilityNeedsController.text,
      'traumaHistory': _traumaHistoryController.text,
      'anxietyTrigger': _anxietyTriggerController.text,
      'anxietyTriggers': _anxietyTriggers,
      'consentBasedCare': _consentBasedCare,
      'preferredBadNewsDelivery': _preferredBadNewsDelivery,
      'fearReduction': _fearReductionController.text,
      'fearReductionRequests': _fearReductionRequests,
      'inMyOwnWords': _inMyOwnWordsController.text,
    };
  }

  Future<void> _saveProgress() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final progressData = _getProgressData();
      
      // Check if there's any meaningful data
      bool hasData = false;
      for (var value in progressData.values) {
        if (value != null && value != '' && value != false) {
          if (value is List && value.isNotEmpty) {
            hasData = true;
            break;
          } else if (value is! List) {
            hasData = true;
            break;
          }
        }
      }

      if (!hasData) return; // Don't save if no data

      // Save as incomplete birth plan draft
      await FirebaseFirestore.instance.collection('birth_plans').add({
        'userId': userId,
        'status': 'incomplete',
        'progressData': progressData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error saving progress: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          await _saveProgress();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Birth Plan'),
          backgroundColor: AppTheme.brandPurple,
          foregroundColor: Colors.white,
        ),
        body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Birth Plan Creator',
                style: AppTheme.responsiveTitleStyle(
                  context,
                  baseSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandPurple,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a comprehensive birth plan that shares your wishes with your healthcare team',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // Section 1: Parent Information
              _buildSection1(),
              const SizedBox(height: 24),
              
              // Section 2: Environment
              _buildSection2(),
              const SizedBox(height: 24),
              
              // Section 3: Labor
              _buildSection3(),
              const SizedBox(height: 24),
              
              // Section 4: Pushing
              _buildSection4(),
              const SizedBox(height: 24),
              
              // Section 5: Newborn Care
              _buildSection5(),
              const SizedBox(height: 24),
              
              // Section 6: Feeding
              _buildSection6(),
              const SizedBox(height: 24),
              
              // Section 7: Postpartum
              _buildSection7(),
              const SizedBox(height: 24),
              
              // Section 8: Cesarean
              _buildSection8(),
              const SizedBox(height: 24),
              
              // Section 9: Special Considerations
              _buildSection9(),
              const SizedBox(height: 24),
              
              // Section 10: In My Own Words
              _buildSection10(),
              const SizedBox(height: 32),
              
              // Generate Button
              ElevatedButton(
                onPressed: _isLoading ? null : _generateBirthPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Generate Birth Plan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSection1() {
    return ExpansionTile(
      title: const Text('Section 1: Parent Information', style: TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: true,
      children: [
        ListTile(
          title: const Text('Due Date'),
          subtitle: Text(_dueDate != null ? DateFormat('MMMM d, yyyy').format(_dueDate!) : 'Tap to select'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 180)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) setState(() => _dueDate = date);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _supportPersonNameController,
          decoration: const InputDecoration(labelText: 'Support Person(s) Name', prefixIcon: Icon(Icons.people)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _supportPersonRelationshipController,
          decoration: const InputDecoration(labelText: 'Relationship', prefixIcon: Icon(Icons.family_restroom)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactInfoController,
          decoration: const InputDecoration(labelText: 'Contact Info (for emergencies)', prefixIcon: Icon(Icons.phone)),
        ),
        const SizedBox(height: 16),
        _buildListInput('Allergies', _allergyController, _allergies, (item) {
          setState(() => _allergies.add(item));
          _allergyController.clear();
        }, (index) {
          setState(() => _allergies.removeAt(index));
        }),
        const SizedBox(height: 16),
        _buildListInput('Medical Conditions', _medicalConditionController, _medicalConditions, (item) {
          setState(() => _medicalConditions.add(item));
          _medicalConditionController.clear();
        }, (index) {
          setState(() => _medicalConditions.removeAt(index));
        }),
        const SizedBox(height: 16),
        _buildListInput('Pregnancy Complications', _complicationController, _pregnancyComplications, (item) {
          setState(() => _pregnancyComplications.add(item));
          _complicationController.clear();
        }, (index) {
          setState(() => _pregnancyComplications.removeAt(index));
        }),
      ],
    );
  }

  Widget _buildSection2() {
    return ExpansionTile(
      title: const Text('Section 2: Labor & Delivery Environment', style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        _buildMultiSelectChips(
          'Preferred Environment',
          ['Calm/quiet', 'Music', 'Low light', 'Minimal staff interruptions'],
          _environmentPreferences,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Photography Allowed'),
          value: _photographyAllowed ?? false,
          onChanged: (v) => setState(() => _photographyAllowed = v),
        ),
        SwitchListTile(
          title: const Text('Videography Allowed'),
          value: _videographyAllowed ?? false,
          onChanged: (v) => setState(() => _videographyAllowed = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Preferred Language'),
          items: ['English', 'Spanish', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _preferredLanguage = v),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Trauma-informed preferences'),
          subtitle: const Text('Please tell me before touching/exams'),
          value: _traumaInformedCare,
          onChanged: (v) => setState(() => _traumaInformedCare = v),
        ),
      ],
    );
  }

  Widget _buildSection3() {
    return ExpansionTile(
      title: const Text('Section 3: Labor Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        _buildMultiSelectChips(
          'Preferred Labor Positions',
          ['Walking', 'Birthing ball', 'Tub', 'Bed', 'Squatting', 'Hands and knees', 'Side-lying'],
          _preferredLaborPositions,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Movement Freedom'),
          subtitle: const Text('Do you want to move freely?'),
          value: _movementFreedom,
          onChanged: (v) => setState(() => _movementFreedom = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Monitoring Preference'),
          items: ['Intermittent', 'Continuous', 'Wireless if available'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _monitoringPreference = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Pain Management Preference'),
          items: ['Unmedicated', 'Epidural', 'Nitrous oxide', 'IV pain meds', 'Comfort measures only'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _painManagementPreference = v),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Use of Doula'),
          value: _useDoula,
          onChanged: (v) => setState(() => _useDoula = v),
        ),
        SwitchListTile(
          title: const Text('Water Labor Available'),
          value: _waterLaborAvailable ?? false,
          onChanged: (v) => setState(() => _waterLaborAvailable = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Membrane Sweeping Preference'),
          items: ['Yes, if offered', 'No', 'Only if medically indicated'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _membraneSweepingPreference = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Induction Preference if Necessary'),
          items: ['Natural methods first', 'Open to medical induction', 'Prefer to avoid'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _inductionPreference = v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Preferred Communication Style', hintText: 'e.g., "explain options first", "keep me calm"'),
          onChanged: (v) => setState(() => _communicationStyle = v),
        ),
      ],
    );
  }

  Widget _buildSection4() {
    return ExpansionTile(
      title: const Text('Section 4: Pushing & Birth Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        _buildMultiSelectChips(
          'Preferred Pushing Positions',
          ['Hands and knees', 'Side-lying', 'Squatting', 'Semi-reclined', 'Whatever feels right'],
          _preferredPushingPositions,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Pushing Style'),
          items: ['Guided', 'Spontaneous', 'Either'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _pushingStyle = v),
        ),
        SwitchListTile(
          title: const Text('Mirror during pushing?'),
          value: _mirrorDuringPushing ?? false,
          onChanged: (v) => setState(() => _mirrorDuringPushing = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Episiotomy Preference'),
          items: ['Avoid unless absolutely necessary', 'Open to if needed', 'No preference'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _episiotomyPreference = v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Tearing Preference', hintText: 'e.g., warm compresses, perineal support'),
          onChanged: (v) => setState(() => _tearingPreference = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Who Catches the Baby'),
          items: ['Partner', 'Doctor', 'Midwife', 'Myself'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _whoCatchesBaby = v),
        ),
        SwitchListTile(
          title: const Text('Preference for delayed pushing if epidural present'),
          value: _delayedPushingWithEpidural ?? false,
          onChanged: (v) => setState(() => _delayedPushingWithEpidural = v),
        ),
      ],
    );
  }

  Widget _buildSection5() {
    return ExpansionTile(
      title: const Text('Section 5: Immediate Newborn Care', style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Delayed Cord Clamping Preference'),
          items: ['1-3 minutes', '3-5 minutes', 'Until cord stops pulsing', 'No preference'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _delayedCordClampingPreference = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Who Cuts the Cord'),
          items: ['Partner', 'Myself', 'Doctor', 'No preference'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _whoCutsCord = v),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Immediate Skin-to-Skin'),
          value: _immediateSkinToSkin,
          onChanged: (v) => setState(() => _immediateSkinToSkin = v),
        ),
        SwitchListTile(
          title: const Text('Baby Stays with Parent for Assessments'),
          subtitle: const Text('vs. moved to warmer'),
          value: _babyStaysWithParent,
          onChanged: (v) => setState(() => _babyStaysWithParent = v),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Vitamin K Shot'),
          value: _vitaminK ?? true,
          onChanged: (v) => setState(() => _vitaminK = v),
        ),
        SwitchListTile(
          title: const Text('Erythromycin Eye Ointment'),
          value: _eyeOintment ?? true,
          onChanged: (v) => setState(() => _eyeOintment = v),
        ),
        SwitchListTile(
          title: const Text('Hepatitis B Vaccine'),
          value: _hepBVaccine ?? true,
          onChanged: (v) => setState(() => _hepBVaccine = v),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Cord Blood Banking'),
          value: _cordBloodBanking ?? false,
          onChanged: (v) => setState(() => _cordBloodBanking = v),
        ),
        if (_cordBloodBanking == true) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _cordBloodCompanyController,
            decoration: const InputDecoration(labelText: 'Cord Blood Company'),
          ),
        ],
      ],
    );
  }

  Widget _buildSection6() {
    return ExpansionTile(
      title: const Text('Section 6: Feeding Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Feeding Preference'),
          items: ['Breastfeeding', 'Formula feeding', 'Combo feeding'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _feedingPreference = v),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Lactation Consultant Requested'),
          value: _lactationConsultantRequested,
          onChanged: (v) => setState(() => _lactationConsultantRequested = v),
        ),
        SwitchListTile(
          title: const Text('No Pacifier Until Breastfeeding Established'),
          value: _noPacifierUntilBreastfeeding ?? false,
          onChanged: (v) => setState(() => _noPacifierUntilBreastfeeding = v),
        ),
        SwitchListTile(
          title: const Text('Consent for Donor Milk if Needed'),
          value: _consentForDonorMilk ?? false,
          onChanged: (v) => setState(() => _consentForDonorMilk = v),
        ),
      ],
    );
  }

  Widget _buildSection7() {
    return ExpansionTile(
      title: const Text('Section 7: Postpartum Care Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        SwitchListTile(
          title: const Text('Rooming-In Preference'),
          subtitle: const Text('Baby stays in room vs nursery use'),
          value: _roomingIn ?? true,
          onChanged: (v) => setState(() => _roomingIn = v),
        ),
        SwitchListTile(
          title: const Text('Mental Health Support Needs'),
          value: _mentalHealthSupport ?? false,
          onChanged: (v) => setState(() => _mentalHealthSupport = v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _visitorPreferenceController,
          decoration: const InputDecoration(labelText: 'Visitors Allowed? Times?', hintText: 'e.g., partner only for first 24 hours'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dietaryPreferencesController,
          decoration: const InputDecoration(labelText: 'Dietary Preferences', hintText: 'e.g., vegetarian, etc.'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _postpartumPainManagementController,
          decoration: const InputDecoration(labelText: 'Pain Management Preferences Postpartum', hintText: 'e.g., ibuprofen first, then stronger meds if needed'),
        ),
      ],
    );
  }

  Widget _buildSection8() {
    return ExpansionTile(
      title: const Text('Section 8: Cesarean Birth Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Important even if planning vaginal birth'),
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Drape Preference'),
          items: ['Clear drape', 'Standard drape', 'No preference'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _drapePreference = v),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Partner Presence in OR'),
          value: _partnerInOR ?? true,
          onChanged: (v) => setState(() => _partnerInOR = v),
        ),
        SwitchListTile(
          title: const Text('Photos Allowed?'),
          value: _photosAllowedInOR ?? true,
          onChanged: (v) => setState(() => _photosAllowedInOR = v),
        ),
        SwitchListTile(
          title: const Text('Baby Placed on Chest Immediately'),
          subtitle: const Text('Gentle cesarean'),
          value: _babyOnChestImmediately ?? true,
          onChanged: (v) => setState(() => _babyOnChestImmediately = v),
        ),
        SwitchListTile(
          title: const Text('Delay Routine Newborn Care Until Parent Holding Baby'),
          value: _delayNewbornCareUntilHolding ?? false,
          onChanged: (v) => setState(() => _delayNewbornCareUntilHolding = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Preferred Anesthesia Type'),
          items: ['Spinal', 'Epidural', 'General (if emergency)', 'No preference'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _anesthesiaPreference = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Surgical Closure Preference'),
          items: ['Staples', 'Sutures', 'Dissolvable', 'No preference'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _surgicalClosurePreference = v),
        ),
      ],
    );
  }

  Widget _buildSection9() {
    return ExpansionTile(
      title: const Text('Section 9: Special Considerations', style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        TextFormField(
          controller: _religiousConsiderationsController,
          decoration: const InputDecoration(labelText: 'Religious Considerations'),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _culturalConsiderationsController,
          decoration: const InputDecoration(labelText: 'Cultural Considerations'),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _accessibilityNeedsController,
          decoration: const InputDecoration(labelText: 'Accessibility Needs'),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _traumaHistoryController,
          decoration: const InputDecoration(labelText: 'History of Trauma (only if you choose)'),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildListInput('Anxiety Triggers', _anxietyTriggerController, _anxietyTriggers, (item) {
          setState(() => _anxietyTriggers.add(item));
          _anxietyTriggerController.clear();
        }, (index) {
          setState(() => _anxietyTriggers.removeAt(index));
        }),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Requests for More Consent-Based Care'),
          value: _consentBasedCare,
          onChanged: (v) => setState(() => _consentBasedCare = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Preferred Ways to Receive Bad News'),
          items: ['Private conversation', 'With partner present', 'Written first, then discussion', 'Direct and clear'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _preferredBadNewsDelivery = v),
        ),
        const SizedBox(height: 16),
        _buildListInput('Things That Reduce Fear/Panic', _fearReductionController, _fearReductionRequests, (item) {
          setState(() => _fearReductionRequests.add(item));
          _fearReductionController.clear();
        }, (index) {
          setState(() => _fearReductionRequests.removeAt(index));
        }),
      ],
    );
  }

  Widget _buildSection10() {
    return ExpansionTile(
      title: const Text('Section 10: In My Own Words', style: TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: true,
      children: [
        TextFormField(
          controller: _inMyOwnWordsController,
          decoration: const InputDecoration(
            labelText: 'Things I want my care team to know about me',
            hintText: 'What helps me feel safe during labor?',
          ),
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildListInput(
    String label,
    TextEditingController controller,
    List<String> items,
    Function(String) onAdd,
    Function(int) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Add item'),
                onSubmitted: (v) {
                  if (v.isNotEmpty) onAdd(v);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onAdd(controller.text);
                }
              },
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => onRemove(entry.key),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMultiSelectChips(String label, List<String> options, List<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    if (!selected.contains(option)) {
                      selected.add(option);
                    }
                  } else {
                    selected.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Extension to add copyWith method to BirthPlan
extension BirthPlanCopyWith on BirthPlan {
  BirthPlan copyWith({
    String? id,
    String? userId,
    String? fullName,
    DateTime? dueDate,
    String? supportPersonName,
    String? supportPersonRelationship,
    String? emergencyContact,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? pregnancyComplications,
    // environmentPreferences removed
    bool? photographyAllowed,
    bool? videographyAllowed,
    String? preferredLanguage,
    bool? traumaInformedCare,
    List<String>? preferredLaborPositions,
    bool? movementFreedom,
    String? monitoringPreference,
    String? painManagementPreference,
    bool? useDoula,
    bool? waterLaborAvailable,
    String? augmentationPreference,
    String? inductionMethodsPreference,
    String? communicationStyle,
    List<String>? preferredPushingPositions,
    String? coachingStyle,
    bool? mirrorDuringPushing,
    String? episiotomyPreference,
    // tearingPreference removed
    String? whoCatchesBaby,
    bool? delayedPushingWithEpidural,
    String? delayedCordClampingPreference,
    String? whoCutsCord,
    bool? immediateSkinToSkin,
    bool? delayedNewbornProcedures,
    bool? vitaminK,
    // eyeOintment removed
    bool? hepBVaccine,
    String? placentaPreference,
    // cordBloodCompany removed
    String? feedingPreference,
    bool? lactationConsultantRequested,
    bool? noPacifierUntilBreastfeeding,
    bool? consentForDonorMilk,
    bool? roomingIn,
    bool? mentalHealthScreeningPreference,
    String? visitorsAfterBirth,
    String? dietaryPreferences,
    String? postpartumPainControlPlan,
    String? cesareanDrapePreference,
    bool? supportPersonInOR,
    // photosAllowedInOR removed
    bool? immediateSkinToSkinInOR,
    // delayNewbornCareUntilHolding removed
    String? anesthesiaPreference,
    // surgicalClosurePreference removed
    String? culturalReligiousRituals,
    // culturalConsiderations removed (now part of culturalReligiousRituals)
    String? accessibilityNeeds,
    String? pastBirthTraumaOrComplications,
    List<String>? anxietyTriggers,
    bool? consentBasedCare,
    String? preferredBadNewsDelivery,
    List<String>? fearReductionRequests,
    String? inMyOwnWords,
    String? formattedPlan,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? providerName,
  }) {
    return BirthPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dueDate: dueDate ?? this.dueDate,
      supportPersonName: supportPersonName ?? this.supportPersonName,
      supportPersonRelationship: supportPersonRelationship ?? this.supportPersonRelationship,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      pregnancyComplications: pregnancyComplications ?? this.pregnancyComplications,
      // environmentPreferences removed
      photographyAllowed: photographyAllowed ?? this.photographyAllowed,
      videographyAllowed: videographyAllowed ?? this.videographyAllowed,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      traumaInformedCare: traumaInformedCare ?? this.traumaInformedCare,
      preferredLaborPositions: preferredLaborPositions ?? this.preferredLaborPositions,
      movementFreedom: movementFreedom ?? this.movementFreedom,
      monitoringPreference: monitoringPreference ?? this.monitoringPreference,
      painManagementPreference: painManagementPreference ?? this.painManagementPreference,
      useDoula: useDoula ?? this.useDoula,
      waterLaborAvailable: waterLaborAvailable ?? this.waterLaborAvailable,
      augmentationPreference: augmentationPreference ?? this.augmentationPreference,
      inductionMethodsPreference: inductionMethodsPreference ?? this.inductionMethodsPreference,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      preferredPushingPositions: preferredPushingPositions ?? this.preferredPushingPositions,
      coachingStyle: coachingStyle ?? this.coachingStyle,
      mirrorDuringPushing: mirrorDuringPushing ?? this.mirrorDuringPushing,
      episiotomyPreference: episiotomyPreference ?? this.episiotomyPreference,
      // tearingPreference removed
      whoCatchesBaby: whoCatchesBaby ?? this.whoCatchesBaby,
      delayedPushingWithEpidural: delayedPushingWithEpidural ?? this.delayedPushingWithEpidural,
      delayedCordClampingPreference: delayedCordClampingPreference ?? this.delayedCordClampingPreference,
      whoCutsCord: whoCutsCord ?? this.whoCutsCord,
      immediateSkinToSkin: immediateSkinToSkin ?? this.immediateSkinToSkin,
      delayedNewbornProcedures: delayedNewbornProcedures ?? this.delayedNewbornProcedures,
      vitaminK: vitaminK ?? this.vitaminK,
      // eyeOintment removed
      hepBVaccine: hepBVaccine ?? this.hepBVaccine,
      placentaPreference: placentaPreference ?? this.placentaPreference,
      // cordBloodCompany removed
      feedingPreference: feedingPreference ?? this.feedingPreference,
      lactationConsultantRequested: lactationConsultantRequested ?? this.lactationConsultantRequested,
      noPacifierUntilBreastfeeding: noPacifierUntilBreastfeeding ?? this.noPacifierUntilBreastfeeding,
      consentForDonorMilk: consentForDonorMilk ?? this.consentForDonorMilk,
      roomingIn: roomingIn ?? this.roomingIn,
      mentalHealthScreeningPreference: mentalHealthScreeningPreference ?? this.mentalHealthScreeningPreference,
      visitorsAfterBirth: visitorsAfterBirth ?? this.visitorsAfterBirth,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      postpartumPainControlPlan: postpartumPainControlPlan ?? this.postpartumPainControlPlan,
      cesareanDrapePreference: cesareanDrapePreference ?? this.cesareanDrapePreference,
      supportPersonInOR: supportPersonInOR ?? this.supportPersonInOR,
      // photosAllowedInOR removed
      immediateSkinToSkinInOR: immediateSkinToSkinInOR ?? this.immediateSkinToSkinInOR,
      // delayNewbornCareUntilHolding removed
      // anesthesiaPreference removed
      // surgicalClosurePreference removed
      culturalReligiousRituals: culturalReligiousRituals ?? this.culturalReligiousRituals,
      // culturalConsiderations removed
      accessibilityNeeds: accessibilityNeeds ?? this.accessibilityNeeds,
      pastBirthTraumaOrComplications: pastBirthTraumaOrComplications ?? this.pastBirthTraumaOrComplications,
      anxietyTriggers: anxietyTriggers ?? this.anxietyTriggers,
      consentBasedCare: consentBasedCare ?? this.consentBasedCare,
      preferredBadNewsDelivery: preferredBadNewsDelivery ?? this.preferredBadNewsDelivery,
      fearReductionRequests: fearReductionRequests ?? this.fearReductionRequests,
      inMyOwnWords: inMyOwnWords ?? this.inMyOwnWords,
      formattedPlan: formattedPlan ?? this.formattedPlan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      providerName: providerName ?? this.providerName,
    );
  }
}

