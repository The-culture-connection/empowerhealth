import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/birth_plan.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'birth_plan_display_screen.dart';
import 'birth_plan_formatter.dart';
import '../widgets/qualitative_survey_dialog.dart';
import '../widgets/drag_scroll_behavior.dart';
import '../widgets/feature_session_scope.dart';
import 'birth_plan_why_copy.dart';

class ComprehensiveBirthPlanScreen extends StatefulWidget {
  final String? incompletePlanId; // For resuming incomplete plans
  final Map<String, dynamic>? savedProgress; // Saved progress data

  /// A completed plan to edit. The form is prefilled from it and saving
  /// updates the same Firestore document (no new plan, no duplicate to-dos).
  /// The screen pops with the updated [BirthPlan].
  final BirthPlan? editingPlan;

  const ComprehensiveBirthPlanScreen({
    super.key,
    this.incompletePlanId,
    this.savedProgress,
    this.editingPlan,
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
  // Set once the plan is saved so leaving the screen doesn't also store a draft.
  bool _saved = false;

  static const String _introDismissedPrefKey = 'birth_plan_intro_dismissed';
  bool _introDismissed = false;

  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _stepChipsScrollController = ScrollController();
  final GlobalKey _stepChipsKey = GlobalKey();
  final List<GlobalKey> _stepChipKeys =
      List.generate(_stepCount, (_) => GlobalKey());

  static const int _stepCount = 5;
  int _currentStep = 0;

  bool get _isEditing => widget.editingPlan?.id != null;
  final Map<String, bool> _whyExpanded = {};
  final Map<String, bool> _jargonExpanded = {};

  // Section 1: Parent Information
  final _supportPersonNameController = TextEditingController();
  final _supportPersonRelationshipController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _communicationStyleController = TextEditingController();
  final _tearingPreferenceController = TextEditingController();
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
    _loadIntroDismissed();
    final editing = widget.editingPlan;
    if (editing != null) {
      _applyProgress(editing.progressData ?? _progressFromPlan(editing));
    } else if (widget.savedProgress != null) {
      _loadSavedProgress();
    } else {
      // Only prefill from the profile for a brand-new plan; otherwise the
      // async profile load would overwrite what the person already entered.
      _loadUserProfile();
    }
  }

  Future<void> _loadIntroDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_introDismissedPrefKey) ?? false;
      if (dismissed && mounted) setState(() => _introDismissed = true);
    } catch (_) {}
  }

  Future<void> _dismissIntro() async {
    setState(() => _introDismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introDismissedPrefKey, true);
    } catch (_) {}
  }

  /// Moves to [step], brings the top of that step into view and keeps its
  /// chip visible in the horizontally scrolling step banner.
  void _goToStep(int step) {
    if (step < 0 || step >= _stepCount) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chipsContext = _stepChipsKey.currentContext;
      if (chipsContext != null && _pageScrollController.hasClients) {
        // Align the step banner with the top of the page so the new step's
        // content starts right below it.
        final box = chipsContext.findRenderObject() as RenderBox?;
        final viewport = RenderAbstractViewport.maybeOf(box);
        if (box != null && viewport != null) {
          final target = viewport
              .getOffsetToReveal(box, 0)
              .offset
              .clamp(0.0, _pageScrollController.position.maxScrollExtent);
          // Only scroll up: if the person is already above the step (e.g. they
          // tapped a chip in the banner) the step's top is already in view.
          if (target < _pageScrollController.offset) {
            _pageScrollController.animateTo(
              target,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      } else if (_pageScrollController.hasClients) {
        _pageScrollController.jumpTo(0);
      }
      _revealCurrentStepChip();
    });
  }

  /// Centers the current step's chip in the step banner. Only the banner's
  /// horizontal scroll moves (Scrollable.ensureVisible would also scroll the
  /// page vertically).
  void _revealCurrentStepChip() {
    if (!_stepChipsScrollController.hasClients) return;
    final chipBox = _stepChipKeys[_currentStep].currentContext
        ?.findRenderObject() as RenderBox?;
    if (chipBox == null) return;
    final viewport = RenderAbstractViewport.maybeOf(chipBox);
    if (viewport == null) return;
    final position = _stepChipsScrollController.position;
    final target = viewport
        .getOffsetToReveal(chipBox, 0.5)
        .offset
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    _stepChipsScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  static const Map<String, List<String>> _dropdownOptions = {
    'preferredLanguage': ['English', 'Spanish', 'Other'],
    'monitoringPreference': [
      'Intermittent',
      'Continuous',
      'Wireless if available',
    ],
    'painManagementPreference': [
      'Unmedicated',
      'Epidural',
      'Nitrous oxide',
      'IV pain meds',
      'Comfort measures only',
    ],
    'membraneSweepingPreference': [
      'Yes, if offered',
      'No',
      'Only if medically indicated',
    ],
    'inductionPreference': [
      'Natural methods first',
      'Open to medical induction',
      'Prefer to avoid',
    ],
    'pushingStyle': ['Guided', 'Spontaneous', 'Either'],
    'episiotomyPreference': [
      'Avoid unless absolutely necessary',
      'Open to if needed',
      'No preference',
    ],
    'whoCatchesBaby': ['Partner', 'Doctor', 'Midwife', 'Myself'],
    'delayedCordClampingPreference': [
      '1-3 minutes',
      '3-5 minutes',
      'Until cord stops pulsing',
      'No preference',
    ],
    'whoCutsCord': ['Partner', 'Myself', 'Doctor', 'No preference'],
    'feedingPreference': ['Breastfeeding', 'Formula feeding', 'Combo feeding'],
    'drapePreference': ['Clear drape', 'Standard drape', 'No preference'],
    'anesthesiaPreference': [
      'Spinal',
      'Epidural',
      'General (if emergency)',
      'No preference',
    ],
    'surgicalClosurePreference': [
      'Staples',
      'Sutures',
      'Dissolvable',
      'No preference',
    ],
    'preferredBadNewsDelivery': [
      'Private conversation',
      'With partner present',
      'Written first, then discussion',
      'Direct and clear',
    ],
  };

  /// Dropdowns assert if their value isn't one of their items, so drop any
  /// stored value (e.g. from an older version of the form) that no longer is.
  String? _dropdownValue(Map<String, dynamic> progress, String key) {
    final value = progress[key];
    if (value is! String) return null;
    return (_dropdownOptions[key]?.contains(value) ?? true) ? value : null;
  }

  /// Rebuilds the form state from a saved plan that has no `progressData`
  /// snapshot (plans saved before edit support existed).
  static Map<String, dynamic> _progressFromPlan(BirthPlan plan) {
    return {
      'supportPersonName': plan.supportPersonName ?? '',
      'supportPersonRelationship': plan.supportPersonRelationship ?? '',
      'contactInfo': plan.emergencyContact ?? '',
      'dueDate': plan.dueDate?.toIso8601String(),
      'allergies': plan.allergies,
      'medicalConditions': plan.medicalConditions,
      'pregnancyComplications': plan.pregnancyComplications,
      'environmentPreferences': plan.environmentPreferences,
      'photographyAllowed': plan.photographyAllowed,
      'videographyAllowed': plan.videographyAllowed,
      'preferredLanguage': plan.preferredLanguage,
      'traumaInformedCare': plan.traumaInformedCare,
      'preferredLaborPositions': plan.preferredLaborPositions,
      'movementFreedom': plan.movementFreedom,
      'monitoringPreference': plan.monitoringPreference,
      'painManagementPreference': plan.painManagementPreference,
      'useDoula': plan.useDoula,
      'waterLaborAvailable': plan.waterLaborAvailable,
      'membraneSweepingPreference': plan.augmentationPreference,
      'inductionPreference': plan.inductionMethodsPreference,
      'communicationStyle': plan.communicationStyle,
      'preferredPushingPositions': plan.preferredPushingPositions,
      'pushingStyle': plan.coachingStyle,
      'mirrorDuringPushing': plan.mirrorDuringPushing,
      'episiotomyPreference': plan.episiotomyPreference,
      'tearingPreference': plan.perinealSupportPreference,
      'whoCatchesBaby': plan.whoCatchesBaby,
      'delayedPushingWithEpidural': plan.delayedPushingWithEpidural,
      'delayedCordClampingPreference': plan.delayedCordClampingPreference,
      'whoCutsCord': plan.whoCutsCord,
      'immediateSkinToSkin': plan.immediateSkinToSkin,
      'babyStaysWithParent': plan.delayedNewbornProcedures ?? true,
      'vitaminK': plan.vitaminK,
      'eyeOintment': plan.eyeOintment,
      'hepBVaccine': plan.hepBVaccine,
      'cordBloodBanking': plan.cordBloodBanking ??
          (plan.placentaPreference == 'Save placenta' ? true : null),
      'cordBloodCompany': plan.cordBloodCompany ?? '',
      'feedingPreference': plan.feedingPreference,
      'lactationConsultantRequested': plan.lactationConsultantRequested,
      'noPacifierUntilBreastfeeding': plan.noPacifierUntilBreastfeeding,
      'consentForDonorMilk': plan.consentForDonorMilk,
      'roomingIn': plan.roomingIn,
      'mentalHealthSupport': plan.mentalHealthScreeningPreference,
      'visitorPreference': plan.visitorsAfterBirth ?? '',
      'dietaryPreferences': plan.dietaryPreferences ?? '',
      'postpartumPainManagement': plan.postpartumPainControlPlan ?? '',
      'drapePreference': plan.cesareanDrapePreference,
      'partnerInOR': plan.supportPersonInOR,
      'photosAllowedInOR': plan.photosAllowedInOR,
      'babyOnChestImmediately': plan.immediateSkinToSkinInOR,
      'delayNewbornCareUntilHolding': plan.delayNewbornCareUntilHolding,
      'anesthesiaPreference': plan.anesthesiaPreference,
      'surgicalClosurePreference': plan.surgicalClosurePreference,
      'religiousConsiderations': plan.culturalReligiousRituals ?? '',
      'culturalConsiderations': plan.culturalConsiderations ?? '',
      'accessibilityNeeds': plan.accessibilityNeeds ?? '',
      'traumaHistory': plan.pastBirthTraumaOrComplications ?? '',
      'anxietyTriggers': plan.anxietyTriggers,
      'consentBasedCare': plan.consentBasedCare,
      'preferredBadNewsDelivery': plan.preferredBadNewsDelivery,
      'fearReductionRequests': plan.fearReductionRequests,
      'inMyOwnWords': plan.inMyOwnWords ?? '',
    };
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
    _applyProgress(widget.savedProgress!);
  }

  void _applyProgress(Map<String, dynamic> progress) {
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
      _preferredLanguage = _dropdownValue(progress, 'preferredLanguage');
      _traumaInformedCare = progress['traumaInformedCare'] ?? false;
      _preferredLaborPositions = List<String>.from(
        progress['preferredLaborPositions'] ?? [],
      );
      _movementFreedom = progress['movementFreedom'] ?? true;
      _monitoringPreference = _dropdownValue(progress, 'monitoringPreference');
      _painManagementPreference = _dropdownValue(progress, 'painManagementPreference');
      _useDoula = progress['useDoula'] ?? false;
      _waterLaborAvailable = progress['waterLaborAvailable'];
      _membraneSweepingPreference = _dropdownValue(progress, 'membraneSweepingPreference');
      _inductionPreference = _dropdownValue(progress, 'inductionPreference');
      _communicationStyle = progress['communicationStyle'];
      _communicationStyleController.text = progress['communicationStyle'] ?? '';
      _preferredPushingPositions = List<String>.from(
        progress['preferredPushingPositions'] ?? [],
      );
      _pushingStyle = _dropdownValue(progress, 'pushingStyle');
      _mirrorDuringPushing = progress['mirrorDuringPushing'];
      _episiotomyPreference = _dropdownValue(progress, 'episiotomyPreference');
      _tearingPreference = progress['tearingPreference'];
      _tearingPreferenceController.text = progress['tearingPreference'] ?? '';
      _whoCatchesBaby = _dropdownValue(progress, 'whoCatchesBaby');
      _delayedPushingWithEpidural = progress['delayedPushingWithEpidural'];
      _delayedCordClampingPreference =
          _dropdownValue(progress, 'delayedCordClampingPreference');
      _whoCutsCord = _dropdownValue(progress, 'whoCutsCord');
      _immediateSkinToSkin = progress['immediateSkinToSkin'] ?? true;
      _babyStaysWithParent = progress['babyStaysWithParent'] ?? true;
      _vitaminK = progress['vitaminK'];
      _eyeOintment = progress['eyeOintment'];
      _hepBVaccine = progress['hepBVaccine'];
      _cordBloodBanking = progress['cordBloodBanking'];
      _cordBloodCompanyController.text = progress['cordBloodCompany'] ?? '';
      _feedingPreference = _dropdownValue(progress, 'feedingPreference');
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
      _drapePreference = _dropdownValue(progress, 'drapePreference');
      _partnerInOR = progress['partnerInOR'];
      _photosAllowedInOR = progress['photosAllowedInOR'];
      _babyOnChestImmediately = progress['babyOnChestImmediately'];
      _delayNewbornCareUntilHolding = progress['delayNewbornCareUntilHolding'];
      _anesthesiaPreference = _dropdownValue(progress, 'anesthesiaPreference');
      _surgicalClosurePreference = _dropdownValue(progress, 'surgicalClosurePreference');
      _religiousConsiderationsController.text =
          progress['religiousConsiderations'] ?? '';
      _culturalConsiderationsController.text =
          progress['culturalConsiderations'] ?? '';
      _accessibilityNeedsController.text = progress['accessibilityNeeds'] ?? '';
      _traumaHistoryController.text = progress['traumaHistory'] ?? '';
      _anxietyTriggerController.text = progress['anxietyTrigger'] ?? '';
      _anxietyTriggers = List<String>.from(progress['anxietyTriggers'] ?? []);
      _consentBasedCare = progress['consentBasedCare'] ?? false;
      _preferredBadNewsDelivery = _dropdownValue(progress, 'preferredBadNewsDelivery');
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
    _communicationStyleController.dispose();
    _tearingPreferenceController.dispose();
    _pageScrollController.dispose();
    _stepChipsScrollController.dispose();
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
      final editing = widget.editingPlan;
      if (profile == null && editing == null) {
        throw Exception('User profile not found');
      }

      String? text(TextEditingController c) =>
          c.text.trim().isEmpty ? null : c.text.trim();
      String? optional(String? v) =>
          (v == null || v.trim().isEmpty) ? null : v.trim();

      // Create birth plan object. Toggle values fall back to the same
      // defaults the switches display, so the saved plan matches the screen.
      final birthPlan = BirthPlan(
        id: editing?.id,
        userId: userId,
        fullName: profile?.username ?? editing!.fullName,
        dueDate: _dueDate,
        supportPersonName: text(_supportPersonNameController),
        supportPersonRelationship: text(_supportPersonRelationshipController),
        emergencyContact: text(_contactInfoController),
        allergies: _allergies,
        medicalConditions: _medicalConditions,
        pregnancyComplications: _pregnancyComplications,
        environmentPreferences: _environmentPreferences,
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
        communicationStyle: optional(_communicationStyle),
        preferredPushingPositions: _preferredPushingPositions,
        coachingStyle: _pushingStyle, // pushingStyle renamed to coachingStyle
        mirrorDuringPushing: _mirrorDuringPushing,
        episiotomyPreference: _episiotomyPreference,
        perinealSupportPreference: optional(_tearingPreference),
        whoCatchesBaby: _whoCatchesBaby,
        delayedPushingWithEpidural: _delayedPushingWithEpidural,
        delayedCordClampingPreference: _delayedCordClampingPreference,
        whoCutsCord: _whoCutsCord,
        immediateSkinToSkin: _immediateSkinToSkin,
        delayedNewbornProcedures:
            _babyStaysWithParent, // babyStaysWithParent -> delayedNewbornProcedures
        vitaminK: _vitaminK ?? true,
        eyeOintment: _eyeOintment ?? true,
        hepBVaccine: _hepBVaccine ?? true,
        cordBloodBanking: _cordBloodBanking,
        cordBloodCompany:
            _cordBloodBanking == true ? text(_cordBloodCompanyController) : null,
        feedingPreference: _feedingPreference,
        lactationConsultantRequested: _lactationConsultantRequested,
        noPacifierUntilBreastfeeding: _noPacifierUntilBreastfeeding,
        consentForDonorMilk: _consentForDonorMilk,
        roomingIn: _roomingIn ?? true,
        mentalHealthScreeningPreference: _mentalHealthSupport,
        visitorsAfterBirth: text(_visitorPreferenceController),
        dietaryPreferences: text(_dietaryPreferencesController),
        postpartumPainControlPlan: text(_postpartumPainManagementController),
        cesareanDrapePreference: _drapePreference,
        supportPersonInOR: _partnerInOR ?? true,
        photosAllowedInOR: _photosAllowedInOR ?? true,
        immediateSkinToSkinInOR: _babyOnChestImmediately ?? true,
        delayNewbornCareUntilHolding: _delayNewbornCareUntilHolding,
        anesthesiaPreference: _anesthesiaPreference,
        surgicalClosurePreference: _surgicalClosurePreference,
        culturalReligiousRituals: text(_religiousConsiderationsController),
        culturalConsiderations: text(_culturalConsiderationsController),
        accessibilityNeeds: text(_accessibilityNeedsController),
        pastBirthTraumaOrComplications: text(_traumaHistoryController),
        anxietyTriggers: _anxietyTriggers,
        consentBasedCare: _consentBasedCare,
        preferredBadNewsDelivery: _preferredBadNewsDelivery,
        fearReductionRequests: _fearReductionRequests,
        inMyOwnWords: text(_inMyOwnWordsController),
        providerName: editing?.providerName ?? _providerName,
        createdAt: editing?.createdAt,
        updatedAt: editing != null ? DateTime.now() : null,
      );

      // Format the birth plan and keep a snapshot of the form so the plan can
      // be reopened for editing exactly as it was filled in.
      final formattedPlan = BirthPlanFormatter().format(birthPlan);
      final updatedPlan = birthPlan.copyWith(
        formattedPlan: formattedPlan,
        status: 'complete',
        progressData: _getProgressData(),
      );

      // Save to Firestore with complete status. Editing updates the same
      // plan; finishing a saved draft completes that draft instead of
      // leaving a duplicate "Incomplete" card behind.
      final planData = updatedPlan.toFirestore();
      planData['status'] = 'complete';
      final targetId = editing?.id ?? widget.incompletePlanId;
      final DocumentReference docRef;
      if (targetId != null) {
        docRef =
            FirebaseFirestore.instance.collection('birth_plans').doc(targetId);
        await docRef.set(planData);
      } else {
        docRef = await FirebaseFirestore.instance
            .collection('birth_plans')
            .add(planData);
      }
      _saved = true;

      if (editing != null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pop(context, updatedPlan.copyWith(id: docRef.id));
        return;
      }

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
    if (plan.cordBloodBanking == true ||
        (plan.placentaPreference != null &&
            plan.placentaPreference!.contains('Save'))) {
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
      'title': 'Plan 2 to 3 postpartum support people',
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
    // Nothing to draft once the plan is saved, and backing out of an edit
    // should leave the saved plan untouched rather than create a draft.
    if (_saved || widget.editingPlan != null) return;
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
        backgroundColor: AppTheme.ground,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _pageScrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              // No side padding here: the step banner scrolls edge to edge.
              padding: EdgeInsets.only(
                bottom: 32 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HearthPushedHeader(
                    onBack: () => Navigator.pop(context),
                    backLabel: 'Birth Plans',
                    title: 'My Birth Preferences',
                    subtitle: 'Your birth, your choices, one step at a time',
                  ),
                  const SizedBox(height: 16),
                  if (!_introDismissed) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildAffirmingIntroCard(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildStepChipsRow(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                      ],
                    ),
                  ),
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
    return HearthFeatureCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            // Extra right padding keeps the title clear of the close button.
            padding: const EdgeInsets.fromLTRB(20, 20, 44, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HearthIconChip(
                  Icons.favorite_border,
                  tone: HearthChipTone.surface,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You know what\'s right for you',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'There\'s no right or wrong way to give birth. This plan helps you explore options and share what feels right with your care team. You can change your mind anytime.',
                        style: hearthCardBodyStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: _dismissIntro,
              tooltip: 'Dismiss',
              icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontally scrolling step banner. Swipe (or drag with a mouse/trackpad
  /// on web) to see every step; tap any step to jump to it. Answers entered on
  /// other steps are kept.
  Widget _buildStepChipsRow() {
    // The keyed SizedBox is what _goToStep aligns to the top of the page.
    return SizedBox(
      key: _stepChipsKey,
      width: double.infinity,
      child: HorizontalDragScroll(
        child: SingleChildScrollView(
          controller: _stepChipsScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < _stepCount; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                _buildStepChip(index),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepChip(int index) {
    final meta = _stepMeta[index];
    final isActive = _currentStep == index;
    final isComplete = _currentStep > index;
    // Active step purple, finished steps gold with a check, upcoming cream.
    final Color fill = isActive
        ? AppTheme.brandPurple
        : isComplete
            ? AppTheme.brandGold
            : AppTheme.surface;
    final Color fg = isActive
        ? AppTheme.onPurple
        : isComplete
            ? AppTheme.ink
            : AppTheme.textSecondary;
    return Semantics(
      key: _stepChipKeys[index],
      button: true,
      selected: isActive,
      label: 'Step ${index + 1} of $_stepCount: ${meta.title}',
      excludeSemantics: true,
      child: Builder(
        builder: (_) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _goToStep(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: ShapeDecoration(
                color: fill,
                shape: StadiumBorder(
                  side: (!isActive && !isComplete)
                      ? const BorderSide(color: AppTheme.borderWarm)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(meta.icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                  Text(
                    '${index + 1}. ${meta.title}',
                    style: TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (isComplete) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check, size: 16, color: fg),
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
        HearthCard(
          onTap: () => setState(() => _whyExpanded[id] = !expanded),
          color: AppTheme.tintWarm,
          borderColor: null,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Why this matters',
                    style: hearthCardTitleStyle.copyWith(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: AppTheme.brandPurple,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          HearthCard(
            child: Text(body, style: hearthCardBodyStyle),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppTheme.brandPurple,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'What does this mean?',
                      style: hearthCaptionStyle.copyWith(fontWeight: FontWeight.w600),
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
              style: hearthCaptionStyle.copyWith(height: 20 / 13),
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
            child: HearthButton.secondary(
              label: 'Previous',
              icon: Icons.chevron_left,
              onPressed: () => _goToStep(_currentStep - 1),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          // Plain themed button: HearthButton has no trailing-chevron variant
          // for a filled button, and the mockup puts the chevron after the label.
          child: ElevatedButton(
            onPressed: () => _goToStep(_currentStep + 1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text('Next step', textAlign: TextAlign.center)),
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
    return HearthFeatureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You\'re done!\u00A0'.trim(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            _isEditing ? 'Tap Save changes below to update your plan.' : 'Tap Save plan below to finish and store your preferences. You can open your plan from the list anytime.',
            style: hearthCardBodyStyle,
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
          HearthButton.secondary(
            label: 'Previous',
            icon: Icons.chevron_left,
            onPressed: () => _goToStep(_currentStep - 1),
          ),
        if (_currentStep > 0) const SizedBox(height: 12),
        // HearthButton disables itself while loading, as before.
        HearthButton.primary(
          label: _isEditing ? 'Save changes' : 'Save plan',
          loading: _isLoading,
          onPressed: _generateBirthPlan,
        ),
      ],
    );
  }

  /// Card holding one group of questions. Fields inside sit on the page
  /// colour so they read as inset, and switch rows lose their side padding.
  Widget _sectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: AppTheme.surfaceInset,
        ),
      ),
      child: ListTileTheme(
        data: const ListTileThemeData(
          contentPadding: EdgeInsets.zero,
          titleTextStyle: TextStyle(
            fontFamily: AppTheme.sansFamily,
            fontSize: 15,
            height: 22 / 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
          subtitleTextStyle: hearthCaptionStyle,
        ),
        child: HearthCard(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: hearthCardBodyStyle),
              ],
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // Labels sit above the field, as in the Hearth forms.
  Widget _labeled(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.ink),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return _labeled(
      label,
      DropdownButtonFormField<String>(
        isExpanded: true,
        value: value,
        icon: const Icon(Icons.expand_more, color: AppTheme.brandPurple),
        dropdownColor: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
        decoration: const InputDecoration(),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSection1() {
    return _sectionCard(
      title: 'Who do you want with you?',
      subtitle: 'Choose the people who make you feel safe and supported.',
      children: [
                // Tappable date row drawn like a field: label, value, calendar icon.
                HearthCard(
                  color: AppTheme.surfaceInset,
                  radius: BorderRadius.circular(AppTheme.fieldRadius),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Due Date',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _dueDate != null
                                  ? DateFormat('MMMM d, yyyy').format(_dueDate!)
                                  : 'Tap to select',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 22,
                        color: AppTheme.brandPurple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Birth partner(s)',
                  TextFormField(
                    controller: _supportPersonNameController,
                    decoration: const InputDecoration(
                      hintText: 'Partner, family member, friend…',
                      prefixIcon: Icon(Icons.people_outline, color: AppTheme.brandPurple),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'How they’re connected to you',
                  TextFormField(
                    controller: _supportPersonRelationshipController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. partner, parent, friend',
                      prefixIcon: Icon(Icons.family_restroom, color: AppTheme.brandPurple),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Best phone number (for urgent questions)',
                  TextFormField(
                    controller: _contactInfoController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.brandPurple),
                    ),
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
    );
  }

  Widget _buildSection2() {
    return _sectionCard(
      title: 'What helps you feel calm?',
      subtitle: 'Choose the settings that help you relax (you can pick more than one).',
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
                _dropdownField(
                  label: 'Language you want care in',
                  value: _preferredLanguage,
                  items: ['English', 'Spanish', 'Other']
                      .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            ))
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
                  'so you feel more in control, especially if past experiences make care harder.',
                ),
      ],
    );
  }

  Widget _buildSection3() {
    return _sectionCard(
      title: 'How would you like to manage discomfort?',
      subtitle: 'There are many ways to stay comfortable. Choose what you’re considering. You can change your mind later.',
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
                _dropdownField(
                  label: 'Fetal monitoring',
                  value: _monitoringPreference,
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
                _dropdownField(
                  label: 'Pain relief',
                  value: _painManagementPreference,
                  items: const [
                    DropdownMenuItem(
                      value: 'Unmedicated',
                      child: Text(
                        'No pain medicine, comfort tools only',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Epidural',
                      child: Text(
                        'Epidural (small tube in your back)',
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
                        'Massage, water, breathing: open to discussion',
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
                  'You can change your mind later. This is what you’re open to discussing.',
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
                _dropdownField(
                  label: 'Membrane sweep',
                  value: _membraneSweepingPreference,
                  items:
                      ['Yes, if offered', 'No', 'Only if medically indicated']
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                  onChanged: (v) =>
                      setState(() => _membraneSweepingPreference = v),
                ),
                _jargonExpandable(
                  'membrane',
                  'A membrane sweep is when a care provider gently sweeps a finger at the cervix '
                  '(opening of the womb) to encourage labor. It is optional, only if you and your provider agree it’s right for you.',
                ),
                const SizedBox(height: 16),
                _dropdownField(
                  label: 'If labor needs help starting',
                  value: _inductionPreference,
                  items:
                      [
                            'Natural methods first',
                            'Open to medical induction',
                            'Prefer to avoid',
                          ]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _inductionPreference = v),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'How you like updates and decisions explained',
                  TextFormField(
                    controller: _communicationStyleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. explain options first, keep me calm',
                    ),
                    onChanged: (v) => setState(() => _communicationStyle = v),
                  ),
                ),
      ],
    );
  }

  Widget _buildSection4() {
    return _sectionCard(
      title: 'Pushing & birth',
      subtitle: 'Your team can suggest options; share what feels right for your body.',
      children: [
                _buildMultiSelectChips('Positions for pushing', [
                  'Hands and knees',
                  'Side-lying',
                  'Squatting',
                  'Semi-reclined',
                  'Whatever feels right',
                ], _preferredPushingPositions),
                const SizedBox(height: 16),
                _dropdownField(
                  label: 'Guidance while pushing',
                  value: _pushingStyle,
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
                _dropdownField(
                  label: 'Episiotomy',
                  value: _episiotomyPreference,
                  items:
                      [
                            'Avoid unless absolutely necessary',
                            'Open to if needed',
                            'No preference',
                          ]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _episiotomyPreference = v),
                ),
                _jargonExpandable(
                  'episiotomy',
                  'An episiotomy is a small cut at the vaginal opening, usually only if there is a medical reason. '
                  'Many people prefer to avoid it unless truly necessary. Your provider can explain in the moment.',
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Support for the vaginal area while stretching',
                  TextFormField(
                    controller: _tearingPreferenceController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. warm cloths, hands-on support',
                    ),
                    onChanged: (v) => setState(() => _tearingPreference = v),
                  ),
                ),
                const SizedBox(height: 16),
                _dropdownField(
                  label: 'Who you’d like to receive baby',
                  value: _whoCatchesBaby,
                  items: ['Partner', 'Doctor', 'Midwife', 'Myself']
                      .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            ))
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
    );
  }

  Widget _buildSection5() {
    return _sectionCard(
      title: 'First moments with your baby',
      subtitle: 'These choices are about the first hour after birth.',
      children: [
                _dropdownField(
                  label: 'Delayed cord clamping',
                  value: _delayedCordClampingPreference,
                  items:
                      [
                            '1-3 minutes',
                            '3-5 minutes',
                            'Until cord stops pulsing',
                            'No preference',
                          ]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            ),
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
                _dropdownField(
                  label: 'Who cuts the cord',
                  value: _whoCutsCord,
                  items: ['Partner', 'Myself', 'Doctor', 'No preference']
                      .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            ))
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
                  subtitle: const Text('Optional. Often arranged ahead with a company'),
                  value: _cordBloodBanking ?? false,
                  onChanged: (v) => setState(() => _cordBloodBanking = v),
                ),
                if (_cordBloodBanking == true) ...[
                  const SizedBox(height: 16),
                  _labeled(
                    'Cord blood company name',
                    TextFormField(
                      controller: _cordBloodCompanyController,
                      decoration: const InputDecoration(),
                    ),
                  ),
                ],
      ],
    );
  }

  Widget _buildSection6() {
    return _sectionCard(
      title: 'Feeding your baby',
      children: [
                _dropdownField(
                  label: 'How you plan to feed your baby',
                  value: _feedingPreference,
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
                  subtitle: const Text('If nursing (optional preference)'),
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
    );
  }

  Widget _buildSection7() {
    return _sectionCard(
      title: 'Recovery after birth',
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
                _labeled(
                  'Visitors',
                  TextFormField(
                    controller: _visitorPreferenceController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. partner only for the first day',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Food needs or restrictions',
                  TextFormField(
                    controller: _dietaryPreferencesController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. vegetarian, allergies',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Comfort for soreness after birth',
                  TextFormField(
                    controller: _postpartumPainManagementController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. ibuprofen first; ask before stronger meds',
                    ),
                  ),
                ),
      ],
    );
  }

  Widget _buildSection8() {
    return _sectionCard(
      title: 'If a cesarean birth is needed',
      subtitle: 'Sometimes called a belly birth. Worth sharing even if you plan a vaginal birth.',
      children: [
                _dropdownField(
                  label: 'Surgical drape / screen',
                  value: _drapePreference,
                  items: const [
                    DropdownMenuItem(
                      value: 'Clear drape',
                      child: Text(
                        'Clear screen to see baby lifted up',
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
                  title: const Text(
                    'Delay routine newborn tasks until you’re holding baby',
                    maxLines: 3,
                    softWrap: true,
                  ),
                  value: _delayNewbornCareUntilHolding ?? false,
                  onChanged: (v) =>
                      setState(() => _delayNewbornCareUntilHolding = v),
                ),
                const SizedBox(height: 16),
                _dropdownField(
                  label: 'Anesthesia for surgery',
                  value: _anesthesiaPreference,
                  items: const [
                    DropdownMenuItem(
                      value: 'Spinal',
                      child: Text(
                        'Spinal (numbs from waist down)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Epidural',
                      child: Text(
                        'Epidural (tube in back)',
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
                _dropdownField(
                  label: 'How the incision is closed',
                  value: _surgicalClosurePreference,
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
    );
  }

  Widget _buildSection9() {
    return _sectionCard(
      title: 'If something unexpected happens',
      subtitle: 'Most births go as planned, but sharing this now can help your team support you.',
      children: [
                _labeled(
                  'Faith or spiritual practices that matter to you',
                  TextFormField(
                    controller: _religiousConsiderationsController,
                    decoration: const InputDecoration(),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Cultural traditions we should know about',
                  TextFormField(
                    controller: _culturalConsiderationsController,
                    decoration: const InputDecoration(),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Accessibility or mobility needs',
                  TextFormField(
                    controller: _accessibilityNeedsController,
                    decoration: const InputDecoration(),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Past trauma (only if you want to share)',
                  TextFormField(
                    controller: _traumaHistoryController,
                    decoration: const InputDecoration(),
                    maxLines: 2,
                  ),
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
                  'Extra check-ins so you can consent before procedures or exams along the way, not just once at admission.',
                ),
                const SizedBox(height: 16),
                _dropdownField(
                  label: 'How you prefer hard news to be shared',
                  value: _preferredBadNewsDelivery,
                  items:
                      [
                            'Private conversation',
                            'With partner present',
                            'Written first, then discussion',
                            'Direct and clear',
                          ]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            ),
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
    );
  }

  Widget _buildSection10() {
    return _sectionCard(
      title: 'Anything else?',
      subtitle: 'Optional: your own words for your care team.',
      children: [
                _labeled(
                  'What you want your team to know',
                  TextFormField(
                    controller: _inMyOwnWordsController,
                    decoration: const InputDecoration(
                      hintText:
                          'Anything else you\'d like your care team to know…',
                    ),
                    maxLines: 5,
                  ),
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
    return _labeled(
      label,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              const SizedBox(width: 10),
              HearthCircleButton(
                icon: Icons.add,
                iconColor: AppTheme.brandPurple,
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    onAdd(controller.text);
                  }
                },
              ),
            ],
          ),
          ...items.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: HearthCard(
                radius: BorderRadius.circular(AppTheme.fieldRadius),
                padding: const EdgeInsets.only(left: 16, right: 2),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontFamily: AppTheme.sansFamily,
                            fontSize: 15,
                            height: 22 / 15,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                        onPressed: () => onRemove(entry.key),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMultiSelectChips(
    String label,
    List<String> options,
    List<String> selected,
  ) {
    return _labeled(
      label,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final isSelected = selected.contains(option);
          return HearthChoiceChip(
            label: option,
            selected: isSelected,
            onSelected: () {
              setState(() {
                if (!isSelected) {
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
    String? status,
    Map<String, dynamic>? progressData,
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
      status: status ?? this.status,
      progressData: progressData ?? this.progressData,
      // Fields not exposed as parameters are carried over unchanged so a
      // copy never silently drops recorded preferences.
      doulaName: doulaName,
      preferredHospital: preferredHospital,
      lightingPreference: lightingPreference,
      noisePreference: noisePreference,
      visitorsAllowed: visitorsAllowed,
      naturalComfortMeasures: naturalComfortMeasures,
      whenToOfferPainMedication: whenToOfferPainMedication,
      ivFluidsPreference: ivFluidsPreference,
      vaginalExamsPreference: vaginalExamsPreference,
      membraneRupturePreference: membraneRupturePreference,
      vacuumForcepsPreference: vacuumForcepsPreference,
      cesareanPreference: cesareanPreference,
      seeTouchBabyHeadDuringCrowning: seeTouchBabyHeadDuringCrowning,
      cordCuttingPreference: cordCuttingPreference,
      nicuTransferInstructions: nicuTransferInstructions,
      gentleCesarean: gentleCesarean,
      musicAllowedInOR: musicAllowedInOR,
      delayCordClampingInCesarean: delayCordClampingInCesarean,
      partnerCutsCordInCesarean: partnerCutsCordInCesarean,
      goldenHourHonoredIfStable: goldenHourHonoredIfStable,
      traumaInformedCareNotes: traumaInformedCareNotes,
      preferredCommunicationStyle: preferredCommunicationStyle,
      genderPreferenceForProviders: genderPreferenceForProviders,
      racialBiasConcerns: racialBiasConcerns,
      stopWordOrPhrase: stopWordOrPhrase,
      advocacyPreferences: advocacyPreferences,
      socialWorkConsultIfNeeded: socialWorkConsultIfNeeded,
      highRiskPregnancyNotes: highRiskPregnancyNotes,
      chronicHealthConditions: chronicHealthConditions,
      medications: medications,
      environmentPreferences: environmentPreferences,
      perinealSupportPreference: perinealSupportPreference,
      eyeOintment: eyeOintment,
      cordBloodBanking: cordBloodBanking,
      cordBloodCompany: cordBloodCompany,
      photosAllowedInOR: photosAllowedInOR,
      delayNewbornCareUntilHolding: delayNewbornCareUntilHolding,
      anesthesiaPreference: anesthesiaPreference ?? this.anesthesiaPreference,
      surgicalClosurePreference: surgicalClosurePreference,
      culturalConsiderations: culturalConsiderations,
    );
  }
}
