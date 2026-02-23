import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/provider_types.dart';
import '../constants/ohio_medicaid_api_options.dart';
import '../cors/ui_theme.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import 'provider_search_results_screen.dart';

class ProviderSearchEntryScreen extends StatefulWidget {
  const ProviderSearchEntryScreen({super.key});

  @override
  State<ProviderSearchEntryScreen> createState() => _ProviderSearchEntryScreenState();
}

class _ProviderSearchEntryScreenState extends State<ProviderSearchEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _zipController = TextEditingController();
  final _cityController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _radius = '10';
  String _healthPlan = '';
  bool _includeNPI = false;
  bool _showAdvanced = false;
  bool _hasLoadedProfile = false;
  
  List<String> _selectedProviderTypes = [];
  List<String> _selectedSpecialties = [];
  List<String> _selectedIdentityTags = [];
  List<String> _selectedLanguages = [];
  
  bool _showProviderTypes = false;
  bool _showSpecialties = false;
  bool _showIdentityTags = false;
  bool _showLanguages = false;
  
  // Advanced filters - Pregnancy-Smart only
  bool _telehealth = false;
  bool _acceptsPregnant = true;
  bool _acceptsNewborns = false;
  bool _mamaApprovedOnly = false;

  final List<String> _healthPlans = [
    'Buckeye',
    'CareSource',
    'Molina',
    'UnitedHealthcare',
    'Anthem',
    'Aetna',
  ];

  final List<String> _radiusOptions = ['3', '5', '10', '15', '25', '50'];

  final List<String> _identityTagOptions = [
    'Black / African American',
    'Latina/o/x',
    'Asian / Pacific Islander',
    'Native American / Indigenous',
    'Middle Eastern / North African',
    'Haitian',
    'Nigerian',
    'Somali',
    'Spanish-speaking',
    'Arabic-speaking',
    'French-speaking',
    'LGBTQ+ affirming',
    'Cultural competency certified',
  ];

  final List<String> _languageOptions = [
    'Spanish',
    'Arabic',
    'French',
    'Haitian Creole',
    'Somali',
    'Mandarin',
    'Vietnamese',
    'Tagalog',
    'Portuguese',
    'Russian',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfileForAutofill();
  }

  @override
  void dispose() {
    _zipController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfileForAutofill() async {
    if (_hasLoadedProfile) return; // Only load once
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final profile = await _databaseService.getUserProfile(userId);
      if (profile != null && mounted) {
        setState(() {
          // Autofill ZIP code
          if (profile.zipCode.isNotEmpty && _zipController.text.isEmpty) {
            _zipController.text = profile.zipCode;
          }
          
          // Autofill City
          if (profile.city != null && profile.city!.isNotEmpty && _cityController.text.isEmpty) {
            _cityController.text = profile.city!;
          }
          
          // Map insurance type to health plan
          if (_healthPlan.isEmpty) {
            _healthPlan = _mapInsuranceToHealthPlan(profile.insuranceType);
          }
          
          // Map provider preferences to identity tags
          if (profile.providerPreferences.isNotEmpty) {
            _selectedIdentityTags = _mapPreferencesToIdentityTags(profile.providerPreferences);
          }
          
          // Map language preference to languages
          if (profile.languagePreference != null && profile.languagePreference!.isNotEmpty) {
            final mappedLanguage = _mapLanguagePreference(profile.languagePreference!);
            if (mappedLanguage != null && !_selectedLanguages.contains(mappedLanguage)) {
              _selectedLanguages = [mappedLanguage];
            }
          }
          
          // Map birth preference to provider types
          if (profile.birthPreference != null && profile.birthPreference!.isNotEmpty) {
            final providerTypes = _mapBirthPreferenceToProviderTypes(profile.birthPreference!);
            if (providerTypes.isNotEmpty) {
              _selectedProviderTypes = providerTypes;
            }
          }
          
          // Set acceptsPregnant to true if user is pregnant
          if (profile.isPregnant) {
            _acceptsPregnant = true;
          }
          
          // Set acceptsNewborns if user is postpartum
          if (profile.isPostpartum) {
            _acceptsNewborns = true;
          }
          
          _hasLoadedProfile = true;
        });
      }
    } catch (e) {
      print('⚠️ [ProviderSearch] Error loading profile for autofill: $e');
    }
  }

  String _mapInsuranceToHealthPlan(String insuranceType) {
    // Map insurance types to health plans
    switch (insuranceType.toLowerCase()) {
      case 'medicaid':
        return 'CareSource'; // Default Medicaid plan
      case 'medicare':
        return 'Anthem';
      case 'private':
        return 'UnitedHealthcare';
      default:
        return '';
    }
  }

  List<String> _mapPreferencesToIdentityTags(List<String> preferences) {
    final mappedTags = <String>[];
    for (var pref in preferences) {
      switch (pref.toLowerCase()) {
        case 'cultural match':
          // Keep as is, will be matched by user selection
          break;
        case 'lgbtq+ friendly':
          mappedTags.add('LGBTQ+ affirming');
          break;
        case 'spanish-speaking':
          mappedTags.add('Spanish-speaking');
          break;
        case 'black-owned practice':
          mappedTags.add('Black / African American');
          break;
        default:
          // Try to match directly
          if (_identityTagOptions.contains(pref)) {
            mappedTags.add(pref);
          }
      }
    }
    return mappedTags;
  }

  String? _mapLanguagePreference(String languagePreference) {
    // Map language preferences to language options
    final lower = languagePreference.toLowerCase();
    for (var lang in _languageOptions) {
      if (lower.contains(lang.toLowerCase()) || lang.toLowerCase().contains(lower)) {
        return lang;
      }
    }
    return null;
  }

  List<String> _mapBirthPreferenceToProviderTypes(String birthPreference) {
    final types = <String>[];
    final lower = birthPreference.toLowerCase();
    
    if (lower.contains('hospital')) {
      types.add('Hospital');
    }
    if (lower.contains('birth center') || lower.contains('birthcenter')) {
      types.add('Free Standing Birth Center');
    }
    if (lower.contains('home')) {
      // Home birth might need midwife or doula
      types.add('Nurse Midwife Individual');
      types.add('Doula');
    }
    
    // If no specific preference, default to common maternal health providers
    if (types.isEmpty) {
      types.add('Physician / Osteopath Individual');
      types.add('Nurse Midwife Individual');
    }
    
    return types;
  }

  bool get _canSearch {
    return _zipController.text.length == 5 &&
        _cityController.text.isNotEmpty &&
        _healthPlan.isNotEmpty &&
        _selectedProviderTypes.isNotEmpty;
  }

  void _toggleItem(String item, List<String> list, Function(List<String>) setter) {
    setState(() {
      if (list.contains(item)) {
        setter(list.where((i) => i != item).toList());
      } else {
        setter([...list, item]);
      }
    });
  }

  void _handleSearch() {
    if (!_canSearch) return;

    // Convert provider type display names to IDs
    final providerTypeIds = <String>[];
    for (var displayName in _selectedProviderTypes) {
      final typeId = ProviderTypes.getTypeId(displayName);
      if (typeId != null) {
        providerTypeIds.add(typeId);
        print('🔍 [SearchEntry] Mapped "$displayName" → "$typeId"');
      } else {
        print('⚠️ [SearchEntry] Could not map provider type: "$displayName"');
      }
    }

    if (providerTypeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one valid provider type'),
        ),
      );
      return;
    }

    print('🔍 [SearchEntry] Final provider type IDs: $providerTypeIds');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderSearchResultsScreen(
          searchParams: {
            'zip': _zipController.text,
            'city': _cityController.text,
            'radius': int.parse(_radius),
            'healthPlan': _healthPlan,
            'providerTypeIds': providerTypeIds,
            'specialties': _selectedSpecialties,
            'includeNPI': _includeNPI,
            'telehealth': _telehealth,
            'acceptsPregnant': _acceptsPregnant,
            'acceptsNewborns': _acceptsNewborns,
            'mamaApprovedOnly': _mamaApprovedOnly,
            'identityTags': _selectedIdentityTags,
            'languages': _selectedLanguages,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      body: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundWarm,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Hero Header (matching NewUI exactly)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32), // px-6 pt-6 pb-8
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFEBE4F3), // from-[#ebe4f3]
                      Color(0xFFE0D5EB), // via-[#e0d5eb]
                      Color(0xFFE8DFE8), // to-[#e8dfe8]
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle background pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Color(0xFFD4C5E0),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: Color(0xFF8B7A95)),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Find your care team',
                                    style: TextStyle(
                                      fontSize: 24, // text-2xl
                                      fontWeight: FontWeight.w400, // font-normal
                                      color: Color(0xFF4A3F52), // text-[#4a3f52]
                                    ),
                                  ),
                                  const SizedBox(height: 8), // mb-2
                                  Text(
                                    'Trusted providers reviewed by mothers like you',
                                    style: TextStyle(
                                      fontSize: 14, // text-sm
                                      color: Color(0xFF6B5C75), // text-[#6b5c75]
                                      fontWeight: FontWeight.w300, // font-light
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24), // px-6
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Location Section
                        _buildSection(
                          title: 'Location',
                          icon: Icons.location_on,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: _zipController,
                                label: 'ZIP Code',
                                required: true,
                                maxLength: 5,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                hintText: 'Enter your ZIP code',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildDropdown(
                                      label: 'Search Radius',
                                      required: true,
                                      value: _radius,
                                      items: _radiusOptions,
                                      onChanged: (value) {
                                        setState(() {
                                          _radius = value ?? '10';
                                        });
                                      },
                                      displayText: (value) => '$value miles',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 1,
                                    child: _buildTextField(
                                      controller: TextEditingController(text: 'Ohio'),
                                      label: 'State',
                                      enabled: false,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _cityController,
                                label: 'City',
                                required: true,
                                hintText: 'Enter city name',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Insurance & Directory
                        _buildSection(
                          title: 'Insurance & Directory',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDropdown(
                                label: 'Health Plan',
                                required: true,
                                value: _healthPlan.isEmpty ? null : _healthPlan,
                                items: _healthPlans,
                                onChanged: (value) {
                                  setState(() {
                                    _healthPlan = value ?? '';
                                  });
                                },
                                hint: 'Select your health plan',
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Plan required for Ohio Medicaid directory',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFE8E0F0).withOpacity(0.6),
                                      Color(0xFFEDE7F3).withOpacity(0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.borderLighter.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _includeNPI,
                                      onChanged: (value) {
                                        setState(() {
                                          _includeNPI = value ?? false;
                                        });
                                      },
                                      activeColor: AppTheme.brandPurple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Include providers from NPI directory',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Adds all providers if no Medicaid match is found',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                              fontWeight: FontWeight.w300,
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

                        const SizedBox(height: 16),

                        // Provider Type
                        _buildSection(
                          title: 'Provider Type',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Provider Type',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Choose at least one',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              _buildExpandableSelector(
                                label: _selectedProviderTypes.isEmpty
                                    ? 'Select provider types'
                                    : '${_selectedProviderTypes.length} selected',
                                isExpanded: _showProviderTypes,
                                onToggle: () {
                                  setState(() {
                                    _showProviderTypes = !_showProviderTypes;
                                  });
                                },
                                options: ProviderTypes.getAllTypes()
                                    .map((t) => t['name']!)
                                    .toList(),
                                selected: _selectedProviderTypes,
                                onToggleItem: (item) => _toggleItem(
                                  item,
                                  _selectedProviderTypes,
                                  (list) => _selectedProviderTypes = list,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Specialty
                        _buildSection(
                          title: 'Specialty (Optional)',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Start typing to find a specialty, then select from suggestions',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              _buildExpandableSelector(
                                label: _selectedSpecialties.isEmpty
                                    ? 'Select specialties'
                                    : '${_selectedSpecialties.length} selected',
                                isExpanded: _showSpecialties,
                                onToggle: () {
                                  setState(() {
                                    _showSpecialties = !_showSpecialties;
                                  });
                                },
                                options: Specialties.specialties,
                                selected: _selectedSpecialties,
                                onToggleItem: (item) => _toggleItem(
                                  item,
                                  _selectedSpecialties,
                                  (list) => _selectedSpecialties = list,
                                ),
                                chipColor: Colors.purple,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Advanced Filters
                        _buildAdvancedFilters(),

                        const SizedBox(height: 24),

                        // Search Button (matching NewUI)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFD4C5E0), // from-[#d4c5e0]
                                Color(0xFFA89CB5), // to-[#a89cb5]
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFA89CB5).withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _canSearch ? _handleSearch : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Search Providers',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Add Provider Button (matching NewUI)
                        OutlinedButton(
                          onPressed: () {
                            // Navigate to add provider screen
                            // TODO: Implement navigation
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: BorderSide(
                              color: AppTheme.borderLighter.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'Can\'t find your provider? Add them',
                            style: TextStyle(
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required Widget child,
    String? title,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.borderLighter.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppTheme.brandPurple, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
    bool enabled = true,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF663399), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
    String? hint,
    String Function(String)? displayText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: (value == null || value.isEmpty) ? null : value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint ?? 'Select $label',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF663399), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                displayText != null ? displayText(item) : item,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Text(
                displayText != null ? displayText(item) : item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87),
              );
            }).toList();
          },
          onChanged: (newValue) {
            onChanged(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildExpandableSelector({
    required String label,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<String> options,
    required List<String> selected,
    required Function(String) onToggleItem,
    Color chipColor = AppTheme.brandPurple,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.borderLighter.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return InkWell(
                onTap: () => onToggleItem(option),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Color(0xFFD4C5E0), // from-[#d4c5e0]
                              Color(0xFFA89CB5), // to-[#a89cb5]
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppTheme.borderLighter.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected.map((item) {
              return Chip(
                label: Text(item),
                backgroundColor: chipColor.withOpacity(0.1),
                deleteIcon: Icon(Icons.close, size: 16, color: chipColor),
                onDeleted: () => onToggleItem(item),
                labelStyle: TextStyle(color: chipColor, fontSize: 12),
                side: BorderSide(color: chipColor.withOpacity(0.3)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showAdvanced = !_showAdvanced;
            });
          },
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.borderLighter.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Advanced Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.textBarelyVisible,
                ),
              ],
            ),
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 16),
          _buildSection(
            child: Column(
              children: [
                _buildToggleRow(
                  title: 'Telehealth available',
                  subtitle: 'Virtual appointments offered',
                  value: _telehealth,
                  onChanged: (value) {
                    setState(() {
                      _telehealth = value;
                    });
                  },
                ),
                const Divider(),
                _buildToggleRow(
                  title: 'Accepts pregnant patients',
                  subtitle: 'Prenatal care provided',
                  value: _acceptsPregnant,
                  onChanged: (value) {
                    setState(() {
                      _acceptsPregnant = value;
                    });
                  },
                ),
                const Divider(),
                _buildToggleRow(
                  title: 'Accepts newborns',
                  subtitle: 'Newborn care provided',
                  value: _acceptsNewborns,
                  onChanged: (value) {
                    setState(() {
                      _acceptsNewborns = value;
                    });
                  },
                ),
                const Divider(),
                _buildToggleRow(
                  title: 'Mama Approved™ only',
                  subtitle: 'Community-verified providers',
                  value: _mamaApprovedOnly,
                  onChanged: (value) {
                    setState(() {
                      _mamaApprovedOnly = value;
                    });
                  },
                  showInfo: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Identity & Cultural Match',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tags are community-added and may be pending verification',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                _buildExpandableSelector(
                  label: _selectedIdentityTags.isEmpty
                      ? 'Select identity tags'
                      : '${_selectedIdentityTags.length} selected',
                  isExpanded: _showIdentityTags,
                  onToggle: () {
                    setState(() {
                      _showIdentityTags = !_showIdentityTags;
                    });
                  },
                  options: _identityTagOptions,
                  selected: _selectedIdentityTags,
                  onToggleItem: (item) => _toggleItem(
                    item,
                    _selectedIdentityTags,
                    (list) => _selectedIdentityTags = list,
                  ),
                  chipColor: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool showInfo = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showInfo) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline, size: 16, color: AppTheme.brandPurple),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.brandPurple,
        ),
      ],
    );
  }
}
