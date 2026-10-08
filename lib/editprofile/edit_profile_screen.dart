import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../cors/ui_theme.dart';
import '../app_router.dart';
import '../auth/guest_account_cta.dart';
import '../utils/pregnancy_utils.dart';
import '../immediate_support/widgets/immediate_support_home_card.dart';
import '../widgets/trust_cue_banner.dart';
import '../pregnancy_loss/widgets/support_stage_settings_tile.dart';
import '../design_system/hearth.dart';
import '../support_stage/support_stage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Scroll + anchor so the "Edit" button on the Pregnancy Details card can
  // jump the user straight to the editable pregnancy fields.
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _pregnancyEditKey = GlobalKey();
  final GlobalKey _basicInfoKey = GlobalKey();
  final FocusNode _usernameFocus = FocusNode();

  /// True once the user taps "Edit Profile" — reveals the editing banner so it
  /// is obvious the fields below are now being edited.
  bool _isEditing = false;

  /// Enter edit mode: show the editing banner, scroll to [scrollTo], and focus
  /// [focus] (which pops the keyboard) so it's unmistakable that editing began.
  void _enterEditMode({GlobalKey? scrollTo, FocusNode? focus}) {
    setState(() => _isEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = scrollTo?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.05,
        );
      }
      focus?.requestFocus();
    });
  }
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _childAgeMonthsController = TextEditingController();
  final _allergyController = TextEditingController();
  final _medicalConditionController = TextEditingController();
  final _medicationController = TextEditingController();
  
  // State variables
  DateTime? _dueDate;
  bool _isPregnant = false;
  bool _isPostpartum = false;
  int? _childAgeMonths;
  String _insuranceType = '';
  String? _city;
  String? _state;
  String? _raceEthnicity;
  String? _languagePreference;
  String? _maritalStatus;
  String? _educationLevel;
  String? _pregnancyStage;
  List<String> _allergies = [];
  List<String> _medicalConditions = [];
  List<String> _medications = [];
  bool _hasDoula = false;
  bool _hasPartner = false;
  bool _hasSupportPerson = false;
  bool _hasPrimaryProvider = false;
  bool _hasTransportation = false;
  bool _needsChildcare = false;
  bool _enrolledInWIC = false;
  bool _hasMentalHealthSupport = false;
  bool _hasAccessToFood = false;
  bool _hasStableHousing = false;
  List<String> _providerPreferences = [];
  String? _birthPreference;
  bool _interestedInBreastfeeding = false;
  List<String> _healthLiteracyGoals = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final profile = await _databaseService.getUserProfile(userId);
      if (!mounted) return;
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _ageController.text = profile.age.toString();
          _zipCodeController.text = profile.zipCode;
          _dueDate = profile.dueDate;
          _isPregnant = profile.isPregnant;
          _isPostpartum = profile.isPostpartum;
          _childAgeMonths = profile.childAgeMonths;
          _childAgeMonthsController.text = profile.childAgeMonths?.toString() ?? '';
          _insuranceType = profile.insuranceType;
          _city = profile.city;
          _state = profile.state;
          _raceEthnicity = profile.raceEthnicity;
          _languagePreference = profile.languagePreference;
          _maritalStatus = profile.maritalStatus;
          _educationLevel = profile.educationLevel;
          _pregnancyStage = profile.pregnancyStage;
          _allergies = List.from(profile.allergies);
          _medicalConditions = List.from(profile.chronicConditions);
          _medications = List.from(profile.medications);
          _hasDoula = profile.hasDoula;
          _hasPartner = profile.hasPartner;
          _hasSupportPerson = profile.hasSupportPerson;
          _hasPrimaryProvider = profile.hasPrimaryProvider;
          _hasTransportation = profile.hasTransportation;
          _needsChildcare = profile.needsChildcare;
          _enrolledInWIC = profile.enrolledInWIC;
          _hasMentalHealthSupport = profile.hasMentalHealthSupport;
          _hasAccessToFood = profile.hasAccessToFood;
          _hasStableHousing = profile.hasStableHousing;
          _providerPreferences = List.from(profile.providerPreferences);
          _birthPreference = profile.birthPreference;
          _interestedInBreastfeeding = profile.interestedInBreastfeeding;
          _healthLiteracyGoals = List.from(profile.healthLiteracyGoals);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _zipCodeController.dispose();
    _childAgeMonthsController.dispose();
    _allergyController.dispose();
    _medicalConditionController.dispose();
    _medicationController.dispose();
    _scrollController.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userId = _auth.currentUser?.uid;
    if (userId == null || _userProfile == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final updatedProfile = UserProfile(
        userId: userId,
        username: _usernameController.text.trim(),
        age: int.parse(_ageController.text),
        isPregnant: _isPregnant,
        dueDate: _dueDate,
        isPostpartum: _isPostpartum,
        childAgeMonths: _childAgeMonths,
        zipCode: _zipCodeController.text.trim(),
        city: _city,
        state: _state,
        insuranceType: _insuranceType,
        raceEthnicity: _raceEthnicity,
        languagePreference: _languagePreference,
        maritalStatus: _maritalStatus,
        educationLevel: _educationLevel,
        pregnancyStage: _pregnancyStage,
        chronicConditions: _medicalConditions,
        medications: _medications,
        allergies: _allergies,
        hasDoula: _hasDoula,
        hasPartner: _hasPartner,
        hasSupportPerson: _hasSupportPerson,
        hasPrimaryProvider: _hasPrimaryProvider,
        hasTransportation: _hasTransportation,
        needsChildcare: _needsChildcare,
        enrolledInWIC: _enrolledInWIC,
        hasMentalHealthSupport: _hasMentalHealthSupport,
        hasAccessToFood: _hasAccessToFood,
        hasStableHousing: _hasStableHousing,
        providerPreferences: _providerPreferences,
        birthPreference: _birthPreference,
        interestedInBreastfeeding: _interestedInBreastfeeding,
        healthLiteracyGoals: _healthLiteracyGoals,
        createdAt: _userProfile!.createdAt,
        updatedAt: DateTime.now(), // Explicitly set updatedAt
      );
      
      await _databaseService.saveUserProfile(updatedProfile);

      try {
        await AnalyticsService().logEvent(
          eventName: 'profile_updated',
          feature: 'profile-editing',
          parameters: {'screen': 'edit_profile'},
          userProfile: updatedProfile,
        );
      } catch (_) {}
      
      // Verify user is still authenticated
      if (_auth.currentUser == null) {
        throw Exception('User session expired. Please sign in again.');
      }
      
      // Reload the profile to get the latest data
      await _loadProfile();
      
      if (mounted) {
        FocusScope.of(context).unfocus();
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        // Don't navigate away - let user stay on edit screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.auth,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text(
          'Are you sure you want to delete your profile? This action cannot be undone and will delete all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            // Destructive actions are ink, not red.
            style: TextButton.styleFrom(foregroundColor: AppTheme.ink),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _databaseService.deleteUserProfile(userId);
          await _authService.deleteAccount();
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.login,
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting profile: $e')),
          );
        }
      }
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Guests have no account profile — invite them to create one.
    if (_auth.currentUser?.isAnonymous ?? false) {
      return const GuestAccountCta(
        message:
            'You\'re exploring as a guest. Create a free account to build your '
            'profile, save progress, and get personalized support.',
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _auth.currentUser;
    final userName = _userProfile?.username ?? user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final dueDate = _userProfile?.dueDate;
    final weeksPregnant = PregnancyUtils.calculateWeeksPregnant(dueDate);
    final trimester = PregnancyUtils.calculateTrimester(dueDate);
    
    final textTheme = Theme.of(context).textTheme;
    final inLossMode = _userProfile?.isInPregnancyLossMode ?? false;

    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Loss mode has no decorative accents.
                  HearthTabHeader(
                    warmCircle: !inLossMode,
                    title: 'Your profile',
                    subtitle: 'Manage your information and preferences',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  const TrustCueBanner(
                    message: 'Profile and health details are stored securely and used to personalize your experience.',
                  ),
                  const SizedBox(height: 24),

                  // Profile hero on the warm tint.
                  HearthFeatureCard(
                    // Avatar + name/metadata share one row (text Expanded);
                    // the Edit Profile button sits on its own row beneath so
                    // it never steals width from the name at large text sizes.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: AppTheme.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(userName),
                                    style: const TextStyle(
                                      fontFamily: AppTheme.serifFamily,
                                      fontSize: 26,
                                      height: 32 / 26,
                                      color: AppTheme.brandPurple,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: hearthFeatureTitleStyle(),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? '',
                                    style: hearthCardBodyStyle,
                                  ),
                                  if (dueDate != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Due date: ${DateFormat('MMMM d, yyyy').format(dueDate)}',
                                      style: hearthCardBodyStyle,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        HearthButton.primary(
                          onPressed: () => _enterEditMode(
                            scrollTo: _basicInfoKey,
                            focus: _usernameFocus,
                          ),
                          icon: Icons.edit_outlined,
                          label: 'Edit Profile',
                          expand: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pregnancy Details Section
                  if (dueDate != null && weeksPregnant > 0) ...[
                    HearthSectionHeading(
                      'Pregnancy Details',
                      trailing: HearthButton.text(
                        onPressed: () =>
                            _enterEditMode(scrollTo: _pregnancyEditKey),
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                      ),
                    ),
                    const SizedBox(height: 12),
                    HearthCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _InfoRow(
                            label: 'Current Week',
                            value: 'Week $weeksPregnant of 40',
                            icon: Icons.calendar_today_outlined,
                          ),
                          const Divider(height: 33),
                          _InfoRow(
                            label: 'Due Date',
                            value: DateFormat('MMMM d, yyyy').format(dueDate),
                          ),
                          const Divider(height: 33),
                          _InfoRow(
                            label: 'Trimester',
                            value: '$trimester Trimester',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Basic Information Section
                  SizedBox(key: _basicInfoKey),
                  if (_isEditing) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: HearthNote(
                        icon: Icons.edit_outlined,
                        tone: HearthNoteTone.lavender,
                        text: "You're editing your profile. Update your details "
                            'below, then tap Save Changes.',
                      ),
                    ),
                  ],
                  // Every section sits in one bordered card, split by dividers.
                  HearthCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _withDividers([
                  _buildSection('Basic Information', [
                TextFormField(
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    prefixIcon: Icon(Icons.person_outline),
                    helperText: 'This will be displayed in the community and reviews',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 3) return 'Username must be at least 3 characters';
                    if (v.length > 20) return 'Username must be 20 characters or less';
                    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(v)) {
                      return 'Username can only contain letters, numbers, underscores, and hyphens';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age *',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final age = int.tryParse(v);
                    if (age == null || age < 13 || age > 100) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _checkTile(
                  key: _pregnancyEditKey,
                  title: 'I am currently pregnant',
                  value: _isPregnant,
                  onChanged: (v) {
                    setState(() {
                      _isPregnant = v ?? false;
                      if (!_isPregnant) _dueDate = null;
                    });
                  },
                ),
                if (_isPregnant) ...[
                  const SizedBox(height: 8),
                  // Drawn as a field so it matches the inputs around it.
                  InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 180)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _dueDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                      child: Text(
                        _dueDate != null
                            ? DateFormat('MMMM d, yyyy').format(_dueDate!)
                            : 'Tap to select',
                        style: textTheme.bodyLarge?.copyWith(color: AppTheme.ink),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _checkTile(
                  title: 'I am postpartum',
                  value: _isPostpartum,
                  onChanged: (v) {
                    setState(() {
                      _isPostpartum = v ?? false;
                      if (!_isPostpartum) _childAgeMonths = null;
                    });
                  },
                ),
                if (_isPostpartum) ...[
                  TextFormField(
                    controller: _childAgeMonthsController,
                    decoration: const InputDecoration(
                      labelText: 'Child\'s Age (in months)',
                      prefixIcon: Icon(Icons.child_care),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final age = int.tryParse(v);
                      if (age != null && age >= 0) {
                        setState(() => _childAgeMonths = age);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _zipCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Zip Code *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length != 5) return 'Please enter a valid 5-digit zip code';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _city,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  onChanged: (v) => setState(() => _city = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _state,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    prefixIcon: Icon(Icons.map_outlined),
                    helperText: 'Enter state abbreviation (e.g., OH)',
                  ),
                  onChanged: (v) => setState(() => _state = v?.toUpperCase()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _insuranceType.isEmpty ? null : _insuranceType,
                  decoration: const InputDecoration(
                    labelText: 'Insurance Type *',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Private', child: Text('Private Insurance')),
                    DropdownMenuItem(value: 'Medicaid', child: Text('Medicaid')),
                    DropdownMenuItem(value: 'Medicare', child: Text('Medicare')),
                    DropdownMenuItem(value: 'Uninsured', child: Text('Uninsured')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onChanged: (v) => setState(() => _insuranceType = v ?? ''),
                ),
              ]),
              
              // Demographics Section
              _buildSection('Demographics', [
                DropdownButtonFormField<String>(
                  value: _raceEthnicity,
                  decoration: const InputDecoration(labelText: 'Race/Ethnicity'),
                  items: const [
                    DropdownMenuItem(value: 'American Indian or Alaska Native', child: Text('American Indian or Alaska Native')),
                    DropdownMenuItem(value: 'Asian', child: Text('Asian')),
                    DropdownMenuItem(value: 'Black or African American', child: Text('Black or African American')),
                    DropdownMenuItem(value: 'Hispanic or Latino', child: Text('Hispanic or Latino')),
                    DropdownMenuItem(value: 'Native Hawaiian or Pacific Islander', child: Text('Native Hawaiian or Pacific Islander')),
                    DropdownMenuItem(value: 'White', child: Text('White')),
                    DropdownMenuItem(value: 'Two or More Races', child: Text('Two or More Races')),
                    DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                  ],
                  onChanged: (v) => setState(() => _raceEthnicity = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _languagePreference,
                  decoration: const InputDecoration(labelText: 'Preferred Language'),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                    DropdownMenuItem(value: 'Chinese', child: Text('Chinese')),
                    DropdownMenuItem(value: 'French', child: Text('French')),
                    DropdownMenuItem(value: 'German', child: Text('German')),
                    DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
                    DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                    DropdownMenuItem(value: 'Portuguese', child: Text('Portuguese')),
                    DropdownMenuItem(value: 'Russian', child: Text('Russian')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _languagePreference = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _maritalStatus,
                  decoration: const InputDecoration(labelText: 'Marital Status'),
                  items: const [
                    DropdownMenuItem(value: 'Single', child: Text('Single')),
                    DropdownMenuItem(value: 'Married', child: Text('Married')),
                    DropdownMenuItem(value: 'Partnered', child: Text('Partnered')),
                    DropdownMenuItem(value: 'Divorced', child: Text('Divorced')),
                    DropdownMenuItem(value: 'Widowed', child: Text('Widowed')),
                    DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                  ],
                  onChanged: (v) => setState(() => _maritalStatus = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _educationLevel,
                  decoration: const InputDecoration(labelText: 'Education Level'),
                  items: const [
                    DropdownMenuItem(value: 'Less than high school', child: Text('Less than high school')),
                    DropdownMenuItem(value: 'High school or GED', child: Text('High school or GED')),
                    DropdownMenuItem(value: 'Some college', child: Text('Some college')),
                    DropdownMenuItem(value: 'Associate degree', child: Text('Associate degree')),
                    DropdownMenuItem(value: 'Bachelor\'s degree', child: Text('Bachelor\'s degree')),
                    DropdownMenuItem(value: 'Graduate degree', child: Text('Graduate degree')),
                    DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                  ],
                  onChanged: (v) => setState(() => _educationLevel = v),
                ),
              ]),
              
              // Health Information Section
              _buildSection('Health Information', [
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
                _buildListInput('Medications', _medicationController, _medications, (item) {
                  setState(() => _medications.add(item));
                  _medicationController.clear();
                }, (index) {
                  setState(() => _medications.removeAt(index));
                }),
              ]),
              
              if (_userProfile != null)
                _buildSection('Your support experience', [
                  const ImmediateSupportHomeCard(
                    entrySource: 'profile',
                    compact: true,
                  ),
                  const SizedBox(height: 8),
                  SupportStageSettingsTile(profile: _userProfile!),
                ]),
              // Support Network Section
              _buildSection('Support Network', [
                _checkTile(
                  title: 'Doula',
                  value: _hasDoula,
                  onChanged: (v) => setState(() => _hasDoula = v ?? false),
                ),
                _checkTile(
                  title: 'Partner or Spouse',
                  value: _hasPartner,
                  onChanged: (v) => setState(() => _hasPartner = v ?? false),
                ),
                _checkTile(
                  title: 'Support Person',
                  value: _hasSupportPerson,
                  onChanged: (v) => setState(() => _hasSupportPerson = v ?? false),
                ),
                _checkTile(
                  title: 'Primary OB/GYN or Midwife',
                  value: _hasPrimaryProvider,
                  onChanged: (v) => setState(() => _hasPrimaryProvider = v ?? false),
                ),
              ]),

              // Wellness & Access Section
              _buildSection('Wellness & Access', [
                _checkTile(
                  title: 'Reliable Transportation',
                  value: _hasTransportation,
                  onChanged: (v) => setState(() => _hasTransportation = v ?? false),
                ),
                _checkTile(
                  title: 'Stable Housing',
                  value: _hasStableHousing,
                  onChanged: (v) => setState(() => _hasStableHousing = v ?? false),
                ),
                _checkTile(
                  title: 'Adequate Food',
                  value: _hasAccessToFood,
                  onChanged: (v) => setState(() => _hasAccessToFood = v ?? false),
                ),
                _checkTile(
                  title: 'Mental Health Support',
                  value: _hasMentalHealthSupport,
                  onChanged: (v) => setState(() => _hasMentalHealthSupport = v ?? false),
                ),
                _checkTile(
                  title: 'WIC Enrollment',
                  value: _enrolledInWIC,
                  onChanged: (v) => setState(() => _enrolledInWIC = v ?? false),
                ),
                _checkTile(
                  title: 'Childcare Needs',
                  value: _needsChildcare,
                  onChanged: (v) => setState(() => _needsChildcare = v ?? false),
                ),
              ]),
              
              // Preferences Section
              _buildSection('Provider Preferences', [
                _buildMultiSelectChips([
                  'Cultural match',
                  'Gender preference',
                  'Trauma-informed care',
                  'LGBTQ+ friendly',
                  'Spanish-speaking',
                  'Black-owned practice',
                  'Holistic approach',
                  'Evidence-based care',
                  'Community-based care',
                ], _providerPreferences),
              ]),
              
              // Goals Section
              _buildSection('Goals', [
                DropdownButtonFormField<String>(
                  value: _birthPreference,
                  decoration: const InputDecoration(labelText: 'Birth Preference'),
                  items: const [
                    DropdownMenuItem(value: 'Hospital', child: Text('Hospital Birth')),
                    DropdownMenuItem(value: 'Home', child: Text('Home Birth')),
                    DropdownMenuItem(value: 'Birth Center', child: Text('Birth Center')),
                    DropdownMenuItem(value: 'Undecided', child: Text('Undecided')),
                  ],
                  onChanged: (v) => setState(() => _birthPreference = v),
                ),
                const SizedBox(height: 16),
                _checkTile(
                  title: 'I am interested in breastfeeding support',
                  value: _interestedInBreastfeeding,
                  onChanged: (v) => setState(() => _interestedInBreastfeeding = v ?? false),
                ),
                const SizedBox(height: 16),
                _buildMultiSelectChips([
                  'Nutrition guidance',
                  'Exercise during pregnancy',
                  'Mental wellness',
                  'Healthy pregnancy tips',
                  'Postpartum recovery',
                  'Infant care',
                  'Sleep management',
                  'Stress management',
                  'Birth preparation',
                ], _healthLiteracyGoals),
              ]),
                      ]),
                    ),
                  ),

              const SizedBox(height: 24),

              // Privacy & Settings Section
              HearthCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HearthSectionHeading('Privacy & Settings'),
                    const SizedBox(height: 12),
                    // Custom row instead of ListTile so the title/supporting
                    // copy gets the full card width; icon and chevron stay in
                    // compact side columns.
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pushNamed(Routes.privacyCenter);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const HearthIconChip(Icons.lock_outline),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Privacy & Trust Center',
                                    style: hearthCardTitleStyle,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Manage your privacy settings and data',
                                    style: hearthCaptionStyle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right,
                                size: 20, color: AppTheme.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              HearthButton.primary(
                onPressed: _isSaving ? null : _saveProfile,
                loading: _isSaving,
                label: 'Save Changes',
              ),

              const SizedBox(height: 12),

              // Delete Profile Button
              HearthButton.destructive(
                onPressed: _deleteProfile,
                label: 'Delete Profile',
              ),

                  const SizedBox(height: 24),

                  // Sign Out row. Destructive actions are ink, not red.
                  HearthCard(
                    onTap: _signOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 46,
                          height: 46,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.tintWarm,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.logout,
                                size: 22, color: AppTheme.ink),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Sign Out',
                            style: hearthCardTitleStyle,
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
            ),
          ),
        ),
    );
  }

  /// Puts a warm divider between consecutive sections in the shared card.
  List<Widget> _withDividers(List<Widget> sections) {
    return [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const Divider(height: 1),
        sections[i],
      ],
    ];
  }

  Widget _checkTile({
    Key? key,
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.ink),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    // Consistent padding/alignment for every section row so titles that wrap
    // at large text sizes (e.g. "Your support experience") line up with
    // their single-line neighbours.
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTheme.sansFamily,
          fontSize: 16,
          height: 22 / 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      // The shared card draws the dividers, so the tile adds no borders.
      shape: const Border(),
      collapsedShape: const Border(),
      textColor: AppTheme.brandPurple,
      collapsedTextColor: AppTheme.ink,
      iconColor: AppTheme.brandPurple,
      collapsedIconColor: AppTheme.textMuted,
      initiallyExpanded: false,
      children: [
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
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
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.ink),
        ),
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
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.tintWarm,
                foregroundColor: AppTheme.brandPurple,
                fixedSize: const Size(52, 52),
              ),
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
              contentPadding: const EdgeInsets.only(left: 4),
              title: Text(
                entry.value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.ink),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                onPressed: () => onRemove(entry.key),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMultiSelectChips(List<String> options, List<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return HearthChoiceChip(
          label: option,
          selected: isSelected,
          onSelected: () {
            // Tapping flips the current selection, as FilterChip did.
            final isSelected = !selected.contains(option);
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: hearthCaptionStyle),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 15,
                  height: 22 / 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
        if (icon != null)
          Icon(icon, color: AppTheme.textMuted, size: 20),
      ],
    );
  }
}
