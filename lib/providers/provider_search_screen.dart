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
import '../widgets/mama_approved_community_badge.dart';
import 'add_provider_screen.dart';
import 'provider_profile_screen.dart';
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
          final reviewCount = data['reviewCount'] as int? ?? 0;
          
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
      backgroundColor: AppTheme.backgroundWarm,
      body: SafeArea(
        child: Column(
          children: [
            // Header (matching image exactly)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), // px-5 pt-4 pb-5
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with location tag
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundWarm,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Color(0xFF663399),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ohio providers',
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
                  const SizedBox(height: 16), // mb-4
                  // Title
                  Text(
                    'Find your care team',
                    style: TextStyle(
                      fontSize: 28, // text-3xl
                      fontWeight: FontWeight.w400, // font-normal
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8), // mb-2
                  // Subtitle
                  Text(
                    'Trusted providers who listen and support you',
                    style: TextStyle(
                      fontSize: 14, // text-sm
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300, // font-light
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_hubLocationLoading)
                    Text(
                      'Loading your area…',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textBarelyVisible,
                      ),
                    )
                  else
                    Text(
                      _hubZip.length == 5
                          ? 'Searching near $_hubZip · 10 mi · ${ProviderSearchConstants.healthPlanAll}'
                          : 'Add ZIP in your profile for fastest search · ${ProviderSearchConstants.healthPlanAll}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                        height: 1.35,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Material(
                    elevation: 3,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(32),
                    child: InkWell(
                      onTap: _openQuickSearch,
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppTheme.textMuted, size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Search provider directories…',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppTheme.textBarelyVisible,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _openExpandedSearch,
                      icon: Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: AppTheme.brandPurple,
                      ),
                      label: Text(
                        'Expanded search',
                        style: TextStyle(
                          color: AppTheme.brandPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoadingProviders
                  ? const Center(child: CircularProgressIndicator())
                  : _reviewedProviders.isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20), // px-5
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mama Approved™ — community reviews (not insurer “verified”)
                              Container(
                                padding: const EdgeInsets.all(16), // p-4
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8F3),
                                  borderRadius: BorderRadius.circular(24), // rounded-3xl
                                  border: Border.all(
                                    color: const Color(0xFFE8D4C0).withOpacity(0.7),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFFF6ED),
                                            Color(0xFFF0E6FA),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.favorite_rounded,
                                        color: Color(0xFF7D4E9E),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Mama Approved™ on this list',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Shows up when other parents left at least 3 reviews and the average is 4★ or higher — real experiences, not a medical seal.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                              fontWeight: FontWeight.w300,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20), // mb-5

                              // Provider Cards
                              ..._reviewedProviders.map((provider) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20), // space-y-5
                                  child: _buildProviderCard(provider),
                                );
                              }).toList(),

                              const SizedBox(height: 20),
                              
                              // Add Provider Button
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
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
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.brandPurple,
                                                Color(0xFF8855BB),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: AppTheme.brandWhite,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Add a Provider',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Can\'t find your provider? Add them to help others',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.textMuted,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: AppTheme.textMuted,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
            ),
          ],
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
            Icon(
              Icons.search,
              size: 64,
              color: AppTheme.brandPurple.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Find Your Care Team',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for trusted providers reviewed by mothers like you',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _openQuickSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
                foregroundColor: AppTheme.brandWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Start Searching',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24), // rounded-3xl
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20), // p-5
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.primaryDisplayName,
                                style: TextStyle(
                                  fontSize: 18, // text-lg
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (provider.showsMamaApprovedBadge)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: MamaApprovedCommunityBadge(compact: true),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.specialty ?? 'Provider',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w300,
                          ),
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
                              child: Text(
                                alt,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            );
                          },
                        ),
                        if (provider.healthCoverageLabel != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.health_and_safety_outlined,
                                size: 16,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Accepted health: ${provider.healthCoverageLabel}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textMuted,
                    size: 24,
                  ),
                ],
              ),

              const SizedBox(height: 12), // mb-3

              // Rating and Distance
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    provider.rating?.toStringAsFixed(1) ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    ' (${provider.reviewCount ?? 0})',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.location_on, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationText,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12), // mb-3

              // Accepting Badge
              if (provider.acceptingNewPatients == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFD1FAE5), // green-100
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(0xFF86EFAC), // green-200
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Accepting new patients',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF15803D), // green-700
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

              // Specialties Tags
              if (specialties.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: specialties.take(3).map((specialty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F0F8), // purple-50
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFFE8DFE8), // purple-100
                          width: 1,
                        ),
                      ),
                      child: Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.brandPurple,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
