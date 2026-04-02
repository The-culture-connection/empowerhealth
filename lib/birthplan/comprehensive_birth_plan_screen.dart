import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/birth_plan.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import '../cors/ui_theme.dart';
import 'birth_plan_display_screen.dart';
import 'birth_plan_formatter.dart';
import '../widgets/qualitative_survey_dialog.dart';
import '../widgets/feature_session_scope.dart';
import 'birth_plan_why_copy.dart';

class ComprehensiveBirthPlanScreen extends StatefulWidget {
  final String? incompletePlanId; // For resuming incomplete plans
  final Map<String, dynamic>? savedProgress; // Saved progress data

  const ComprehensiveBirthPlanScreen({
    super.key,
    this.incompletePlanId,
    this.savedProgress,
  });

  @override
  State<ComprehensiveBirthPlanScreen> createState() =>
      _ComprehensiveBirthPlanScreenState();
}

class _ComprehensiveBirthPlanScreenState
    extends State<ComprehensiveBirthPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  static const int _stepCount = 5;
  int _currentStep = 0;
  final Map<String, bool> _whyExpanded = {};
  final Map<String, bool> _jargonExpanded = {};

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
    _trackScreenView();
    _loadUserProfile();
    if (widget.savedProgress != null) {
      _loadSavedProgress();
    }
  }

  Future<void> _trackScreenView() async {
    try {
      final analytics = AnalyticsService();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProfile = await _databaseService.getUserProfile(userId);
        await analytics.logScreenView(
          screenName: 'birth_plan_creator',
          feature: 'birth-plan-generator',
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking birth plan screen view: $e');
    }
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

  void _loadSavedProgress() {
    if (widget.savedProgress == null) return;
    final progress = widget.savedProgress!;

    setState(() {
      _supportPersonNameController.text = progress['supportPersonName'] ?? '';
      _supportPersonRelationshipController.text =
          progress['supportPersonRelationship'] ?? '';
      _contactInfoController.text = progress['contactInfo'] ?? '';
      _allergyController.text = progress['allergy'] ?? '';
      _medicalConditionController.text = progress['medicalCondition'] ?? '';
      _complicationController.text = progress['complication'] ?? '';

      if (progress['dueDate'] != null) {
        _dueDate = DateTime.parse(progress['dueDate']);
      }

      _allergies = List<String>.from(progress['allergies'] ?? []);
      _medicalConditions = List<String>.from(
        progress['medicalConditions'] ?? [],
      );
      _pregnancyComplications = List<String>.from(
        progress['pregnancyComplications'] ?? [],
      );
      _environmentPreferences = List<String>.from(
        progress['environmentPreferences'] ?? [],
      );
      _photographyAllowed = progress['photographyAllowed'];
      _videographyAllowed = progress['videographyAllowed'];
      _preferredLanguage = progress['preferredLanguage'];
      _traumaInformedCare = progress['traumaInformedCare'] ?? false;
      _preferredLaborPositions = List<String>.from(
        progress['preferredLaborPositions'] ?? [],
      );
      _movementFreedom = progress['movementFreedom'] ?? true;
      _monitoringPreference = progress['monitoringPreference'];
      _painManagementPreference = progress['painManagementPreference'];
      _useDoula = progress['useDoula'] ?? false;
      _waterLaborAvailable = progress['waterLaborAvailable'];
      _membraneSweepingPreference = progress['membraneSweepingPreference'];
      _inductionPreference = progress['inductionPreference'];
      _communicationStyle = progress['communicationStyle'];
      _preferredPushingPositions = List<String>.from(
        progress['preferredPushingPositions'] ?? [],
      );
      _pushingStyle = progress['pushingStyle'];
      _mirrorDuringPushing = progress['mirrorDuringPushing'];
      _episiotomyPreference = progress['episiotomyPreference'];
      _tearingPreference = progress['tearingPreference'];
      _whoCatchesBaby = progress['whoCatchesBaby'];
      _delayedPushingWithEpidural = progress['delayedPushingWithEpidural'];
      _delayedCordClampingPreference =
          progress['delayedCordClampingPreference'];
      _whoCutsCord = progress['whoCutsCord'];
      _immediateSkinToSkin = progress['immediateSkinToSkin'] ?? true;
      _babyStaysWithParent = progress['babyStaysWithParent'] ?? true;
      _vitaminK = progress['vitaminK'];
      _eyeOintment = progress['eyeOintment'];
      _hepBVaccine = progress['hepBVaccine'];
      _cordBloodBanking = progress['cordBloodBanking'];
      _cordBloodCompanyController.text = progress['cordBloodCompany'] ?? '';
      _feedingPreference = progress['feedingPreference'];
      _lactationConsultantRequested =
          progress['lactationConsultantRequested'] ?? false;
      _noPacifierUntilBreastfeeding = progress['noPacifierUntilBreastfeeding'];
      _consentForDonorMilk = progress['consentForDonorMilk'];
      _roomingIn = progress['roomingIn'];
      _mentalHealthSupport = progress['mentalHealthSupport'];
      _visitorPreferenceController.text = progress['visitorPreference'] ?? '';
      _dietaryPreferencesController.text = progress['dietaryPreferences'] ?? '';
      _postpartumPainManagementController.text =
          progress['postpartumPainManagement'] ?? '';
      _drapePreference = progress['drapePreference'];
      _partnerInOR = progress['partnerInOR'];
      _photosAllowedInOR = progress['photosAllowedInOR'];
      _babyOnChestImmediately = progress['babyOnChestImmediately'];
      _delayNewbornCareUntilHolding = progress['delayNewbornCareUntilHolding'];
      _anesthesiaPreference = progress['anesthesiaPreference'];
      _surgicalClosurePreference = progress['surgicalClosurePreference'];
      _religiousConsiderationsController.text =
          progress['religiousConsiderations'] ?? '';
      _culturalConsiderationsController.text =
          progress['culturalConsiderations'] ?? '';
      _accessibilityNeedsController.text = progress['accessibilityNeeds'] ?? '';
      _traumaHistoryController.text = progress['traumaHistory'] ?? '';
      _anxietyTriggerController.text = progress['anxietyTrigger'] ?? '';
      _anxietyTriggers = List<String>.from(progress['anxietyTriggers'] ?? []);
      _consentBasedCare = progress['consentBasedCare'] ?? false;
      _preferredBadNewsDelivery = progress['preferredBadNewsDelivery'];
      _fearReductionController.text = progress['fearReduction'] ?? '';
      _fearReductionRequests = List<String>.from(
        progress['fearReductionRequests'] ?? [],
      );
      _inMyOwnWordsController.text = progress['inMyOwnWords'] ?? '';
    });
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
        fullName: profile.username,
        dueDate: _dueDate,
        supportPersonName: _supportPersonNameController.text.trim().isEmpty
            ? null
            : _supportPersonNameController.text.trim(),
        supportPersonRelationship:
            _supportPersonRelationshipController.text.trim().isEmpty
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
        augmentationPreference:
            _membraneSweepingPreference, // membrane sweep is now part of augmentation
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
        delayedNewbornProcedures:
            _babyStaysWithParent, // babyStaysWithParent -> delayedNewbornProcedures
        vitaminK: _vitaminK,
        // eyeOintment removed
        hepBVaccine: _hepBVaccine,
        placentaPreference: _cordBloodBanking == true
            ? 'Save placenta'
            : null, // cordBloodBanking -> placentaPreference
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
        postpartumPainControlPlan:
            _postpartumPainManagementController.text.trim().isEmpty
            ? null
            : _postpartumPainManagementController.text.trim(),
        cesareanDrapePreference: _drapePreference,
        supportPersonInOR: _partnerInOR,
        // photosAllowedInOR removed
        immediateSkinToSkinInOR: _babyOnChestImmediately,
        // delayNewbornCareUntilHolding removed
        // anesthesiaPreference removed
        // surgicalClosurePreference removed
        culturalReligiousRituals:
            _religiousConsiderationsController.text.trim().isEmpty
            ? null
            : _religiousConsiderationsController.text.trim(),
        // culturalConsiderations removed (now part of culturalReligiousRituals)
        accessibilityNeeds: _accessibilityNeedsController.text.trim().isEmpty
            ? null
            : _accessibilityNeedsController.text.trim(),
        pastBirthTraumaOrComplications:
            _traumaHistoryController.text.trim().isEmpty
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
        mentalHealthScreeningPreference:
            birthPlan.mentalHealthScreeningPreference,
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
        pastBirthTraumaOrComplications:
            birthPlan.pastBirthTraumaOrComplications,
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

      // Track birth plan completion
      try {
        final analytics = AnalyticsService();
        await analytics.logBirthPlanCompleted(
          completionTime: DateTime.now().millisecondsSinceEpoch,
          sectionsCompleted: 10, // Approximate number of sections
          userProfile: profile,
        );
      } catch (e) {
        print('Error tracking birth plan completion: $e');
      }

      setState(() => _isLoading = false);

      if (mounted) {
        // Show qualitative survey dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => QualitativeSurveyDialog(
            feature: 'birth-plan-generator',
            questions: [
              'My birth plan reflects what matters most to me.',
              'I feel prepared to discuss my birth preferences.',
              'Creating this birth plan felt manageable.',
            ],
            title: 'Birth Plan Feedback',
            sourceId: docRef.id,
            onCompleted: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BirthPlanDisplayScreen(
                    birthPlan: updatedPlan.copyWith(id: docRef.id),
                  ),
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
        'description':
            'Ask if you qualify for intermittent monitoring during unmedicated birth',
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
      {
        'title': 'Schedule your hospital tour',
        'description': 'Tour the labor and delivery unit',
        'category': 'Medical Preparation',
      },
      {
        'title': 'Complete pre-registration for your hospital',
        'description': 'Fill out hospital pre-registration forms',
        'category': 'Medical Preparation',
      },
      {
        'title': 'Confirm pediatrician selection',
        'description': 'Choose and confirm pediatrician for baby',
        'category': 'Medical Preparation',
      },
    ]);

    // Labor Comfort Prep To-Dos
    if (plan.painManagementPreference != null ||
        plan.lightingPreference != null ||
        plan.noisePreference != null) {
      todos.addAll([
        {
          'title': 'Pack labor comfort items',
          'description': 'Playlist, dim lights, robe, heating pad',
          'category': 'Labor Comfort Prep',
        },
        {
          'title': 'Download your birth playlist',
          'description': 'Create and download music for labor',
          'category': 'Labor Comfort Prep',
        },
        {
          'title': 'Buy snacks + electrolyte drinks for labor',
          'description': 'Stock up on labor snacks',
          'category': 'Labor Comfort Prep',
        },
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
    if (plan.placentaPreference != null &&
        plan.placentaPreference!.contains('Save')) {
      todos.add({
        'title': 'Complete paperwork for cord blood banking',
        'description': 'Fill out cord blood banking forms',
        'category': 'Paperwork & Permissions',
      });
    }
    todos.addAll([
      {
        'title': 'Add hospital to insurance notifications',
        'description': 'Notify insurance of hospital choice',
        'category': 'Paperwork & Permissions',
      },
      {
        'title': 'Fill out breast pump order forms',
        'description': 'Order breast pump through insurance',
        'category': 'Paperwork & Permissions',
      },
      {
        'title': 'Print 2 copies of the birth plan',
        'description': 'Print birth plan for hospital bag',
        'category': 'Paperwork & Permissions',
      },
      {
        'title': 'Arrange FMLA / maternity leave paperwork',
        'description': 'Complete leave paperwork',
        'category': 'Paperwork & Permissions',
      },
      {
        'title': 'Create a visitor list + boundaries',
        'description': 'Prepare visitor guidelines for nurses',
        'category': 'Paperwork & Permissions',
      },
    ]);

    // Baby Care To-Dos
    if (plan.feedingPreference == 'Breastfeeding' ||
        plan.feedingPreference == 'Combo feeding') {
      todos.addAll([
        {
          'title': 'Purchase breastfeeding supplies',
          'description': 'Nipple cream, pump parts, bottles as backup',
          'category': 'Baby Care',
        },
        {
          'title': 'Confirm hospital has a lactation consultant',
          'description': 'Verify lactation support availability',
          'category': 'Baby Care',
        },
      ]);
    }
    if (plan.feedingPreference == 'Formula feeding' ||
        plan.feedingPreference == 'Combo feeding') {
      todos.add({
        'title': 'Order formula samples',
        'description':
            'Get formula samples if planning mixed or formula feeding',
        'category': 'Baby Care',
      });
    }
    todos.addAll([
      {
        'title': 'Buy newborn onesies, swaddles, diapers',
        'description': 'Stock up on newborn essentials',
        'category': 'Baby Care',
      },
      {
        'title': 'Install the car seat and get it inspected',
        'description': 'Install and verify car seat installation',
        'category': 'Baby Care',
      },
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
      {
        'title': 'Arrange child or pet care for day of labor',
        'description': 'Plan childcare/pet care',
        'category': 'Logistical',
      },
      {
        'title': 'Map fastest route to hospital',
        'description': 'Plan routes at various times of day',
        'category': 'Logistical',
      },
      {
        'title': 'Add doula/midwife/pediatrician contacts',
        'description': 'Save important contacts in phone',
        'category': 'Logistical',
      },
    ]);

    // Mental & Emotional Support To-Dos
    if (plan.traumaInformedCare ||
        plan.pastBirthTraumaOrComplications != null) {
      todos.addAll([
        {
          'title': 'Identify grounding techniques',
          'description': 'Practice techniques for medical exams',
          'category': 'Mental & Emotional Support',
        },
        {
          'title': 'Share trauma-informed preferences with OB team',
          'description': 'Communicate needs to care team',
          'category': 'Mental & Emotional Support',
        },
        {
          'title': 'Create a "How to Support Me" card for partner',
          'description': 'Prepare support instructions',
          'category': 'Mental & Emotional Support',
        },
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
      {
        'title': 'Prepare a postpartum recovery basket',
        'description': 'Pads, pain spray, peri bottle',
        'category': 'Home Preparation',
      },
      {
        'title': 'Set up baby sleep space',
        'description': 'Prepare baby\'s sleeping area',
        'category': 'Home Preparation',
      },
      {
        'title': 'Wash baby clothes + sheets',
        'description': 'Prepare baby laundry',
        'category': 'Home Preparation',
      },
      {
        'title': 'Stock freezer meals',
        'description': 'Prepare meals for postpartum',
        'category': 'Home Preparation',
      },
      {
        'title': 'Set aside comfortable postpartum clothing',
        'description': 'Prepare recovery wardrobe',
        'category': 'Home Preparation',
      },
      {
        'title': 'Prepare a feeding station',
        'description': 'Burp cloths, water bottle, snacks',
        'category': 'Home Preparation',
      },
    ]);

    // Time-Specific To-Dos
    final weeksPregnant = _calculateWeeksPregnant(plan.dueDate);
    if (weeksPregnant >= 30 && weeksPregnant < 35) {
      todos.addAll([
        {
          'title': 'Hospital tour',
          'description': 'Tour labor and delivery unit',
          'category': 'Time-Specific (30-34 weeks)',
        },
        {
          'title': 'Birth class',
          'description': 'Attend childbirth education class',
          'category': 'Time-Specific (30-34 weeks)',
        },
        {
          'title': 'Pediatrician selection',
          'description': 'Choose pediatrician',
          'category': 'Time-Specific (30-34 weeks)',
        },
      ]);
    } else if (weeksPregnant >= 35 && weeksPregnant < 38) {
      todos.addAll([
        {
          'title': 'Pack hospital bag',
          'description': 'Prepare hospital bag',
          'category': 'Time-Specific (35-37 weeks)',
        },
        {
          'title': 'Install car seat',
          'description': 'Install and verify car seat',
          'category': 'Time-Specific (35-37 weeks)',
        },
        {
          'title': 'Finalize birth plan',
          'description': 'Review and finalize birth plan',
          'category': 'Time-Specific (35-37 weeks)',
        },
      ]);
    } else if (weeksPregnant >= 38) {
      todos.addAll([
        {
          'title': 'Prepare home',
          'description': 'Final home preparations',
          'category': 'Time-Specific (38-40 weeks)',
        },
        {
          'title': 'Reduce schedule to lower stress',
          'description': 'Simplify commitments',
          'category': 'Time-Specific (38-40 weeks)',
        },
        {
          'title': 'Keep hospital bag by door',
          'description': 'Ready to go at a moment\'s notice',
          'category': 'Time-Specific (38-40 weeks)',
        },
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

  Map<String, dynamic> _getProgressData() {
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

      // Save as incomplete birth plan draft (update existing or create new)
      if (widget.incompletePlanId != null) {
        await FirebaseFirestore.instance
            .collection('birth_plans')
            .doc(widget.incompletePlanId)
            .update({
              'progressData': progressData,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        await FirebaseFirestore.instance.collection('birth_plans').add({
          'userId': userId,
          'status': 'incomplete',
          'progressData': progressData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error saving progress: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureSessionScope(
      feature: 'birth-plan-generator',
      entrySource: 'comprehensive_birth_plan',
      child: PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          await _saveProgress();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundWarm, // Matching NewUI background
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chevron_left, size: 20, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Birth Plans',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'My Birth Preferences',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      letterSpacing: -0.01 * 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your birth, your choices — one step at a time',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildAffirmingIntroCard(),
                  const SizedBox(height: 24),
                  _buildStepChipsRow(),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildCurrentStepBody(),
                  ),
                  const SizedBox(height: 24),
                  if (_currentStep < _stepCount - 1) _buildMidStepNavigation(),
                  if (_currentStep == _stepCount - 1) ...[
                    _buildCompletionCard(),
                    const SizedBox(height: 16),
                    _buildFinalActionsRow(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  static const List<({String title, IconData icon})> _stepMeta = [
    (title: 'Your Support Team', icon: Icons.groups_outlined),
    (title: 'Your Birth Space', icon: Icons.home_outlined),
    (title: 'Comfort Options', icon: Icons.favorite_outline),
    (title: 'After Baby Arrives', icon: Icons.auto_awesome_outlined),
    (title: 'If Plans Change', icon: Icons.warning_amber_rounded),
  ];

  Widget _buildAffirmingIntroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5EEE0),
            Color(0xFFFAF8F4),
            Color(0xFFEBE0D6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E0F0).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF663399).withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4A574).withOpacity(0.05),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5EEE0), Color(0xFFEBE0D6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Color(0xFFD4A574),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You know what\'s right for you',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'There\'s no right or wrong way to give birth. This plan helps you explore options and share what feels right with your care team. You can change your mind anytime.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          height: 1.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepChipsRow() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _stepCount,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final meta = _stepMeta[index];
          final isActive = _currentStep == index;
          final isComplete = _currentStep > index;
          return GestureDetector(
            onTap: () => setState(() => _currentStep = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF663399), Color(0xFF8855BB)],
                      )
                    : isComplete
                        ? const LinearGradient(
                            colors: [Color(0xFFD4A574), Color(0xFFE0B589)],
                          )
                        : null,
                color: (!isActive && !isComplete) ? AppTheme.surfaceCard : null,
                borderRadius: BorderRadius.circular(18),
                border: (!isActive && !isComplete)
                    ? Border.all(color: const Color(0xFFE8E0F0).withOpacity(0.5))
                    : null,
                boxShadow: [
                  if (isActive || isComplete)
                    BoxShadow(
                      color: (isActive
                              ? const Color(0xFF663399)
                              : const Color(0xFFD4A574))
                          .withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    meta.icon,
                    size: 18,
                    color: (isActive || isComplete)
                        ? AppTheme.brandWhite
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${index + 1}. ${meta.title}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: (isActive || isComplete)
                          ? AppTheme.brandWhite
                          : AppTheme.textMuted,
                    ),
                  ),
                  if (isComplete) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check, size: 16, color: AppTheme.brandWhite),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStepBody() {
    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection1(),
            const SizedBox(height: 12),
            _whyMattersTile('support', BirthPlanWhyCopy.support),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection2(),
            const SizedBox(height: 12),
            _whyMattersTile('environment', BirthPlanWhyCopy.environment),
          ],
        );
      case 2:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection3(),
            const SizedBox(height: 16),
            _buildSection4(),
            const SizedBox(height: 12),
            _whyMattersTile('comfort', BirthPlanWhyCopy.comfort),
          ],
        );
      case 3:
        return Column(
          key: const ValueKey(3),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection5(),
            const SizedBox(height: 16),
            _buildSection6(),
            const SizedBox(height: 16),
            _buildSection7(),
            const SizedBox(height: 12),
            _whyMattersTile('after', BirthPlanWhyCopy.afterBaby),
          ],
        );
      case 4:
        return Column(
          key: const ValueKey(4),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection8(),
            const SizedBox(height: 16),
            _buildSection9(),
            const SizedBox(height: 16),
            _buildSection10(),
            const SizedBox(height: 12),
            _whyMattersTile('change', BirthPlanWhyCopy.ifPlansChange),
          ],
        );
      default:
        return const SizedBox.shrink(key: ValueKey(-1));
    }
  }

  Widget _whyMattersTile(String id, String body) {
    final expanded = _whyExpanded[id] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _whyExpanded[id] = !expanded),
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFAF7F3),
                    Color(0xFFF5F0EB),
                    Color(0xFFF0EAD8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8DFC8).withOpacity(0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Why this matters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFFD4A574),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E0F0).withOpacity(0.4)),
            ),
            child: Text(
              body,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                height: 1.5,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Short labels on controls; full plain-language text lives in the collapsible.
  Widget _jargonExpandable(String id, String explanation) {
    final open = _jargonExpanded[id] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _jargonExpanded[id] = !open),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: const Color(0xFFD4A574),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'What does this mean?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Text(
              explanation,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w300,
                color: AppTheme.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMidStepNavigation() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: BorderSide(color: const Color(0xFFE8E0F0).withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left, size: 18),
                  SizedBox(width: 4),
                  Text('Previous'),
                ],
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep++),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF663399),
              foregroundColor: AppTheme.brandWhite,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next step'),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5EEE0),
            Color(0xFFFAF8F4),
            Color(0xFFEBE0D6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E0F0).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF663399).withOpacity(0.1),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You\'re done! 🎉',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Save plan below to finish and store your preferences. You can open your plan from the list anytime.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              height: 1.5,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_currentStep > 0)
          OutlinedButton(
            onPressed: () => setState(() => _currentStep--),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              side: BorderSide(
                color: const Color(0xFFE8E0F0).withOpacity(0.5),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chevron_left, size: 18),
                SizedBox(width: 4),
                Text('Previous'),
              ],
            ),
          ),
        if (_currentStep > 0) const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _generateBirthPlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF663399),
            foregroundColor: AppTheme.brandWhite,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.brandWhite,
                  ),
                )
              : const Text('Save plan'),
        ),
      ],
    );
  }

  Widget _buildSection1() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who do you want with you?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the people who make you feel safe and supported.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(
                    _dueDate != null
                        ? DateFormat('MMMM d, yyyy').format(_dueDate!)
                        : 'Tap to select',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          _dueDate ??
                          DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _dueDate = date);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _supportPersonNameController,
                  decoration: const InputDecoration(
                    labelText: 'Birth partner(s)',
                    hintText: 'Partner, family member, friend…',
                    prefixIcon: Icon(Icons.people),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _supportPersonRelationshipController,
                  decoration: const InputDecoration(
                    labelText: 'How they’re connected to you',
                    hintText: 'e.g. partner, parent, friend',
                    prefixIcon: Icon(Icons.family_restroom),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactInfoController,
                  decoration: const InputDecoration(
                    labelText: 'Best phone number (for urgent questions)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                _buildListInput(
                  'Allergies (things you react to)',
                  _allergyController,
                  _allergies,
                  (item) {
                    setState(() => _allergies.add(item));
                    _allergyController.clear();
                  },
                  (index) {
                    setState(() => _allergies.removeAt(index));
                  },
                ),
                const SizedBox(height: 16),
                _buildListInput(
                  'Ongoing health conditions',
                  _medicalConditionController,
                  _medicalConditions,
                  (item) {
                    setState(() => _medicalConditions.add(item));
                    _medicalConditionController.clear();
                  },
                  (index) {
                    setState(() => _medicalConditions.removeAt(index));
                  },
                ),
                const SizedBox(height: 16),
                _buildListInput(
                  'Pregnancy Complications',
                  _complicationController,
                  _pregnancyComplications,
                  (item) {
                    setState(() => _pregnancyComplications.add(item));
                    _complicationController.clear();
                  },
                  (index) {
                    setState(() => _pregnancyComplications.removeAt(index));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection2() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What helps you feel calm?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the settings that help you relax (you can pick more than one).',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMultiSelectChips('Your birth space', [
                  'Quiet room',
                  'Music',
                  'Dim lighting',
                  'Freedom to move around',
                  'Minimal interruptions',
                ], _environmentPreferences),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Photos during labor or birth'),
                  value: _photographyAllowed ?? false,
                  onChanged: (v) => setState(() => _photographyAllowed = v),
                ),
                SwitchListTile(
                  title: const Text('Video during labor or birth'),
                  value: _videographyAllowed ?? false,
                  onChanged: (v) => setState(() => _videographyAllowed = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _preferredLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Language you want care in',
                  ),
                  items: ['English', 'Spanish', 'Other']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _preferredLanguage = v),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Ask before touch or exams'),
                  value: _traumaInformedCare,
                  onChanged: (v) => setState(() => _traumaInformedCare = v),
                ),
                _jargonExpandable(
                  'trauma_informed',
                  'Trauma-informed care means your team checks in before touch or exams, '
                  'so you feel more in control—especially if past experiences make care harder.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection3() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How would you like to manage discomfort?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'There are many ways to stay comfortable. Choose what you’re considering—you can change your mind later.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMultiSelectChips('Positions that sound good for labor', [
                  'Walking',
                  'Birthing ball',
                  'Tub',
                  'Bed',
                  'Squatting',
                  'Hands and knees',
                  'Side-lying',
                ], _preferredLaborPositions),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Freedom to move and change positions'),
                  subtitle: const Text('Instead of staying in bed unless needed'),
                  value: _movementFreedom,
                  onChanged: (v) => setState(() => _movementFreedom = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _monitoringPreference,
                  decoration: const InputDecoration(
                    labelText: 'Fetal monitoring',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Intermittent',
                      child: Text(
                        'At intervals (more freedom to move)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Continuous',
                      child: Text(
                        'Continuous belts on your belly',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Wireless if available',
                      child: Text(
                        'Wireless monitors if available',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _monitoringPreference = v),
                ),
                _jargonExpandable(
                  'monitoring',
                  'Your care team may listen to baby’s heart rate during labor. '
                  'Intermittent means checks at intervals (often more freedom to move). '
                  'Continuous means belts on your belly for ongoing monitoring. '
                  'Wireless monitors may be available if your hospital offers them.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _painManagementPreference,
                  decoration: const InputDecoration(
                    labelText: 'Pain relief',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Unmedicated',
                      child: Text(
                        'No pain medicine — comfort tools only',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Epidural',
                      child: Text(
                        'Epidural — small tube in your back',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Nitrous oxide',
                      child: Text(
                        'Laughing gas (mask)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'IV pain meds',
                      child: Text(
                        'Pain medicine through an IV',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Comfort measures only',
                      child: Text(
                        'Massage, water, breathing — open to discussion',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _painManagementPreference = v),
                ),
                _jargonExpandable(
                  'pain',
                  'There are many ways to stay comfortable in labor. '
                  'Some people use medicine (epidural, IV meds, or nitrous). '
                  'Others prefer movement, water, massage, or breathing. '
                  'You can change your mind later—this is what you’re open to discussing.',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Doula or birth coach'),
                  subtitle: const Text('A trained labor support person'),
                  value: _useDoula,
                  onChanged: (v) => setState(() => _useDoula = v),
                ),
                SwitchListTile(
                  title: const Text('Laboring in water (if your place offers it)'),
                  value: _waterLaborAvailable ?? false,
                  onChanged: (v) => setState(() => _waterLaborAvailable = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _membraneSweepingPreference,
                  decoration: const InputDecoration(
                    labelText: 'Membrane sweep',
                  ),
                  items:
                      ['Yes, if offered', 'No', 'Only if medically indicated']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) =>
                      setState(() => _membraneSweepingPreference = v),
                ),
                _jargonExpandable(
                  'membrane',
                  'A membrane sweep is when a care provider gently sweeps a finger at the cervix '
                  '(opening of the womb) to encourage labor. It is optional—only if you and your provider agree it’s right for you.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _inductionPreference,
                  decoration: const InputDecoration(
                    labelText: 'If labor needs help starting',
                  ),
                  items:
                      [
                            'Natural methods first',
                            'Open to medical induction',
                            'Prefer to avoid',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _inductionPreference = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'How you like updates and decisions explained',
                    hintText: 'e.g. explain options first, keep me calm',
                  ),
                  onChanged: (v) => setState(() => _communicationStyle = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection4() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pushing & birth',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your team can suggest options; share what feels right for your body.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMultiSelectChips('Positions for pushing', [
                  'Hands and knees',
                  'Side-lying',
                  'Squatting',
                  'Semi-reclined',
                  'Whatever feels right',
                ], _preferredPushingPositions),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _pushingStyle,
                  decoration: const InputDecoration(
                    labelText: 'Guidance while pushing',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Guided',
                      child: Text('Staff guide when to push'),
                    ),
                    DropdownMenuItem(
                      value: 'Spontaneous',
                      child: Text('Push when your body tells you'),
                    ),
                    DropdownMenuItem(
                      value: 'Either',
                      child: Text('Either is fine'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _pushingStyle = v),
                ),
                SwitchListTile(
                  title: const Text('Mirror to see baby crown'),
                  value: _mirrorDuringPushing ?? false,
                  onChanged: (v) => setState(() => _mirrorDuringPushing = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _episiotomyPreference,
                  decoration: const InputDecoration(
                    labelText: 'Episiotomy',
                  ),
                  items:
                      [
                            'Avoid unless absolutely necessary',
                            'Open to if needed',
                            'No preference',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _episiotomyPreference = v),
                ),
                _jargonExpandable(
                  'episiotomy',
                  'An episiotomy is a small cut at the vaginal opening, usually only if there is a medical reason. '
                  'Many people prefer to avoid it unless truly necessary—your provider can explain in the moment.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Support for the vaginal area while stretching',
                    hintText: 'e.g. warm cloths, hands-on support',
                  ),
                  onChanged: (v) => setState(() => _tearingPreference = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _whoCatchesBaby,
                  decoration: const InputDecoration(
                    labelText: 'Who you’d like to receive baby',
                  ),
                  items: ['Partner', 'Doctor', 'Midwife', 'Myself']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _whoCatchesBaby = v),
                ),
                SwitchListTile(
                  title: const Text(
                    'Wait to push until you feel the urge (with epidural)',
                  ),
                  value: _delayedPushingWithEpidural ?? false,
                  onChanged: (v) =>
                      setState(() => _delayedPushingWithEpidural = v),
                ),
                _jargonExpandable(
                  'laboring_down',
                  'With an epidural, some people prefer to wait until they feel the urge to push, '
                  'sometimes called “laboring down.” Ask your team what is safe for you and your baby.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection5() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'First moments with your baby',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'These choices are about the first hour after birth.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _delayedCordClampingPreference,
                  decoration: const InputDecoration(
                    labelText: 'Delayed cord clamping',
                  ),
                  items:
                      [
                            '1-3 minutes',
                            '3-5 minutes',
                            'Until cord stops pulsing',
                            'No preference',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) =>
                      setState(() => _delayedCordClampingPreference = v),
                ),
                _jargonExpandable(
                  'cord_clamp',
                  'Waiting before clamping the cord lets more blood flow from the placenta to your baby. '
                  'Your team can advise on timing based on you and baby’s condition.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _whoCutsCord,
                  decoration: const InputDecoration(
                    labelText: 'Who cuts the cord',
                  ),
                  items: ['Partner', 'Myself', 'Doctor', 'No preference']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _whoCutsCord = v),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Hold baby skin-to-skin right away'),
                  value: _immediateSkinToSkin,
                  onChanged: (v) => setState(() => _immediateSkinToSkin = v),
                ),
                SwitchListTile(
                  title: const Text('Keep baby with you for checkups when possible'),
                  subtitle: const Text('Instead of on a warmer across the room'),
                  value: _babyStaysWithParent,
                  onChanged: (v) => setState(() => _babyStaysWithParent = v),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Vitamin K injection (helps blood clot normally)',
                  ),
                  value: _vitaminK ?? true,
                  onChanged: (v) => setState(() => _vitaminK = v),
                ),
                SwitchListTile(
                  title: const Text(
                    'Antibiotic eye ointment (helps prevent certain eye infections)',
                  ),
                  value: _eyeOintment ?? true,
                  onChanged: (v) => setState(() => _eyeOintment = v),
                ),
                SwitchListTile(
                  title: const Text(
                    'Hepatitis B vaccine (liver infection prevention)',
                  ),
                  value: _hepBVaccine ?? true,
                  onChanged: (v) => setState(() => _hepBVaccine = v),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Save cord blood for banking'),
                  subtitle: const Text('Optional—often arranged ahead with a company'),
                  value: _cordBloodBanking ?? false,
                  onChanged: (v) => setState(() => _cordBloodBanking = v),
                ),
                if (_cordBloodBanking == true) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cordBloodCompanyController,
                    decoration: const InputDecoration(
                      labelText: 'Cord blood company name',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection6() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Feeding your baby',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _feedingPreference,
                  decoration: const InputDecoration(
                    labelText: 'How you plan to feed your baby',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Breastfeeding',
                      child: Text('Nursing (breastfeeding)'),
                    ),
                    DropdownMenuItem(
                      value: 'Formula feeding',
                      child: Text('Formula feeding'),
                    ),
                    DropdownMenuItem(
                      value: 'Combo feeding',
                      child: Text('Both nursing and formula'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _feedingPreference = v),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Visit from a lactation specialist'),
                  value: _lactationConsultantRequested,
                  onChanged: (v) =>
                      setState(() => _lactationConsultantRequested = v),
                ),
                SwitchListTile(
                  title: const Text(
                    'Wait on pacifiers until feeding is going well',
                  ),
                  subtitle: const Text('If nursing—optional preference'),
                  value: _noPacifierUntilBreastfeeding ?? false,
                  onChanged: (v) =>
                      setState(() => _noPacifierUntilBreastfeeding = v),
                ),
                SwitchListTile(
                  title: const Text(
                    'Okay with donor breast milk if medically needed',
                  ),
                  value: _consentForDonorMilk ?? false,
                  onChanged: (v) => setState(() => _consentForDonorMilk = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection7() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Recovery after birth',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Baby stays in your room (rooming-in)'),
                  subtitle: const Text('Instead of the nursery, when possible'),
                  value: _roomingIn ?? true,
                  onChanged: (v) => setState(() => _roomingIn = v),
                ),
                SwitchListTile(
                  title: const Text('Extra emotional or mental health support'),
                  value: _mentalHealthSupport ?? false,
                  onChanged: (v) => setState(() => _mentalHealthSupport = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _visitorPreferenceController,
                  decoration: const InputDecoration(
                    labelText: 'Visitors',
                    hintText: 'e.g. partner only for the first day',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dietaryPreferencesController,
                  decoration: const InputDecoration(
                    labelText: 'Food needs or restrictions',
                    hintText: 'e.g. vegetarian, allergies',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _postpartumPainManagementController,
                  decoration: const InputDecoration(
                    labelText: 'Comfort for soreness after birth',
                    hintText: 'e.g. ibuprofen first; ask before stronger meds',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection8() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If a cesarean birth is needed',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sometimes called a belly birth. Worth sharing even if you plan a vaginal birth.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _drapePreference,
                  decoration: const InputDecoration(
                    labelText: 'Surgical drape / screen',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Clear drape',
                      child: Text(
                        'Clear screen — see baby lifted up',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Standard drape',
                      child: Text('Standard drape'),
                    ),
                    DropdownMenuItem(
                      value: 'No preference',
                      child: Text('No preference'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _drapePreference = v),
                ),
                _jargonExpandable(
                  'drape',
                  'A drape separates the surgical field from your view. Some hospitals offer a clear screen '
                  'so you can see baby being lifted up. Ask your team what they offer.',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Support person in the operating room'),
                  value: _partnerInOR ?? true,
                  onChanged: (v) => setState(() => _partnerInOR = v),
                ),
                SwitchListTile(
                  title: const Text('Photos in the operating room'),
                  value: _photosAllowedInOR ?? true,
                  onChanged: (v) => setState(() => _photosAllowedInOR = v),
                ),
                SwitchListTile(
                  title: const Text('Baby on your chest as soon as safely possible'),
                  value: _babyOnChestImmediately ?? true,
                  onChanged: (v) => setState(() => _babyOnChestImmediately = v),
                ),
                _jargonExpandable(
                  'gentle_cesarean',
                  'A “gentle” or family-centered cesarean often means placing baby on your chest as soon as it is safe, '
                  'sometimes with a clear drape so you can see baby lifted up. Your hospital may use different terms.',
                ),
                SwitchListTile(
                  title: Text(
                    'Delay routine newborn tasks until you’re holding baby',
                    maxLines: 3,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  value: _delayNewbornCareUntilHolding ?? false,
                  onChanged: (v) =>
                      setState(() => _delayNewbornCareUntilHolding = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _anesthesiaPreference,
                  decoration: const InputDecoration(
                    labelText: 'Anesthesia for surgery',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Spinal',
                      child: Text(
                        'Spinal — numbs from waist down',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Epidural',
                      child: Text(
                        'Epidural — tube in back',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'General (if emergency)',
                      child: Text(
                        'General (only if needed)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'No preference',
                      child: Text('No preference'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _anesthesiaPreference = v),
                ),
                _jargonExpandable(
                  'anesthesia',
                  'Most cesareans use a spinal or epidural so you are awake but numb from the waist down. '
                  'General anesthesia (asleep) is reserved for emergencies or when your team says it is safest.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _surgicalClosurePreference,
                  decoration: const InputDecoration(
                    labelText: 'How the incision is closed',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Staples',
                      child: Text('Metal staples'),
                    ),
                    DropdownMenuItem(
                      value: 'Sutures',
                      child: Text('Stitches (sutures)'),
                    ),
                    DropdownMenuItem(
                      value: 'Dissolvable',
                      child: Text('Dissolvable stitches'),
                    ),
                    DropdownMenuItem(
                      value: 'No preference',
                      child: Text('No preference'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _surgicalClosurePreference = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection9() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If something unexpected happens',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Most births go as planned, but sharing this now can help your team support you.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _religiousConsiderationsController,
                  decoration: const InputDecoration(
                    labelText: 'Faith or spiritual practices that matter to you',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _culturalConsiderationsController,
                  decoration: const InputDecoration(
                    labelText: 'Cultural traditions we should know about',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accessibilityNeedsController,
                  decoration: const InputDecoration(
                    labelText: 'Accessibility or mobility needs',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _traumaHistoryController,
                  decoration: const InputDecoration(
                    labelText: 'Past trauma (only if you want to share)',
                  ),
                  maxLines: 2,
                ),
                _jargonExpandable(
                  'trauma_history',
                  'Sharing past trauma is optional. If you do, it can help staff offer more sensitive care. '
                  'Share only what you choose.',
                ),
                const SizedBox(height: 16),
                _buildListInput(
                  'Things that make anxiety worse',
                  _anxietyTriggerController,
                  _anxietyTriggers,
                  (item) {
                    setState(() => _anxietyTriggers.add(item));
                    _anxietyTriggerController.clear();
                  },
                  (index) {
                    setState(() => _anxietyTriggers.removeAt(index));
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Ask me before procedures or exams'),
                  value: _consentBasedCare,
                  onChanged: (v) => setState(() => _consentBasedCare = v),
                ),
                _jargonExpandable(
                  'consent_care',
                  'Extra check-ins so you can consent before procedures or exams along the way—not just once at admission.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _preferredBadNewsDelivery,
                  decoration: const InputDecoration(
                    labelText: 'How you prefer hard news to be shared',
                  ),
                  items:
                      [
                            'Private conversation',
                            'With partner present',
                            'Written first, then discussion',
                            'Direct and clear',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) =>
                      setState(() => _preferredBadNewsDelivery = v),
                ),
                const SizedBox(height: 16),
                _buildListInput(
                  'What helps you feel calmer under stress',
                  _fearReductionController,
                  _fearReductionRequests,
                  (item) {
                    setState(() => _fearReductionRequests.add(item));
                    _fearReductionController.clear();
                  },
                  (index) {
                    setState(() => _fearReductionRequests.removeAt(index));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection10() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anything else?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Optional—your own words for your care team.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _inMyOwnWordsController,
                  decoration: const InputDecoration(
                    labelText: 'What you want your team to know',
                    hintText:
                        'Anything else you\'d like your care team to know…',
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildMultiSelectChips(
    String label,
    List<String> options,
    List<String> selected,
  ) {
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
      supportPersonRelationship:
          supportPersonRelationship ?? this.supportPersonRelationship,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      pregnancyComplications:
          pregnancyComplications ?? this.pregnancyComplications,
      // environmentPreferences removed
      photographyAllowed: photographyAllowed ?? this.photographyAllowed,
      videographyAllowed: videographyAllowed ?? this.videographyAllowed,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      traumaInformedCare: traumaInformedCare ?? this.traumaInformedCare,
      preferredLaborPositions:
          preferredLaborPositions ?? this.preferredLaborPositions,
      movementFreedom: movementFreedom ?? this.movementFreedom,
      monitoringPreference: monitoringPreference ?? this.monitoringPreference,
      painManagementPreference:
          painManagementPreference ?? this.painManagementPreference,
      useDoula: useDoula ?? this.useDoula,
      waterLaborAvailable: waterLaborAvailable ?? this.waterLaborAvailable,
      augmentationPreference:
          augmentationPreference ?? this.augmentationPreference,
      inductionMethodsPreference:
          inductionMethodsPreference ?? this.inductionMethodsPreference,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      preferredPushingPositions:
          preferredPushingPositions ?? this.preferredPushingPositions,
      coachingStyle: coachingStyle ?? this.coachingStyle,
      mirrorDuringPushing: mirrorDuringPushing ?? this.mirrorDuringPushing,
      episiotomyPreference: episiotomyPreference ?? this.episiotomyPreference,
      // tearingPreference removed
      whoCatchesBaby: whoCatchesBaby ?? this.whoCatchesBaby,
      delayedPushingWithEpidural:
          delayedPushingWithEpidural ?? this.delayedPushingWithEpidural,
      delayedCordClampingPreference:
          delayedCordClampingPreference ?? this.delayedCordClampingPreference,
      whoCutsCord: whoCutsCord ?? this.whoCutsCord,
      immediateSkinToSkin: immediateSkinToSkin ?? this.immediateSkinToSkin,
      delayedNewbornProcedures:
          delayedNewbornProcedures ?? this.delayedNewbornProcedures,
      vitaminK: vitaminK ?? this.vitaminK,
      // eyeOintment removed
      hepBVaccine: hepBVaccine ?? this.hepBVaccine,
      placentaPreference: placentaPreference ?? this.placentaPreference,
      // cordBloodCompany removed
      feedingPreference: feedingPreference ?? this.feedingPreference,
      lactationConsultantRequested:
          lactationConsultantRequested ?? this.lactationConsultantRequested,
      noPacifierUntilBreastfeeding:
          noPacifierUntilBreastfeeding ?? this.noPacifierUntilBreastfeeding,
      consentForDonorMilk: consentForDonorMilk ?? this.consentForDonorMilk,
      roomingIn: roomingIn ?? this.roomingIn,
      mentalHealthScreeningPreference:
          mentalHealthScreeningPreference ??
          this.mentalHealthScreeningPreference,
      visitorsAfterBirth: visitorsAfterBirth ?? this.visitorsAfterBirth,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      postpartumPainControlPlan:
          postpartumPainControlPlan ?? this.postpartumPainControlPlan,
      cesareanDrapePreference:
          cesareanDrapePreference ?? this.cesareanDrapePreference,
      supportPersonInOR: supportPersonInOR ?? this.supportPersonInOR,
      // photosAllowedInOR removed
      immediateSkinToSkinInOR:
          immediateSkinToSkinInOR ?? this.immediateSkinToSkinInOR,
      // delayNewbornCareUntilHolding removed
      // anesthesiaPreference removed
      // surgicalClosurePreference removed
      culturalReligiousRituals:
          culturalReligiousRituals ?? this.culturalReligiousRituals,
      // culturalConsiderations removed
      accessibilityNeeds: accessibilityNeeds ?? this.accessibilityNeeds,
      pastBirthTraumaOrComplications:
          pastBirthTraumaOrComplications ?? this.pastBirthTraumaOrComplications,
      anxietyTriggers: anxietyTriggers ?? this.anxietyTriggers,
      consentBasedCare: consentBasedCare ?? this.consentBasedCare,
      preferredBadNewsDelivery:
          preferredBadNewsDelivery ?? this.preferredBadNewsDelivery,
      fearReductionRequests:
          fearReductionRequests ?? this.fearReductionRequests,
      inMyOwnWords: inMyOwnWords ?? this.inMyOwnWords,
      formattedPlan: formattedPlan ?? this.formattedPlan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      providerName: providerName ?? this.providerName,
    );
  }
}
