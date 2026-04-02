import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/provider_search_constants.dart';
import '../constants/provider_types.dart';
import '../cors/ui_theme.dart';
import '../services/database_service.dart';
import 'provider_search_entry_screen.dart';
import 'provider_search_results_screen.dart';

enum _QuickSearchKind { providerType, providerName }

/// Google-style quick search: type vs name, autocomplete, then results or expanded form.
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

  _QuickSearchKind _kind = _QuickSearchKind.providerType;

  String _zip = '';
  String _city = '';
  int _radius = 10;
  String _healthPlan = ProviderSearchConstants.healthPlanAll;
  bool _loadingDefaults = true;
  bool _searchingFirestoreNames = false;

  List<String> _suggestions = [];
  Timer? _debounce;
  List<_ProviderDirectorySuggest> _providerSuggests = [];

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

    if (_kind == _QuickSearchKind.providerType) {
      if (q.isEmpty) {
        setState(() {
          _suggestions = _allTypeNames.take(14).toList();
          _providerSuggests = [];
        });
        return;
      }
      final matches = _allTypeNames
          .where((n) => n.toLowerCase().contains(q))
          .take(16)
          .toList();
      setState(() {
        _suggestions = matches;
        _providerSuggests = [];
      });
      return;
    }

    // Name mode: suggestions from Firestore `providers` (practiceName-first schema).
    setState(() => _suggestions = []);
    if (raw.isEmpty) {
      setState(() {
        _providerSuggests = [];
        _searchingFirestoreNames = false;
      });
      return;
    }
    _fetchProviderDirectorySuggestions(raw);
  }

  static String? _subtitleForDoc(Map<String, dynamic> data) {
    final spec = (data['specialty'] as String?)?.trim();
    if (spec != null && spec.isNotEmpty) return spec;
    final list = data['specialties'] as List<dynamic>?;
    if (list == null || list.isEmpty) return null;
    for (final e in list) {
      final s = e.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static _ProviderDirectorySuggest? _suggestFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final practice = (data['practiceName'] as String?)?.trim() ?? '';
    final name = (data['name'] as String?)?.trim() ?? '';
    final displayTitle = practice.isNotEmpty ? practice : name;
    if (displayTitle.isEmpty) return null;
    final searchTerm = practice.isNotEmpty ? practice : name;
    if (searchTerm.isEmpty) return null;
    return _ProviderDirectorySuggest(
      displayTitle: displayTitle,
      subtitle: _subtitleForDoc(data),
      searchTerm: searchTerm,
    );
  }

  Future<void> _fetchProviderDirectorySuggestions(String prefix) async {
    setState(() => _searchingFirestoreNames = true);
    final seen = <String>{};
    final out = <_ProviderDirectorySuggest>[];

    void addDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      if (seen.contains(doc.id)) return;
      final s = _suggestFromDoc(doc);
      if (s == null) return;
      seen.add(doc.id);
      out.add(s);
    }

    try {
      final fs = FirebaseFirestore.instance;
      final col = fs.collection('providers');

      try {
        final s1 = await col
            .orderBy('practiceName')
            .startAt([prefix])
            .endAt(['$prefix\uf8ff'])
            .limit(14)
            .get();
        for (final d in s1.docs) {
          addDoc(d);
        }
      } catch (_) {}

      try {
        final s2 = await col
            .orderBy('name')
            .startAt([prefix])
            .endAt(['$prefix\uf8ff'])
            .limit(14)
            .get();
        for (final d in s2.docs) {
          addDoc(d);
        }
      } catch (_) {}

      if (out.length < 8) {
        final low = prefix.toLowerCase();
        final broad = await col.limit(280).get();
        final extra = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        for (final d in broad.docs) {
          if (seen.contains(d.id)) continue;
          final m = d.data();
          final p = (m['practiceName'] as String? ?? '').toLowerCase();
          final n = (m['name'] as String? ?? '').toLowerCase();
          if (p.contains(low) || n.contains(low)) extra.add(d);
        }
        extra.sort((a, b) {
          final ta = _suggestFromDoc(a)?.displayTitle ?? '';
          final tb = _suggestFromDoc(b)?.displayTitle ?? '';
          return ta.toLowerCase().compareTo(tb.toLowerCase());
        });
        for (final d in extra) {
          addDoc(d);
          if (out.length >= 22) break;
        }
      }

      out.sort(
        (a, b) => a.displayTitle.toLowerCase().compareTo(
              b.displayTitle.toLowerCase(),
            ),
      );
      final trimmed = out.take(20).toList();

      if (!mounted) return;
      setState(() {
        _providerSuggests = trimmed;
        _searchingFirestoreNames = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _providerSuggests = [];
          _searchingFirestoreNames = false;
        });
      }
    }
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

  void _applyProviderDirectorySuggest(_ProviderDirectorySuggest s) {
    final t = s.searchTerm;
    _queryController.text = t;
    _queryController.selection = TextSelection.collapsed(offset: t.length);
    setState(() {});
    _refreshSuggestions();
  }

  void _runSearch() {
    final q = _queryController.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a provider type or name to search.'),
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

    if (_kind == _QuickSearchKind.providerType) {
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
            'providerTypeIds': List<String>.from(ProviderTypes.mvpTypes),
            'specialties': <String>[],
            'includeNPI': true,
            'telehealth': false,
            'acceptsPregnant': true,
            'acceptsNewborns': false,
            'mamaApprovedOnly': false,
            'identityTags': <String>[],
            'languages': <String>[],
            'nameContains': q,
          },
        ),
      ),
    );
  }

  void _openExpanded() {
    final q = _queryController.text.trim();
    List<String>? types;
    if (_kind == _QuickSearchKind.providerType && q.isNotEmpty) {
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
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWarm,
        elevation: 0,
        foregroundColor: AppTheme.textSecondary,
        title: const Text(
          'Search providers',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
        ),
      ),
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
                  SegmentedButton<_QuickSearchKind>(
                    segments: const [
                      ButtonSegment(
                        value: _QuickSearchKind.providerType,
                        label: Text('Provider type'),
                        icon: Icon(Icons.category_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: _QuickSearchKind.providerName,
                        label: Text('Provider name'),
                        icon: Icon(Icons.person_search_outlined, size: 18),
                      ),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) {
                      setState(() {
                        _kind = s.first;
                        _suggestions = [];
                        _providerSuggests = [];
                      });
                      _refreshSuggestions();
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _kind == _QuickSearchKind.providerType
                        ? 'Search Ohio directory types (e.g. midwife, hospital).'
                        : 'Search by practice or provider name; we match against results near you.',
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
                        hintText: _kind == _QuickSearchKind.providerType
                            ? 'Type a provider type…'
                            : 'Type a name…',
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
                  const SizedBox(height: 8),
                  if (_kind == _QuickSearchKind.providerName &&
                      _searchingFirestoreNames)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Looking up names…',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textBarelyVisible,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_kind == _QuickSearchKind.providerName &&
                      _queryController.text.trim().isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Start typing to see practices from the directory.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (_kind == _QuickSearchKind.providerName &&
                      _providerSuggests.isNotEmpty) ...[
                    ..._providerSuggests.map(
                      (s) => ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.local_hospital_outlined,
                          size: 20,
                          color: AppTheme.brandPurple,
                        ),
                        title: Text(s.displayTitle),
                        subtitle: s.subtitle != null
                            ? Text(
                                s.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () => _applyProviderDirectorySuggest(s),
                      ),
                    ),
                  ],
                  if (_kind == _QuickSearchKind.providerType)
                    ..._suggestions.map(
                      (s) => ListTile(
                        dense: true,
                        title: Text(s),
                        onTap: () => _applySuggestion(s),
                      ),
                    ),
                  if (_kind == _QuickSearchKind.providerType &&
                      _suggestions.isEmpty &&
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
                  if (_kind == _QuickSearchKind.providerName &&
                      !_searchingFirestoreNames &&
                      _queryController.text.trim().isNotEmpty &&
                      _providerSuggests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No directory matches — you can still run search or use expanded filters.',
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

class _ProviderDirectorySuggest {
  const _ProviderDirectorySuggest({
    required this.displayTitle,
    this.subtitle,
    required this.searchTerm,
  });

  final String displayTitle;
  final String? subtitle;
  final String searchTerm;
}
