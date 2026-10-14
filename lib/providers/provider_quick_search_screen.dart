import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/provider_search_constants.dart';
import '../constants/provider_types.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../services/database_service.dart';
import 'provider_search_entry_screen.dart';
import 'provider_search_results_screen.dart';

/// Quick search by Ohio directory provider type, then results or expanded form.
class ProviderQuickSearchScreen extends StatefulWidget {
  const ProviderQuickSearchScreen({super.key});

  @override
  State<ProviderQuickSearchScreen> createState() =>
      _ProviderQuickSearchScreenState();
}

class _ProviderQuickSearchScreenState extends State<ProviderQuickSearchScreen> {
  final _queryController = TextEditingController();
  final _zipController = TextEditingController();
  final _cityController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _focusNode = FocusNode();
  final _databaseService = DatabaseService();

  int _radius = 10;
  String _healthPlan = ProviderSearchConstants.healthPlanAll;
  bool _loadingDefaults = true;
  bool _mamaApprovedOnly = false;
  final List<String> _selectedIdentityTags = [];
  final List<String> _selectedLanguages = [];

  List<String> _suggestions = [];
  Timer? _debounce;

  static const List<String> _healthPlans = [
    ProviderSearchConstants.healthPlanAll,
    'Buckeye',
    'CareSource',
    'Molina',
    'UnitedHealthcare',
    'Anthem',
    'Aetna',
    ProviderSearchConstants.healthPlanNotListed,
  ];

  static const List<String> _radiusOptions = ['3', '5', '10', '15', '25', '50'];

  /// Race/ethnicity, language, and cultural tags (aligned with expanded search).
  static const List<String> _identityTagOptions = [
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

  static const List<String> _languageOptions = [
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

  List<String> get _allTypeNames {
    final names = ProviderTypes.getAllTypes().map((e) => e['name']!).toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    _loadDefaults();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _zipController.dispose();
    _cityController.dispose();
    _specialtyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    String zip = '';
    String city = '';

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final profile = await _databaseService.getUserProfile(uid);
        if (profile != null) {
          zip = profile.zipCode.trim();
          city = (profile.city ?? '').trim();
        }
      } catch (_) {}
    }

    if (zip.length == 5 && city.isEmpty) {
      city = await _cityFromZip(zip) ?? '';
    }

    if (mounted) {
      _zipController.text = zip;
      _cityController.text = city;
      setState(() => _loadingDefaults = false);
    }
  }

  Future<String?> _cityFromZip(String zip) async {
    try {
      final r = await http
          .get(Uri.parse('https://api.zippopotam.us/us/$zip'))
          .timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return null;
      final j = json.decode(r.body) as Map<String, dynamic>;
      final places = j['places'] as List<dynamic>?;
      if (places == null || places.isEmpty) return null;
      final first = places.first as Map<String, dynamic>;
      return first['place name'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), _refreshSuggestions);
  }

