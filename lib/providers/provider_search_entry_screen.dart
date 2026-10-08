import 'package:flutter/material.dart';

import '../widgets/feature_session_scope.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/provider_types.dart';
import '../constants/provider_search_constants.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import 'add_provider_screen.dart';
import 'provider_search_results_screen.dart';

/// Optional values when opening expanded search from quick search.
class ProviderSearchPrefill {
  final String? zip;
  final String? city;
  final String? radius;
  final String? healthPlan;
  final List<String>? providerTypeDisplayNames;
  final List<String>? specialties;
  final bool? includeNpi;
  /// Labels matching expanded search identity / cultural chips.
  final List<String>? identityTagLabels;
  final List<String>? languages;
  final String? specialtyQuery;
  final bool? mamaApprovedOnly;

  const ProviderSearchPrefill({
    this.zip,
    this.city,
    this.radius,
    this.healthPlan,
    this.providerTypeDisplayNames,
    this.specialties,
    this.includeNpi,
    this.identityTagLabels,
    this.languages,
    this.specialtyQuery,
    this.mamaApprovedOnly,
  });
}

class ProviderSearchEntryScreen extends StatefulWidget {
  final ProviderSearchPrefill? prefill;

  const ProviderSearchEntryScreen({super.key, this.prefill});

  @override
  State<ProviderSearchEntryScreen> createState() =>
      _ProviderSearchEntryScreenState();
}

