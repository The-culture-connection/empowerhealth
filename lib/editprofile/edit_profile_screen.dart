import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../cors/ui_theme.dart';
import '../app_router.dart';
import '../utils/pregnancy_utils.dart';

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
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Controllers
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
      setState(() => _isLoading = false);
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
        name: _userProfile!.name, // Name is not editable
        age: int.parse(_ageController.text),
        isPregnant: _isPregnant,
        dueDate: _dueDate,
        isPostpartum: _isPostpartum,
        childAgeMonths: _childAgeMonths,
        zipCode: _zipCodeController.text.trim(),
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
      
      // Verify user is still authenticated
      if (_auth.currentUser == null) {
        throw Exception('User session expired. Please sign in again.');
      }
      
      // Reload the profile to get the latest data
      await _loadProfile();
      
      if (mounted) {
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F8)],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final user = _auth.currentUser;
    final userName = _userProfile?.name ?? user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final dueDate = _userProfile?.dueDate;
    final weeksPregnant = PregnancyUtils.calculateWeeksPregnant(dueDate);
    final trimester = PregnancyUtils.calculateTrimester(dueDate);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F8)],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your information and preferences',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profile Card with Gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF663399), Color(0xFF8855BB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF663399).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(userName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              if (dueDate != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Due Date: ${DateFormat('MMMM d, yyyy').format(dueDate)}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Toggle edit mode - for now just show full form
                          },
                          child: const Text(
                            'Edit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pregnancy Details Section
                  if (dueDate != null && weeksPregnant > 0) ...[
                    const Text(
                      'Pregnancy Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                        children: [
                          _InfoRow(
                            label: 'Current Week',
                            value: 'Week $weeksPregnant of 40',
                            icon: Icons.calendar_today,
                          ),
                          const Divider(height: 32),
                          _InfoRow(
                            label: 'Due Date',
                            value: DateFormat('MMMM d, yyyy').format(dueDate),
                          ),
                          const Divider(height: 32),
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
                  _buildSection('Basic Information', [
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
                CheckboxListTile(
                  title: const Text('I am currently pregnant'),
                  value: _isPregnant,
                  onChanged: (v) {
                    setState(() {
                      _isPregnant = v ?? false;
                      if (!_isPregnant) _dueDate = null;
                    });
                  },
                ),
                if (_isPregnant) ...[
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
                        initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 180)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _dueDate = date);
                    },
                  ),
                ],
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('I am postpartum'),
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
              
              // Support Network Section
              _buildSection('Support Network', [
                CheckboxListTile(
                  title: const Text('Doula'),
                  value: _hasDoula,
                  onChanged: (v) => setState(() => _hasDoula = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Partner or Spouse'),
                  value: _hasPartner,
                  onChanged: (v) => setState(() => _hasPartner = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Support Person'),
                  value: _hasSupportPerson,
                  onChanged: (v) => setState(() => _hasSupportPerson = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Primary OB/GYN or Midwife'),
                  value: _hasPrimaryProvider,
                  onChanged: (v) => setState(() => _hasPrimaryProvider = v ?? false),
                ),
              ]),
              
              // Wellness & Access Section
              _buildSection('Wellness & Access', [
                CheckboxListTile(
                  title: const Text('Reliable Transportation'),
                  value: _hasTransportation,
                  onChanged: (v) => setState(() => _hasTransportation = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Stable Housing'),
                  value: _hasStableHousing,
                  onChanged: (v) => setState(() => _hasStableHousing = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Adequate Food'),
                  value: _hasAccessToFood,
                  onChanged: (v) => setState(() => _hasAccessToFood = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Mental Health Support'),
                  value: _hasMentalHealthSupport,
                  onChanged: (v) => setState(() => _hasMentalHealthSupport = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('WIC Enrollment'),
                  value: _enrolledInWIC,
                  onChanged: (v) => setState(() => _enrolledInWIC = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Childcare Needs'),
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
                CheckboxListTile(
                  title: const Text('I am interested in breastfeeding support'),
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
              
              const SizedBox(height: 24),
              
              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Delete Profile Button
              OutlinedButton(
                onPressed: _deleteProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Delete Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              
                  const SizedBox(height: 24),
                  
                  // Sign Out Button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: _signOut,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildMultiSelectChips(List<String> options, List<String> selected) {
    return Wrap(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        if (icon != null)
          Icon(icon, color: Colors.grey[400], size: 20),
      ],
    );
  }
}
