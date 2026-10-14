import 'dart:convert';

import 'package:flutter/material.dart';

import '../widgets/feature_session_scope.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../constants/provider_search_constants.dart';
import '../services/database_service.dart';
import '../models/provider.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../widgets/mama_approved_community_badge.dart';
import 'add_provider_screen.dart';
import 'provider_profile_screen.dart';
import 'mama_approved_providers_screen.dart';
import 'provider_quick_search_screen.dart';
import 'provider_search_entry_screen.dart';

class ProviderSearchScreen extends StatefulWidget {
  const ProviderSearchScreen({super.key});

  @override
  State<ProviderSearchScreen> createState() => _ProviderSearchScreenState();
}

class _ProviderSearchScreenState extends State<ProviderSearchScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Provider> _reviewedProviders = [];
  bool _isLoadingProviders = true;

  String _hubZip = '';
  String _hubCity = '';
  bool _hubLocationLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviewedProviders();
    _loadHubLocationDefaults();
  }

  Future<void> _loadHubLocationDefaults() async {
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
      try {
        final r = await http
            .get(Uri.parse('https://api.zippopotam.us/us/$zip'))
            .timeout(const Duration(seconds: 6));
        if (r.statusCode == 200) {
          final j = json.decode(r.body) as Map<String, dynamic>;
          final places = j['places'] as List<dynamic>?;
          if (places != null && places.isNotEmpty) {
            city = (places.first as Map<String, dynamic>)['place name'] as String? ?? '';
          }
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _hubZip = zip;
        _hubCity = city;
        _hubLocationLoading = false;
      });
    }
  }

  void _openQuickSearch() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ProviderQuickSearchScreen(),
      ),
    );
  }

  void _openExpandedSearch() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProviderSearchEntryScreen(
          prefill: ProviderSearchPrefill(
            zip: _hubZip.length == 5 ? _hubZip : null,
            city: _hubCity.isNotEmpty ? _hubCity : null,
            radius: '10',
            healthPlan: ProviderSearchConstants.healthPlanAll,
            includeNpi: true,
          ),
        ),
      ),
    );
  }

  Future<void> _loadReviewedProviders() async {
    try {
      print('🔍 [ProviderSearch] Loading top-rated providers...');
      
      QuerySnapshot providersQuery;
      try {
        providersQuery = await FirebaseFirestore.instance
            .collection('providers')
            .where('reviewCount', isGreaterThan: 0)
            .orderBy('reviewCount', descending: true)
            .limit(20)
            .get();
      } catch (e) {
        print('⚠️ [ProviderSearch] Index error, falling back to in-memory sort: $e');
        providersQuery = await FirebaseFirestore.instance
            .collection('providers')
            .limit(100)
            .get();
      }
      
      print('✅ [ProviderSearch] Found ${providersQuery.docs.length} providers');
      
      final providers = <Provider>[];
      for (var doc in providersQuery.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          if (data['directoryHidden'] == true) continue;
          final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
          
          if (reviewCount > 0) {
            final provider = Provider.fromMap(data, id: doc.id);
            providers.add(provider);
          }
        } catch (e) {
          print('⚠️ [ProviderSearch] Error parsing provider ${doc.id}: $e');
        }
      }
      
      // Sort: community Mama Approved first, then by review count, then by rating
      providers.sort((a, b) {
        if (a.showsMamaApprovedBadge && !b.showsMamaApprovedBadge) {
          return -1;
        }
        if (!a.showsMamaApprovedBadge && b.showsMamaApprovedBadge) {
          return 1;
        }
        
        final countA = a.reviewCount ?? 0;
        final countB = b.reviewCount ?? 0;
        if (countA != countB) {
          return countB.compareTo(countA);
        }
        
        final ratingA = a.rating ?? 0.0;
        final ratingB = b.rating ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
      
      final topProviders = providers.take(10).toList();
      
      if (mounted) {
        setState(() {
          _reviewedProviders = topProviders;
          _isLoadingProviders = false;
        });
      }
    } catch (e, stackTrace) {
      print('⚠️ [ProviderSearch] Error loading reviewed providers: $e');
      print('⚠️ [ProviderSearch] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingProviders = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return FeatureSessionScope(
      feature: 'provider-search',
      entrySource: 'provider_search_home',
      child: Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (now scrolls with the content below)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location tag
                  DecoratedBox(
                    decoration: const ShapeDecoration(
                      color: AppTheme.surface,
                      shape: StadiumBorder(
                        side: BorderSide(color: AppTheme.borderWarm),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 6,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppTheme.brandPurple,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Ohio providers',
                            style: hearthCaptionStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Find your care team',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Trusted providers who listen and support you',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 6),
                  if (_hubLocationLoading)
                    Text(
                      'Loading your area…',
                      style: hearthCaptionStyle,
                    )
                  else
                    Text(
                      _hubZip.length == 5
                          ? 'Searching near $_hubZip · 10 mi · ${ProviderSearchConstants.healthPlanAll}'
                          : 'Add ZIP in your profile for fastest search · ${ProviderSearchConstants.healthPlanAll}',
                      style: hearthCaptionStyle,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Looks like a search field but opens the quick search screen.
                  Material(
                    color: AppTheme.surface,
                    shape: const StadiumBorder(
                      side: BorderSide(color: AppTheme.borderWarm),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _openQuickSearch,
                      child: SizedBox(
                        height: 54,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: AppTheme.brandPurple, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Search provider directories…',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.sansFamily,
                                    color: AppTheme.textMuted,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: HearthButton.text(
                      label: 'Expanded search',
                      icon: Icons.tune_rounded,
                      onPressed: _openExpandedSearch,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content (scrolls together with the header above)
            _isLoadingProviders
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _reviewedProviders.isEmpty
                    ? _buildEmptyState()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Mama Approved™ — community reviews (not insurer “verified”)
                              HearthFeatureCard(
                                padding: const EdgeInsets.all(16),
                                onTap: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          const MamaApprovedProvidersScreen(),
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'See Mama Approved™ providers',
                                            style: hearthCardTitleStyle,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            Provider.mamaApprovedCriteriaText,
                                            style: hearthCaptionStyle.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: AppTheme.brandPurple,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Provider Cards
                              ..._reviewedProviders.map((provider) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildProviderCard(provider),
                                );
                              }).toList(),

                              const SizedBox(height: 8),

                              // Add Provider Button
                              HearthCard(
                                padding: const EdgeInsets.all(20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddProviderScreen(),
                                    ),
                                  ).then((_) {
                                    // Reload providers after adding a new one
                                    _loadReviewedProviders();
                                  });
                                },
                                child: Row(
                                  children: [
                                    const HearthIconChip(Icons.add),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Add a Provider',
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Can\'t find your provider? Add them to help others',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppTheme.textSecondary,
                                      size: 20,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HearthIconChip(Icons.search, size: 64, iconSize: 30),
            const SizedBox(height: 20),
            Text(
              'Find Your Care Team',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Search for trusted providers reviewed by mothers like you',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            HearthButton.primary(
              label: 'Start Searching',
              onPressed: _openQuickSearch,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(Provider provider) {
    // Get specialties from the specialties array
    final specialties = provider.specialties.isNotEmpty
        ? provider.specialties
        : (provider.specialty != null ? [provider.specialty!] : []);

    // Get location info
    final location = provider.locations.isNotEmpty ? provider.locations.first : null;
    final locationText = location != null
        ? '${location.city}, ${location.state}'
        : 'Location not available';

    return HearthCard(
        padding: const EdgeInsets.all(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderProfileScreen(
                provider: provider,
                providerId: provider.id,
              ),
            ),
          );
        },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Badges Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name uses the full width; the badge sits on its own
                        // line below so it never squeezes the name.
                        Text(
                          provider.primaryDisplayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (provider.showsMamaApprovedBadge) ...[
                          const SizedBox(height: 8),
                          const MamaApprovedCommunityBadge(compact: true),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          provider.specialty ?? 'Provider',
                          style: hearthCardBodyStyle,
                        ),
                        Builder(
                          builder: (context) {
                            final legal = provider.name.trim();
                            final pr = (provider.practiceName ?? '').trim();
                            String? alt;
                            if (pr.isNotEmpty &&
                                pr.toLowerCase() !=
                                    provider.primaryDisplayName
                                        .toLowerCase()) {
                              alt = pr;
                            } else if (legal.isNotEmpty &&
                                legal.toLowerCase() !=
                                    provider.primaryDisplayName
                                        .toLowerCase()) {
                              alt = legal;
                            }
                            if (alt == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(alt, style: hearthCaptionStyle),
                            );
                          },
                        ),
                        if (provider.healthCoverageLabel != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.health_and_safety_outlined,
                                size: 16,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Accepted health: ${provider.healthCoverageLabel}',
                                  style: hearthCaptionStyle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Rating and Distance
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 18, color: AppTheme.brandGold),
                  const SizedBox(width: 4),
                  Text(
                    provider.rating != null
                        ? Provider.formatAverageRating(provider.rating!)
                        : 'N/A',
                    style: hearthCardBodyStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  Text(
                    ' (${provider.reviewCount ?? 0})',
                    style: hearthCardBodyStyle.copyWith(color: AppTheme.textMuted),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationText,
                      style: hearthCardBodyStyle.copyWith(color: AppTheme.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Accepting Badge
              if (provider.acceptingNewPatients == true)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: HearthTag('Accepting new patients', icon: Icons.check),
                ),

              // Specialties Tags
              if (specialties.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: specialties.take(3).map((specialty) {
                    return _SpecialtyPill(specialty);
                  }).toList(),
                ),
            ],
          ),
    );
  }
}

/// Outlined pill for a provider specialty.
class _SpecialtyPill extends StatelessWidget {
  const _SpecialtyPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: AppTheme.ground,
        shape: StadiumBorder(side: BorderSide(color: AppTheme.borderWarm)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
        child: Text(
          text,
          style: hearthCaptionStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