  void _refreshSuggestions() {
    final raw = _queryController.text.trim();
    final q = raw.toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _suggestions = _allTypeNames.take(14).toList();
      });
      return;
    }
    final matches = _allTypeNames
        .where((n) => n.toLowerCase().contains(q))
        .take(16)
        .toList();
    setState(() {
      _suggestions = matches;
    });
  }

  String? _resolveTypeId(String input) {
    final t = input.trim();
    if (t.isEmpty) return null;
    final byExact = ProviderTypes.getTypeId(t);
    if (byExact != null) return byExact;
    final lower = t.toLowerCase();
    for (final n in _allTypeNames) {
      if (n.toLowerCase() == lower) return ProviderTypes.getTypeId(n);
    }
    String? bestId;
    int bestLen = 9999;
    for (final n in _allTypeNames) {
      if (n.toLowerCase().contains(lower)) {
        if (n.length < bestLen) {
          bestLen = n.length;
          bestId = ProviderTypes.getTypeId(n);
        }
      }
    }
    return bestId;
  }

  void _applySuggestion(String text) {
    _queryController.text = text;
    _queryController.selection = TextSelection.collapsed(offset: text.length);
    setState(() {});
    _refreshSuggestions();
  }

  void _toggleIdentity(String label) {
    setState(() {
      if (_selectedIdentityTags.contains(label)) {
        _selectedIdentityTags.remove(label);
      } else {
        _selectedIdentityTags.add(label);
      }
    });
  }

  void _toggleLanguage(String label) {
    setState(() {
      if (_selectedLanguages.contains(label)) {
        _selectedLanguages.remove(label);
      } else {
        _selectedLanguages.add(label);
      }
    });
  }

  void _runSearch() {
    // Location is genuinely required for a directory search, but provider type
    // and specialty are NOT — this is a universal search.
    final zip = _zipController.text.trim();
    if (zip.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a 5-digit ZIP code.'),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
      return;
    }
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a city or open Expanded search.'),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
      return;
    }

    // Universal search: if the text matches a known provider type, filter by
    // it; otherwise treat the text as a name search across the core provider
    // types so results still come back regardless of type. Empty text = search
    // everything nearby.
    final q = _queryController.text.trim();
    final id = _resolveTypeId(q);
    final List<String> providerTypeIds =
        id != null ? [id] : List<String>.from(ProviderTypes.mvpTypes);
    final String? nameContains = (id == null && q.isNotEmpty) ? q : null;

    final spec = _specialtyController.text.trim();
    final specialties = spec.isEmpty ? <String>[] : <String>[spec];

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProviderSearchResultsScreen(
          searchParams: {
            'zip': zip,
            'city': city,
            'radius': _radius,
            'healthPlan': _healthPlan,
            'providerTypeIds': providerTypeIds,
            'specialties': specialties,
            'nameContains': nameContains,
            'directoryQuery': q.isEmpty ? null : q,
            'includeNPI': true,
            'telehealth': false,
            'acceptsPregnant': true,
            'acceptsNewborns': false,
            'mamaApprovedOnly': _mamaApprovedOnly,
            'identityTags': List<String>.from(_selectedIdentityTags),
            'languages': List<String>.from(_selectedLanguages),
          },
        ),
      ),
    );
  }

  void _openExpanded() {
    final q = _queryController.text.trim();
    List<String>? types;
    if (q.isNotEmpty) {
      final id = _resolveTypeId(q);
      if (id != null) {
        final name = ProviderTypes.getDisplayName(id);
        if (name != null) types = [name];
      }
    }
    final zip = _zipController.text.trim();
    final city = _cityController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProviderSearchEntryScreen(
          prefill: ProviderSearchPrefill(
            zip: zip.length == 5 ? zip : null,
            city: city.isNotEmpty ? city : null,
            radius: '$_radius',
            healthPlan: _healthPlan,
            providerTypeDisplayNames: types,
            includeNpi: true,
            identityTagLabels: _selectedIdentityTags.isEmpty
                ? null
                : List<String>.from(_selectedIdentityTags),
            languages: _selectedLanguages.isEmpty
                ? null
                : List<String>.from(_selectedLanguages),
            specialtyQuery: _specialtyController.text.trim().isEmpty
                ? null
                : _specialtyController.text.trim(),
            mamaApprovedOnly: _mamaApprovedOnly,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zip = _zipController.text.trim();
    final city = _cityController.text.trim();
    final summaryParts = <String>[];
    if (zip.length == 5) summaryParts.add('ZIP $zip');
    summaryParts.add('$_radius mi');
    if (city.isNotEmpty) summaryParts.add(city);
    summaryParts.add(_healthPlan);
    if (_mamaApprovedOnly) summaryParts.add('Mama Approved');
    if (_selectedIdentityTags.isNotEmpty) {
      summaryParts.add('${_selectedIdentityTags.length} cultural tag(s)');
    }
    if (_selectedLanguages.isNotEmpty) {
      summaryParts.add('${_selectedLanguages.length} language(s)');
    }

    final labelStyle = Theme.of(context).textTheme.labelMedium;

    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: _loadingDefaults
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HearthPushedHeader(title: 'Search providers'),
                Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HearthPushedHeader(
                    title: 'Search providers',
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 16),
                  ),
                  Text(
                    summaryParts.join(' · '),
                    style: hearthCaptionStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search by provider name or type (both optional). Leave blank '
                    'to see everyone nearby.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          focusNode: _focusNode,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _runSearch(),
                          decoration: const InputDecoration(
                            hintText: 'Search by name or type (optional)…',
                            prefixIcon:
                                Icon(Icons.search, color: AppTheme.brandPurple),
                            // The main search field is a pill, like the hub's.
                            border: _pillBorder,
                            enabledBorder: _pillBorder,
                            focusedBorder: _pillFocusedBorder,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      HearthButton.primary(
                        label: 'Search',
                        onPressed: _runSearch,
                        expand: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Suggestions', style: labelStyle?.copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  if (_suggestions.isNotEmpty)
                    HearthCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < _suggestions.length; i++) ...[
                            if (i > 0)
                              const Divider(height: 1, thickness: 1, color: AppTheme.borderWarm),
                            InkWell(
                              onTap: () => _applySuggestion(_suggestions[i]),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 48),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 11,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _suggestions[i],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(color: AppTheme.ink),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (_suggestions.isEmpty &&
                      _queryController.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No suggestions. You can still search or open expanded filters.',
                        style: hearthCaptionStyle,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('ZIP', style: labelStyle),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _zipController,
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                counterText: '',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('City', style: labelStyle),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _cityController,
                              onChanged: (_) => setState(() {}),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Insurance / plan', style: labelStyle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _healthPlan,
                    icon: const Icon(Icons.expand_more, color: AppTheme.brandPurple),
                    items: _healthPlans
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _healthPlan = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Radius', style: labelStyle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: '$_radius',
                    icon: const Icon(Icons.expand_more, color: AppTheme.brandPurple),
                    items: _radiusOptions
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text('$r mi'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _radius = int.tryParse(v) ?? 10);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mama Approved™ only', style: hearthCardTitleStyle),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '3+ reviews averaging 4 stars or higher from moms in our community.',
                        style: hearthCaptionStyle,
                      ),
                    ),
                    value: _mamaApprovedOnly,
                    onChanged: (v) => setState(() => _mamaApprovedOnly = v),
                  ),
                  const SizedBox(height: 8),
                  Text('Specialty (optional)', style: labelStyle),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _specialtyController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'e.g. high-risk pregnancy',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      iconColor: AppTheme.brandPurple,
                      collapsedIconColor: AppTheme.brandPurple,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(
                        'Race/ethnicity, language & cultural tags',
                        style: labelStyle?.copyWith(color: AppTheme.ink),
                      ),
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Cultural / identity',
                            style: hearthCaptionStyle.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _identityTagOptions.map((label) {
                            final sel = _selectedIdentityTags.contains(label);
                            return HearthChoiceChip(
                              label: label,
                              selected: sel,
                              icon: sel ? Icons.check : null,
                              onSelected: () => _toggleIdentity(label),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Language',
                            style: hearthCaptionStyle.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _languageOptions.map((label) {
                            final sel = _selectedLanguages.contains(label);
                            return HearthChoiceChip(
                              label: label,
                              selected: sel,
                              icon: sel ? Icons.check : null,
                              onSelected: () => _toggleLanguage(label),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  HearthButton.secondary(
                    label: 'Expanded search (all filters)',
                    icon: Icons.tune_rounded,
                    onPressed: _openExpanded,
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

const OutlineInputBorder _pillBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(999)),
  borderSide: BorderSide(color: AppTheme.borderWarm),
);

const OutlineInputBorder _pillFocusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(999)),
  borderSide: BorderSide(color: AppTheme.brandPurple, width: 2),
);
