import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/provider_search_constants.dart';
import '../constants/provider_types.dart';
import '../cors/ui_theme.dart';
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
  final _focusNode = FocusNode();
  final _databaseService = DatabaseService();

  String _zip = '';
  String _city = '';
  int _radius = 10;
  String _healthPlan = ProviderSearchConstants.healthPlanAll;
  bool _loadingDefaults = true;

  List<String> _suggestions = [];
  Timer? _debounce;

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
      setState(() {
        _zip = zip;
        _city = city;
        _loadingDefaults = false;
      });
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

  void _runSearch() {
    final q = _queryController.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a provider type to search.'),
          backgroundColor: AppTheme.brandGold,
        ),
      );
      return;
    }
    if (_zip.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a ZIP code in your profile or use Expanded search.'),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
      return;
    }
    if (_city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We need a city — open Expanded search to enter it.'),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
      return;
    }

    final id = _resolveTypeId(q);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a provider type from the suggestions below.'),
          backgroundColor: AppTheme.brandGold,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProviderSearchResultsScreen(
          searchParams: {
            'zip': _zip,
            'city': _city,
            'radius': _radius,
            'healthPlan': _healthPlan,
            'providerTypeIds': [id],
            'specialties': <String>[],
            'includeNPI': true,
            'telehealth': false,
            'acceptsPregnant': true,
            'acceptsNewborns': false,
            'mamaApprovedOnly': false,
            'identityTags': <String>[],
            'languages': <String>[],
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
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProviderSearchEntryScreen(
          prefill: ProviderSearchPrefill(
            zip: _zip.isNotEmpty ? _zip : null,
            city: _city.isNotEmpty ? _city : null,
            radius: '$_radius',
            healthPlan: _healthPlan,
            providerTypeDisplayNames: types,
            includeNpi: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryParts = <String>[];
    if (_zip.length == 5) summaryParts.add('ZIP $_zip');
    summaryParts.add('$_radius mi');
    if (_city.isNotEmpty) summaryParts.add(_city);
    summaryParts.add(_healthPlan);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppTheme.newUiAppBar(context, title: 'Search providers'),
      body: _loadingDefaults
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    summaryParts.join(' · '),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search Ohio directory types (e.g. midwife, hospital).',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    elevation: 2,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(28),
                    child: TextField(
                      controller: _queryController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _runSearch(),
                      decoration: InputDecoration(
                        hintText: 'Type a provider type…',
                        prefixIcon:
                            Icon(Icons.search, color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: AppTheme.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: AppTheme.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: const BorderSide(
                            color: Color(0xFF663399),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._suggestions.map(
                    (s) => ListTile(
                      dense: true,
                      title: Text(s),
                      onTap: () => _applySuggestion(s),
                    ),
                  ),
                  if (_suggestions.isEmpty &&
                      _queryController.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No suggestions — you can still search or open expanded filters.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _runSearch,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF663399),
                      foregroundColor: AppTheme.brandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text('Search'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openExpanded,
                    icon: Icon(Icons.tune_rounded, color: AppTheme.brandPurple),
                    label: const Text('Expanded search (all filters)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.brandPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFD4C4EB)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