class _ProviderSearchEntryScreenState extends State<ProviderSearchEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _zipController = TextEditingController();
  final _cityController = TextEditingController();
  final _providerTypeQueryController = TextEditingController();
  final _specialtyQueryController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _radius = '10';
  String _healthPlan = ProviderSearchConstants.healthPlanAll;
  bool _includeNPI = false;
  bool _showAdvanced = false;
  bool _hasLoadedProfile = false;
  /// Set once the user changes these fields, so the async profile autofill
  /// (which can land after the screen is interactive) never overwrites
  /// what they picked.
  bool _userPickedPlan = false;
  bool _userPickedTypes = false;

  List<String> _selectedProviderTypes = [];
  List<String> _selectedSpecialties = [];
  List<String> _selectedIdentityTags = [];
  List<String> _selectedLanguages = [];

  bool _showIdentityTags = false;

  // Advanced filters - Pregnancy-Smart only
  bool _telehealth = false;
  bool _acceptsPregnant = true;
  bool _acceptsNewborns = false;
  bool _mamaApprovedOnly = false;

  final List<String> _healthPlans = [
    ProviderSearchConstants.healthPlanAll,
    'Buckeye',
    'CareSource',
    'Molina',
    'UnitedHealthcare',
    'Anthem',
    'Aetna',
    ProviderSearchConstants.healthPlanNotListed,
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
    final p = widget.prefill;
    if (p != null) {
      if (p.zip != null && p.zip!.isNotEmpty) {
        _zipController.text = p.zip!;
      }
      if (p.city != null && p.city!.isNotEmpty) {
        _cityController.text = p.city!;
      }
      if (p.radius != null && p.radius!.isNotEmpty) {
        _radius = p.radius!;
      }
      if (p.healthPlan != null && p.healthPlan!.isNotEmpty) {
        _healthPlan = p.healthPlan!;
      }
      if (p.providerTypeDisplayNames != null &&
          p.providerTypeDisplayNames!.isNotEmpty) {
        _selectedProviderTypes =
            List<String>.from(p.providerTypeDisplayNames!);
      }
      if (p.specialties != null && p.specialties!.isNotEmpty) {
        _selectedSpecialties = List<String>.from(p.specialties!);
      }
      if (p.includeNpi != null) {
        _includeNPI = p.includeNpi!;
      }
      if (p.identityTagLabels != null && p.identityTagLabels!.isNotEmpty) {
        _selectedIdentityTags = List<String>.from(p.identityTagLabels!);
      }
      if (p.languages != null && p.languages!.isNotEmpty) {
        _selectedLanguages = List<String>.from(p.languages!);
      }
      if (p.specialtyQuery != null && p.specialtyQuery!.trim().isNotEmpty) {
        _specialtyQueryController.text = p.specialtyQuery!.trim();
      }
      if (p.mamaApprovedOnly != null) {
        _mamaApprovedOnly = p.mamaApprovedOnly!;
      }
    }
    _trackScreenView();
    _loadUserProfileForAutofill();
  }

  Future<void> _trackScreenView() async {
    try {
      final analytics = AnalyticsService();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProfile = await _databaseService.getUserProfile(userId);
        await analytics.logScreenView(
          screenName: 'provider_search_entry',
          feature: 'provider-search',
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking provider search entry screen view: $e');
    }
  }

  @override
  void dispose() {
    _zipController.dispose();
    _cityController.dispose();
    _providerTypeQueryController.dispose();
    _specialtyQueryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfileForAutofill() async {
    if (_hasLoadedProfile) return; // Only load once

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Values passed in via [ProviderSearchPrefill] (from quick search or the
    // Find Your Care hub) are the user's current choices — profile autofill
    // must not silently overwrite them.
    final p = widget.prefill;
    final prefilledPlan = p?.healthPlan != null && p!.healthPlan!.isNotEmpty;
    final prefilledTypes = p?.providerTypeDisplayNames?.isNotEmpty == true;
    final prefilledTags = p?.identityTagLabels?.isNotEmpty == true;
    final prefilledLanguages = p?.languages?.isNotEmpty == true;

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

          // Map insurance type to health plan (overrides default "All plans" when known)
          final mappedPlan = _mapInsuranceToHealthPlan(profile.insuranceType);
          if (mappedPlan.isNotEmpty && !prefilledPlan && !_userPickedPlan) {
            _healthPlan = mappedPlan;
          }

          // Map provider preferences to identity tags
          if (profile.providerPreferences.isNotEmpty && !prefilledTags) {
            _selectedIdentityTags = _mapPreferencesToIdentityTags(profile.providerPreferences);
          }

          // Map language preference to languages
          if (!prefilledLanguages &&
              profile.languagePreference != null &&
              profile.languagePreference!.isNotEmpty) {
            final mappedLanguage = _mapLanguagePreference(profile.languagePreference!);
            if (mappedLanguage != null && !_selectedLanguages.contains(mappedLanguage)) {
              _selectedLanguages = [mappedLanguage];
            }
          }

          // Map birth preference to provider types
          if (!prefilledTypes &&
              !_userPickedTypes &&
              profile.birthPreference != null &&
              profile.birthPreference!.isNotEmpty) {
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
    // Provider type is an optional filter, not a search requirement — the
    // search functions as a universal search and returns matching results
    // regardless of provider type.
    return _zipController.text.length == 5 &&
        _cityController.text.isNotEmpty &&
        _healthPlan.isNotEmpty;
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

  Future<void> _handleSearch() async {
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

    // Universal search: when no provider type is selected (or none mapped to a
    // valid ID), fall back to the core set of provider types so the search
    // still returns matching results regardless of type. The backend requires
    // at least one provider type, so we never send an empty list.
    if (providerTypeIds.isEmpty) {
      providerTypeIds.addAll(ProviderTypes.mvpTypes);
      print('🔍 [SearchEntry] No type selected — universal search using mvpTypes: $providerTypeIds');
    }

    print('🔍 [SearchEntry] Final provider type IDs: $providerTypeIds');

    // Track provider search initiation
    try {
      final analytics = AnalyticsService();
      final databaseService = DatabaseService();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProfile = await databaseService.getUserProfile(userId);
        await analytics.logProviderSearchInitiated(
          searchRadius: int.parse(_radius).toDouble(),
          providerType: providerTypeIds.isNotEmpty ? providerTypeIds.first : null,
          insuranceFilter: _healthPlan.isNotEmpty ? _healthPlan : null,
          telehealth: _telehealth,
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking provider search: $e');
    }

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
    return FeatureSessionScope(
      feature: 'provider-search',
      entrySource: 'provider_search_entry',
      child: Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: Column(
          children: [
            HearthPushedHeader(
              title: 'Find your care team',
              subtitle: 'Trusted providers reviewed by mothers like you',
              onBack: () => Navigator.pop(context),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Location Section
                      _buildSection(
                        title: 'Location',
                        icon: Icons.location_on_outlined,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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

                      _buildAddProviderCallout(),

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
                                  _userPickedPlan = true;
                                  _healthPlan = value ?? '';
                                });
                              },
                              hint: 'Select your health plan',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _healthPlan == ProviderSearchConstants.healthPlanAll ||
                                      _healthPlan ==
                                          ProviderSearchConstants
                                              .healthPlanNotListed
                                  ? 'We\'ll search Ohio Medicaid with a general plan; turn on the national list below if you want NPI results too.'
                                  : 'Needed for the Ohio Medicaid directory.',
                              style: hearthCaptionStyle,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceInset,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.fieldRadius),
                                border: Border.all(color: AppTheme.borderWarm),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _includeNPI,
                                    onChanged: (value) {
                                      setState(() {
                                        _includeNPI = value ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Include the national provider list (NPI)',
                                            style: TextStyle(
                                              fontFamily: AppTheme.sansFamily,
                                              fontSize: 15,
                                              height: 22 / 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Adds more providers beyond the Ohio Medicaid directory',
                                            style: hearthCaptionStyle,
                                          ),
                                        ],
                                      ),
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
                        title: 'Provider Type (Optional)',
                        child: _buildTypingMultiSelect(
                          helperText:
                              'Optional. Leave blank for all types, or type a word like midwife or doula and tap to add.',
                          hintText: 'Type to filter provider types…',
                          queryController: _providerTypeQueryController,
                          allOptions: () {
                            final names = ProviderTypes.getAllTypes()
                                .map((t) => t['name']!)
                                .toList();
                            names.sort(
                              (a, b) =>
                                  a.toLowerCase().compareTo(b.toLowerCase()),
                            );
                            return names;
                          }(),
                          selected: _selectedProviderTypes,
                          onToggleItem: (item) => _toggleItem(
                            item,
                            _selectedProviderTypes,
                            (list) {
                              _userPickedTypes = true;
                              _selectedProviderTypes = list;
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Specialty
                      _buildSection(
                        title: 'Specialty (Optional)',
                        child: _buildTypingMultiSelect(
                          helperText:
                              'Optional: type a few letters to narrow specialties, then tap to add.',
                          hintText: 'Type to filter specialties…',
                          queryController: _specialtyQueryController,
                          allOptions: () {
                            final s = List<String>.from(Specialties.specialties);
                            s.sort(
                              (a, b) =>
                                  a.toLowerCase().compareTo(b.toLowerCase()),
                            );
                            return s;
                          }(),
                          selected: _selectedSpecialties,
                          onToggleItem: (item) => _toggleItem(
                            item,
                            _selectedSpecialties,
                            (list) => _selectedSpecialties = list,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Prominent Mama Approved™ filter (community trust)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: HearthFeatureCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            // The theme's off track blends into the tint card.
                            inactiveTrackColor: AppTheme.sheetHandle,
                            value: _mamaApprovedOnly,
                            onChanged: (v) =>
                                setState(() => _mamaApprovedOnly = v),
                            title: const Row(
                              children: [
                                Icon(Icons.favorite_border,
                                    size: 18, color: AppTheme.brandPurple),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Mama Approved™ only',
                                    style: hearthCardTitleStyle,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                '3+ reviews averaging 4 stars or higher from '
                                'moms in our community.',
                                style: TextStyle(
                                  fontFamily: AppTheme.sansFamily,
                                  fontSize: 13,
                                  height: 18 / 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Advanced Filters
                      _buildAdvancedFilters(),

                      const SizedBox(height: 24),

                      HearthButton.primary(
                        label: 'Search Providers',
                        icon: Icons.search,
                        onPressed: _canSearch ? _handleSearch : null,
                      ),

                      const SizedBox(height: 12),

                      HearthButton.secondary(
                        label: 'Still missing? Add your provider to the directory',
                        icon: Icons.person_add_alt_outlined,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const AddProviderScreen(),
                            ),
                          );
                        },
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

  /// Field label in ink, with the purple required star.
  Widget _buildFieldLabel(String label, {bool required = false}) {
    final style = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(color: AppTheme.ink);
    return Row(
      children: [
        Flexible(child: Text(label, style: style)),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: style?.copyWith(color: AppTheme.brandPurple),
          ),
        ],
      ],
    );
  }

  /// Removable chip for a picked item: warm tint with the purple outline.
  Widget _buildSelectedChip(String item, VoidCallback onRemove) {
    return Chip(
      label: Text(item),
      backgroundColor: AppTheme.tintWarm,
      deleteIcon: const Icon(Icons.close, size: 18, color: AppTheme.brandPurple),
      onDeleted: onRemove,
      labelStyle: const TextStyle(
        fontFamily: AppTheme.sansFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.brandPurple,
      ),
      side: const BorderSide(color: AppTheme.brandPurple, width: 2),
      shape: const StadiumBorder(),
    );
  }

  Widget _buildSection({
    required Widget child,
    String? title,
    IconData? icon,
    bool markTitleRequired = false,
  }) {
    final headingStyle = Theme.of(context).textTheme.headlineMedium;
    return HearthCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppTheme.brandPurple, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: headingStyle,
                  ),
                ),
                if (markTitleRequired)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '*',
                      style: headingStyle?.copyWith(color: AppTheme.brandPurple),
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

  Widget _buildAddProviderCallout() {
    return HearthFeatureCard(
      padding: const EdgeInsets.all(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const AddProviderScreen(),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HearthIconChip(
            Icons.favorite_border,
            tone: HearthChipTone.surface,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Can\'t find your provider?',
                  style: hearthCardTitleStyle,
                ),
                SizedBox(height: 6),
                Text(
                  'Add them here. It helps other mamas discover care that worked for you.',
                  style: hearthCardBodyStyle,
                ),
                SizedBox(height: 10),
                Text(
                  'Add a provider →',
                  style: TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandPurple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 13),
            child: Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingMultiSelect({
    required String helperText,
    required String hintText,
    required TextEditingController queryController,
    required List<String> allOptions,
    required List<String> selected,
    required void Function(String) onToggleItem,
  }) {
    final q = queryController.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? allOptions.take(18).toList()
        : allOptions
            .where((o) => o.toLowerCase().contains(q))
            .take(36)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          helperText,
          style: hearthCaptionStyle,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: queryController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hintText,
            fillColor: AppTheme.surfaceInset,
          ),
        ),
        const SizedBox(height: 12),
        if (q.isEmpty && allOptions.length > 18)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Showing a few common types. Type to see more.',
              style: hearthCaptionStyle,
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filtered.map((option) {
            final isSelected = selected.contains(option);
            return HearthChoiceChip(
              label: option,
              selected: isSelected,
              icon: isSelected ? Icons.check : null,
              onSelected: () => onToggleItem(option),
            );
          }).toList(),
        ),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No matches. Try different words.',
              style: hearthCaptionStyle,
            ),
          ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Selected',
            style: TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected
                .map((item) => _buildSelectedChip(item, () => onToggleItem(item)))
                .toList(),
          ),
        ],
      ],
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
        _buildFieldLabel(label, required: required),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: TextStyle(
            fontFamily: AppTheme.sansFamily,
            fontSize: 15,
            height: 22 / 15,
            color: enabled ? AppTheme.ink : AppTheme.textMuted,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            // Fields inside a card use the inset fill.
            fillColor: AppTheme.surfaceInset,
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
    const valueStyle = TextStyle(
      fontFamily: AppTheme.sansFamily,
      fontSize: 15,
      height: 22 / 15,
      color: AppTheme.ink,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, required: required),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: (value == null || value.isEmpty) ? null : value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppTheme.textSecondary),
          dropdownColor: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
          style: valueStyle,
          decoration: InputDecoration(
            hintText: hint ?? 'Select $label',
            fillColor: AppTheme.surfaceInset,
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
                style: valueStyle,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drawn like a dropdown field so it reads as one.
        Material(
          color: AppTheme.surfaceInset,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
            side: const BorderSide(color: AppTheme.borderWarm),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onToggle,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 15,
                        height: 22 / 15,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
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
              return HearthChoiceChip(
                label: option,
                selected: isSelected,
                icon: isSelected ? Icons.check : null,
                onSelected: () => onToggleItem(option),
              );
            }).toList(),
          ),
        ],
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected
                .map((item) => _buildSelectedChip(item, () => onToggleItem(item)))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HearthCard(
          onTap: () {
            setState(() {
              _showAdvanced = !_showAdvanced;
            });
          },
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Advanced Filters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.brandPurple,
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
                const Divider(height: 32),
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
                const Divider(height: 32),
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
                  style: hearthCaptionStyle,
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
    VoidCallback? onInfoTap,
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
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 15,
                        height: 22 / 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  if (showInfo) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onInfoTap,
                      borderRadius: BorderRadius.circular(22),
                      child: const Padding(
                        padding: EdgeInsets.all(13),
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: hearthCaptionStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
