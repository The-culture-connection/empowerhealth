import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/provider.dart';
import '../services/provider_repository.dart';
import '../cors/ui_theme.dart';
import '../widgets/provider_search_loading.dart';
import '../constants/provider_types.dart';
import 'provider_profile_screen.dart';
import 'add_provider_screen.dart';

class ProviderSearchResultsScreen extends StatefulWidget {
  final Map<String, dynamic> searchParams;

  const ProviderSearchResultsScreen({
    super.key,
    required this.searchParams,
  });

  @override
  State<ProviderSearchResultsScreen> createState() => _ProviderSearchResultsScreenState();
}

class _ProviderSearchResultsScreenState extends State<ProviderSearchResultsScreen> {
  final ProviderRepository _repository = ProviderRepository();
  List<Provider> _providers = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'Highest rated';
  Map<String, Map<String, dynamic>> _providerMatchInfo = {}; // Store match scores and filters
  List<String> _searchProviderTypeIds = []; // Store search provider type IDs for card display

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  /// Refresh provider data after returning from profile screen
  Future<void> _refreshProviderData(Provider provider) async {
    try {
      print('🔄 [ResultsScreen] Refreshing provider data for: ${provider.name}');
      // Wait a moment for Firestore to index the new review
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Find the provider in the list (it may have been updated with Firestore ID)
      final index = _providers.indexWhere((p) => 
        p.name == provider.name && 
        (p.id == provider.id || 
         (p.locations.isNotEmpty && provider.locations.isNotEmpty && 
          p.locations.first.city == provider.locations.first.city))
      );
      
      if (index >= 0) {
        final currentProvider = _providers[index];
        final providerIdToUse = currentProvider.id ?? provider.id;
        
        // Try to reload from Firestore if we have a valid Firestore ID
        if (providerIdToUse != null && 
            providerIdToUse.isNotEmpty &&
            !providerIdToUse.startsWith('api_') && 
            !providerIdToUse.startsWith('name_') &&
            !providerIdToUse.startsWith('npi_')) {
          try {
            final updatedProvider = await _repository.getProvider(providerIdToUse);
            if (updatedProvider != null && mounted) {
              setState(() {
                _providers[index] = updatedProvider;
              });
              print('✅ [ResultsScreen] Updated provider at index $index with Firestore data: reviewCount=${updatedProvider.reviewCount}');
              return;
            }
          } catch (e) {
            print('⚠️ [ResultsScreen] Could not reload provider from Firestore: $e');
          }
        }
        
        // Fallback: reload reviews and update rating
        await _reloadProviderReviews(currentProvider);
      } else {
        // Provider not in list, try to reload reviews anyway
        await _reloadProviderReviews(provider);
      }
    } catch (e) {
      print('⚠️ [ResultsScreen] Error refreshing provider data: $e');
      // Still try to reload reviews
      await _reloadProviderReviews(provider);
    }
  }

  /// Reload reviews for a provider and update its rating
  Future<void> _reloadProviderReviews(Provider provider) async {
    try {
      // Determine providerId for reviews (same logic as profile screen)
      String? reviewProviderId = provider.id;
      if (reviewProviderId == null || reviewProviderId.isEmpty) {
        if (provider.npi != null && provider.npi!.isNotEmpty) {
          reviewProviderId = 'npi_${provider.npi}';
        } else if (provider.locations.isNotEmpty) {
          final loc = provider.locations.first;
          final namePart = provider.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
          reviewProviderId = 'api_${namePart}_${loc.city}_${loc.zip}';
        } else if (provider.name.isNotEmpty) {
          final namePart = provider.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
          reviewProviderId = 'name_$namePart';
        }
      }
      
      if (reviewProviderId != null && reviewProviderId.isNotEmpty) {
        final reviews = await _repository.getProviderReviews(reviewProviderId);
        if (reviews.isNotEmpty && mounted) {
          final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
          final averageRating = totalRating / reviews.length;
          
          setState(() {
            final index = _providers.indexWhere((p) => 
              p.name == provider.name && 
              (p.locations.isEmpty || provider.locations.isEmpty || 
               p.locations.first.city == provider.locations.first.city)
            );
            if (index >= 0) {
              _providers[index] = _providers[index].copyWith(
                rating: averageRating,
                reviewCount: reviews.length,
              );
              print('✅ [ResultsScreen] Updated provider rating: $averageRating, review count: ${reviews.length}');
            }
          });
        }
      }
    } catch (e) {
      print('⚠️ [ResultsScreen] Error reloading reviews: $e');
    }
  }

  Future<void> _performSearch() async {
    print('🔍 [ResultsScreen] Search started');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final providerTypeIds = widget.searchParams['providerTypeIds'] as List<String>;
      print('🔍 [ResultsScreen] Calling repository.searchProviders...');
      print('🔍 [ResultsScreen] Payload details:');
      print('🔍 [ResultsScreen]   - ZIP: ${widget.searchParams['zip']}');
      print('🔍 [ResultsScreen]   - City: ${widget.searchParams['city']}');
      print('🔍 [ResultsScreen]   - Health Plan: ${widget.searchParams['healthPlan']}');
      print('🔍 [ResultsScreen]   - Provider Type IDs: $providerTypeIds');
      print('🔍 [ResultsScreen]   - Provider Type IDs count: ${providerTypeIds.length}');
      print('🔍 [ResultsScreen]   - Radius: ${widget.searchParams['radius']}');
      print('🔍 [ResultsScreen]   - Include NPI: ${widget.searchParams['includeNPI']}');
      
      final results = await _repository.searchProviders(
        zip: widget.searchParams['zip'] as String,
        city: widget.searchParams['city'] as String,
        healthPlan: widget.searchParams['healthPlan'] as String,
        providerTypeIds: providerTypeIds,
        radius: widget.searchParams['radius'] as int,
        specialty: (widget.searchParams['specialties'] as List<String>?)?.isNotEmpty == true
            ? (widget.searchParams['specialties'] as List<String>).first
            : null,
        includeNpi: widget.searchParams['includeNPI'] as bool? ?? false,
        // Pregnancy-Smart filters only
        acceptsPregnantWomen: widget.searchParams['acceptsPregnant'] as bool?,
        acceptsNewborns: widget.searchParams['acceptsNewborns'] as bool?,
        telehealth: widget.searchParams['telehealth'] as bool?,
      );

      print('✅ [ResultsScreen] Repository returned ${results.length} providers');

      // Calculate match scores for each provider based on active filters
      // Show all providers, but prioritize by how many filters they match
      final activeFilters = <String, dynamic>{};
      
      // Log provider type IDs being searched
      print('🔍 [ResultsScreen] Searching with provider type IDs: $providerTypeIds');
      if (providerTypeIds.isNotEmpty) {
        final providerTypeNames = providerTypeIds.map((id) {
          final name = ProviderTypes.getDisplayName(id);
          return '$id (${name ?? "Unknown"})';
        }).join(', ');
        print('🔍 [ResultsScreen] Provider types: $providerTypeNames');
      }
      
      if (widget.searchParams['mamaApprovedOnly'] == true) {
        activeFilters['mamaApproved'] = true;
      }
      if (widget.searchParams['acceptsPregnant'] == true) {
        activeFilters['acceptsPregnantWomen'] = true;
      }
      if (widget.searchParams['acceptsNewborns'] == true) {
        activeFilters['acceptsNewborns'] = true;
      }
      if (widget.searchParams['telehealth'] == true) {
        activeFilters['telehealth'] = true;
      }
      if ((widget.searchParams['specialties'] as List?)?.isNotEmpty == true) {
        activeFilters['specialty'] = (widget.searchParams['specialties'] as List).first;
      }
      if ((widget.searchParams['identityTags'] as List?)?.isNotEmpty == true) {
        activeFilters['identityTags'] = widget.searchParams['identityTags'];
      }
      if (providerTypeIds.isNotEmpty) {
        activeFilters['providerTypeIds'] = providerTypeIds;
      }

      // Calculate match score for each provider
      final providersWithScores = results.map((provider) {
        int matchScore = 0;
        final matchedFilters = <String>[];

        // Provider type matching (most important filter)
        if (activeFilters.containsKey('providerTypeIds') && provider.providerTypes.isNotEmpty) {
          final selectedTypeIds = activeFilters['providerTypeIds'] as List<String>;
          // Normalize IDs to API format (single digits 1-9 WITH leading zeros: "01", "02", "09")
          final normalizedSelected = selectedTypeIds.map((id) {
            final numId = int.tryParse(id);
            if (numId != null && numId >= 1 && numId <= 9) {
              return id.padLeft(2, '0'); // Add leading zero (API format: "01", "09")
            }
            return id; // Return as-is for double digits (10+)
          }).toList();
          
          final normalizedProvider = provider.providerTypes.map((id) {
            final numId = int.tryParse(id);
            if (numId != null && numId >= 1 && numId <= 9) {
              return id.padLeft(2, '0'); // Add leading zero (API format: "01", "09")
            }
            return id; // Return as-is for double digits (10+)
          }).toList();
          
          // Check if any provider type matches
          final matchingTypes = normalizedSelected.where((selectedId) => 
            normalizedProvider.contains(selectedId)
          ).toList();
          
          if (matchingTypes.isNotEmpty) {
            matchScore += matchingTypes.length; // Weight provider type matches more
            final typeNames = matchingTypes.map((id) => ProviderTypes.getDisplayName(id) ?? id).join(', ');
            matchedFilters.add('Provider type: $typeNames');
            print('✅ [ResultsScreen] Provider ${provider.name} matches types: $typeNames');
          } else {
            print('⚠️ [ResultsScreen] Provider ${provider.name} types (${provider.providerTypes}) do not match search types ($normalizedSelected)');
          }
        }

        if (activeFilters.containsKey('mamaApproved') && provider.mamaApproved == true) {
          matchScore++;
          matchedFilters.add('Mama Approved');
        }
        if (activeFilters.containsKey('acceptsPregnantWomen') && provider.acceptsPregnantWomen == true) {
          matchScore++;
          matchedFilters.add('Accepts pregnant patients');
        }
        if (activeFilters.containsKey('acceptsNewborns') && provider.acceptsNewborns == true) {
          matchScore++;
          matchedFilters.add('Accepts newborns');
        }
        if (activeFilters.containsKey('telehealth') && provider.telehealth == true) {
          matchScore++;
          matchedFilters.add('Telehealth');
        }
        if (activeFilters.containsKey('specialty') && provider.specialty != null) {
          final selectedSpecialty = activeFilters['specialty'] as String;
          if (provider.specialty!.toLowerCase().contains(selectedSpecialty.toLowerCase()) ||
              provider.specialties.any((s) => s.toLowerCase().contains(selectedSpecialty.toLowerCase()))) {
            matchScore++;
            matchedFilters.add('Specialty match');
          }
        }
        if (activeFilters.containsKey('identityTags') && provider.identityTags.isNotEmpty) {
          final selectedTags = (activeFilters['identityTags'] as List).map((t) => t.toString().toLowerCase()).toList();
          final providerTags = provider.identityTags.map((t) => t.name.toLowerCase()).toList();
          if (selectedTags.any((tag) => providerTags.contains(tag))) {
            matchScore++;
            matchedFilters.add('Identity match');
          }
        }

        return {
          'provider': provider,
          'matchScore': matchScore,
          'matchedFilters': matchedFilters,
        };
      }).toList();

      // Sort by: Match score first (most important), then Mama Approved, then rating
      providersWithScores.sort((a, b) {
        final providerA = a['provider'] as Provider;
        final providerB = b['provider'] as Provider;
        
        // First priority: Match score (providers matching more filters come first)
        final scoreA = a['matchScore'] as int;
        final scoreB = b['matchScore'] as int;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA); // Higher score first
        }
        
        // Second priority: Mama Approved providers
        if (providerA.mamaApproved && !providerB.mamaApproved) return -1;
        if (!providerA.mamaApproved && providerB.mamaApproved) return 1;
        
        // Third priority: Rating
        final ratingA = providerA.rating ?? 0.0;
        final ratingB = providerB.rating ?? 0.0;
        if (ratingA != ratingB) {
          return ratingB.compareTo(ratingA);
        }
        
        // Fourth priority: Review count
        final countA = providerA.reviewCount ?? 0;
        final countB = providerB.reviewCount ?? 0;
        return countB.compareTo(countA);
      });

      // Extract providers and store match info, calculate ratings from reviews
      final filtered = await Future.wait(providersWithScores.map((item) async {
        final provider = item['provider'] as Provider;
        // Debug: log rating info
        print('🔍 [ResultsScreen] Provider: ${provider.name}, Rating: ${provider.rating}, ReviewCount: ${provider.reviewCount}, ID: ${provider.id}');
        
        // Use the repository method to enrich provider with reviews
        // This will find the provider in Firestore first, then fetch reviews using the correct ID
        try {
          final enrichedProvider = await _repository.enrichProviderWithReviews(provider);
          print('✅ [ResultsScreen] Enriched ${provider.name}: rating=${enrichedProvider.rating}, reviewCount=${enrichedProvider.reviewCount}, FirestoreID=${enrichedProvider.id}');
          return enrichedProvider;
        } catch (e) {
          print('⚠️ [ResultsScreen] Error enriching provider ${provider.name}: $e');
          return provider; // Return original provider on error
        }
      }));

      // Store match info for display
      _providerMatchInfo = Map.fromEntries(
        providersWithScores.map((item) => MapEntry(
          (item['provider'] as Provider).id ?? '',
          {
            'score': item['matchScore'] as int,
            'filters': item['matchedFilters'] as List<String>,
          },
        )),
      );

      print('✅ [ResultsScreen] After scoring: ${filtered.length} providers');
      print('📊 [ResultsScreen] Match scores: ${_providerMatchInfo.values.map((v) => v['score']).join(', ')}');

      setState(() {
        _providers = filtered;
        _isLoading = false;
        _searchProviderTypeIds = providerTypeIds; // Store for card display
        print('✅ [ResultsScreen] setState called with ${filtered.length} providers');
        // Clear error if we got results (even if empty)
        if (filtered.isEmpty) {
          _error = null; // Empty results is not an error
          print('ℹ️ [ResultsScreen] Empty results - will show empty state');
        }
      });
    } catch (e, stackTrace) {
      print('❌ [ResultsScreen] Error in _performSearch: $e');
      print('❌ [ResultsScreen] Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _providers = []; // Clear providers on error
      });
    }
  }

  void _sortProviders(List<Provider> providers) {
    switch (_sortBy) {
      case 'Highest rated':
        providers.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'Nearest':
        providers.sort((a, b) {
          final distA = a.locations.isNotEmpty ? a.locations.first.distance : null;
          final distB = b.locations.isNotEmpty ? b.locations.first.distance : null;
          final distAValue = distA ?? double.infinity;
          final distBValue = distB ?? double.infinity;
          return distAValue.compareTo(distBValue);
        });
        break;
      case 'Most reviewed':
        providers.sort((a, b) => (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0));
        break;
      case 'Mama Approved first':
        providers.sort((a, b) {
          if (a.mamaApproved && !b.mamaApproved) return -1;
          if (!a.mamaApproved && b.mamaApproved) return 1;
          return (b.rating ?? 0).compareTo(a.rating ?? 0);
        });
        break;
      default: // Most relevant
        providers.sort((a, b) {
          // Sort by Mama Approved first, then rating
          if (a.mamaApproved && !b.mamaApproved) return -1;
          if (!a.mamaApproved && b.mamaApproved) return 1;
          return (b.rating ?? 0).compareTo(a.rating ?? 0);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F5F9), // bg-[#f7f5f9]
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF7F5F9),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header (matching NewUI exactly)
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
                                    'Search results',
                                    style: TextStyle(
                                      fontSize: 24, // text-2xl
                                      fontWeight: FontWeight.w400, // font-normal
                                      color: Color(0xFF4A3F52), // text-[#4a3f52]
                                    ),
                                  ),
                                  const SizedBox(height: 8), // mb-2
                                  Text(
                                    '${_providers.length} providers found near you',
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

              // Content (matching NewUI)
              Expanded(
                child: _isLoading
                    ? const ProviderSearchLoading()
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading providers',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFD4C5E0),
                                          Color(0xFFA89CB5),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _performSearch,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: Text(
                                        'Try Again',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              if (_providers.isEmpty) {
                                return _buildEmptyState();
                              } else {
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(horizontal: 24), // px-6
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Trust Banner (matching NewUI)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 24), // mb-6
                                        padding: const EdgeInsets.all(20), // p-5
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFF0EAD8), // from-[#f0ead8]
                                              Color(0xFFF5F0E8), // to-[#f5f0e8]
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: Color(0xFFE8DFC8).withOpacity(0.5),
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.shield,
                                              color: Color(0xFFC9B087),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'These providers are sourced from Ohio Medicaid directories + NPI registry. Community trust indicators come from verified patient reviews.',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B5C75),
                                                  fontWeight: FontWeight.w300,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Sorting (matching NewUI)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 24), // mb-6
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Sorted by distance',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF8B7A95),
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: AppTheme.borderLighter.withOpacity(0.5),
                                                ),
                                              ),
                                              child: DropdownButton<String>(
                                                value: _sortBy,
                                                underline: const SizedBox(),
                                                isDense: true,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B5C75),
                                                  fontWeight: FontWeight.w300,
                                                ),
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: 'Nearest',
                                                    child: Text('Nearest first'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'Highest rated',
                                                    child: Text('Highest rated'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'Most reviewed',
                                                    child: Text('Most reviewed'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'Mama Approved first',
                                                    child: Text('Mama Approved™'),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  if (value != null) {
                                                    setState(() {
                                                      _sortBy = value;
                                                      _sortProviders(_providers);
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Provider Cards (matching NewUI)
                                      ..._providers.map((provider) {
                                        final matchInfo = _providerMatchInfo[provider.id ?? ''] ?? {'score': 0, 'filters': <String>[]};
                                        return _ProviderCard(
                                          provider: provider,
                                          repository: _repository,
                                          matchedFilters: (matchInfo['filters'] as List<String>?) ?? [],
                                          matchScore: (matchInfo['score'] as int?) ?? 0,
                                          searchProviderTypeIds: _searchProviderTypeIds,
                                          onTap: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ProviderProfileScreen(
                                                  provider: provider,
                                                  providerId: provider.id,
                                                ),
                                              ),
                                            );
                                            // If a review was submitted, refresh the provider data
                                            if (result != null && mounted) {
                                              // Result contains the Firestore provider ID
                                              final firestoreProviderId = result is String ? result : null;
                                              print('✅ [ResultsScreen] Review submitted, Firestore ID: $firestoreProviderId');
                                              
                                              // Update provider ID if we got a Firestore ID
                                              if (firestoreProviderId != null && 
                                                  firestoreProviderId != provider.id &&
                                                  !firestoreProviderId.startsWith('api_') && 
                                                  !firestoreProviderId.startsWith('name_') &&
                                                  !firestoreProviderId.startsWith('npi_')) {
                                                // Update the provider in the list with the Firestore ID
                                                final index = _providers.indexWhere((p) => 
                                                  p.name == provider.name && 
                                                  (p.id == provider.id || 
                                                   (p.locations.isNotEmpty && provider.locations.isNotEmpty && 
                                                    p.locations.first.city == provider.locations.first.city))
                                                );
                                                if (index >= 0) {
                                                  setState(() {
                                                    _providers[index] = _providers[index].copyWith(id: firestoreProviderId);
                                                  });
                                                  print('✅ [ResultsScreen] Updated provider ID to Firestore ID: $firestoreProviderId');
                                                }
                                              }
                                              
                                              // Refresh this provider's data (reviews, rating, etc.)
                                              await _refreshProviderData(provider);
                                            }
                                          },
                                        );
                                      }).toList(),
                                      
                                      const SizedBox(height: 32), // mt-8
                                      
                                      // Can't Find Provider (matching NewUI)
                                      Container(
                                        padding: const EdgeInsets.all(24), // p-6
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFFAF7FB), // from-[#faf7fb]
                                              Color(0xFFF9F5FB), // to-[#f9f5fb]
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: AppTheme.borderLightest.withOpacity(0.5),
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
                                            Text(
                                              'Can\'t find who you\'re looking for?',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF4A3F52),
                                              ),
                                            ),
                                            const SizedBox(height: 8), // mb-4
                                            Text(
                                              'Help build this directory by adding providers you trust. Your contribution helps other mothers find quality care.',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF6B5C75),
                                                fontWeight: FontWeight.w300,
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 16), // mb-4
                                            InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const AddProviderScreen(),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                'Add a provider →',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFFA89CB5),
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 100), // Space for bottom nav
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderLighter.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildCulturalMatchDisclaimer() {
    // Check if any providers have verified identity tags matching the search
    final identityTags = widget.searchParams['identityTags'] as List<String>? ?? [];
    if (identityTags.isEmpty) return const SizedBox.shrink();
    
    final hasVerifiedMatches = _providers.any((provider) {
      if (provider.identityTags.isEmpty) return false;
      // Check if provider has any verified identity tags that match the search
      return provider.identityTags.any((tag) => 
        identityTags.contains(tag.name) && tag.verificationStatus == 'verified'
      );
    });
    
    if (hasVerifiedMatches) return const SizedBox.shrink();
    
    // No verified matches found - show disclaimer (matching NewUI)
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF0EAD8), // from-[#f0ead8]
            Color(0xFFF5F0E8), // to-[#f5f0e8]
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Color(0xFFE8DFC8).withOpacity(0.5),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Color(0xFFC9B087),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No community-verified matches found',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4A3F52),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We found ${_providers.length} providers matching your search, but none have been community-verified for the identity tags you selected. These providers may still be a good match.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B5C75),
                    fontWeight: FontWeight.w300,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSpecialty = (widget.searchParams['specialties'] as List<String>?)?.isNotEmpty == true;
    final includeNPI = widget.searchParams['includeNPI'] as bool? ?? false;
    final currentRadius = widget.searchParams['radius'] as int? ?? 10;
    final providerTypeIds = widget.searchParams['providerTypeIds'] as List<String>? ?? [];
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No providers found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Try these suggestions:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestion('Widen your search radius (currently ${currentRadius} miles)'),
                  if (!providerTypeIds.contains('01'))
                    _buildSuggestion('Add "Hospital" (01) to provider types'),
                  if (!providerTypeIds.contains('20') && !providerTypeIds.contains('09'))
                    _buildSuggestion('Add "Physician / Osteopath Individual" (20) or "OB-GYN" (09)'),
                  if (!includeNPI && hasSpecialty)
                    _buildSuggestion('Enable NPI fallback to search additional providers'),
                  if (includeNPI && !hasSpecialty)
                    _buildSuggestion('Select a specialty to enable NPI search'),
                  _buildSuggestion('Try a different health plan'),
                  _buildSuggestion('Search in a nearby city'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Go back to search
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddProviderScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Provider'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersInScrollView() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Within ${widget.searchParams['radius']} miles of ${(widget.searchParams['zip'] as String).length > 5 ? (widget.searchParams['zip'] as String).substring(0, 5) : widget.searchParams['zip']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Edit filters',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.brandPurple,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(widget.searchParams['healthPlan'] as String),
              if ((widget.searchParams['providerTypeIds'] as List).isNotEmpty)
                _buildFilterChip('Provider Type'),
              if (widget.searchParams['acceptsPregnant'] == true)
                _buildFilterChip('Accepts pregnant patients'),
              if (widget.searchParams['acceptsNewborns'] == true)
                _buildFilterChip('Accepts newborns'),
              if (widget.searchParams['telehealth'] == true)
                _buildFilterChip('Telehealth'),
              if ((widget.searchParams['specialties'] as List?)?.isNotEmpty == true)
                _buildFilterChip('Specialty'),
              if ((widget.searchParams['identityTags'] as List?)?.isNotEmpty == true)
                _buildFilterChip('Identity match'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final Provider provider;
  final ProviderRepository repository;
  final VoidCallback onTap;
  final List<String> matchedFilters;
  final int matchScore;
  final List<String> searchProviderTypeIds;

  const _ProviderCard({
    required this.provider,
    required this.repository,
    required this.onTap,
    this.matchedFilters = const [],
    this.matchScore = 0,
    this.searchProviderTypeIds = const [],
  });

  String _formatPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    if (digits.length == 11 && digits.startsWith('1')) {
      return '1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final location = provider.locations.isNotEmpty ? provider.locations.first : null;
    final distance = location?.distance != null
        ? '${location!.distance!.toStringAsFixed(1)} miles'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20), // space-y-5
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(32), // rounded-[32px]
        border: Border.all(
          color: AppTheme.borderLighter.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Provider Image/Header (matching NewUI)
          Container(
            height: 144, // h-36
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFEBE4F3), // from-[#ebe4f3]
                  Color(0xFFE8DFE8), // to-[#e8dfe8]
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 80, // w-20
                height: 80, // h-20
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFD4C5E0), // from-[#d4c5e0]
                      Color(0xFFE0D5EB), // to-[#e0d5eb]
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFA89CB5).withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32, // text-2xl
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24), // p-6
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Tags (matching NewUI)
                Container(
                  margin: const EdgeInsets.only(bottom: 16), // mb-4
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.name,
                                  style: TextStyle(
                                    fontSize: 18, // text-lg
                                    fontWeight: FontWeight.w400, // font-normal
                                    color: Color(0xFF4A3F52), // text-[#4a3f52]
                                  ),
                                ),
                                const SizedBox(height: 4), // mb-1
                                Text(
                                  '${provider.specialty ?? ''}${provider.practiceName != null ? ' • ${provider.practiceName}' : ''}',
                                  style: TextStyle(
                                    fontSize: 14, // text-sm
                                    color: Color(0xFF8B7A95), // text-[#8b7a95]
                                    fontWeight: FontWeight.w300, // font-light
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (provider.acceptingNewPatients ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFDCE8E4).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Color(0xFFC9E0D9).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '✓ Accepting',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B9688),
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Provider Type Tags and Match Indicators
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Provider Type Tags (only show types with display names)
                          ...provider.providerTypes
                              .where((typeId) => ProviderTypes.getDisplayName(typeId) != null) // Filter out codes without display names
                              .map((typeId) {
                            final typeName = ProviderTypes.getDisplayName(typeId)!; // Safe to use ! since we filtered
                            final isMatched = searchProviderTypeIds.any((searchId) {
                              // Normalize to API format (single digits 1-9 WITH leading zeros: "01", "02", "09")
                              final normalizedSearch = int.tryParse(searchId) != null && int.parse(searchId) >= 1 && int.parse(searchId) <= 9
                                  ? searchId.padLeft(2, '0') // Add leading zero (API format: "01", "09")
                                  : searchId;
                              final normalizedType = int.tryParse(typeId) != null && int.parse(typeId) >= 1 && int.parse(typeId) <= 9
                                  ? typeId.padLeft(2, '0') // Add leading zero (API format: "01", "09")
                                  : typeId;
                              return normalizedSearch == normalizedType;
                            });
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isMatched 
                                    ? Color(0xFFE8F5E9).withOpacity(0.8) // Green for matched
                                    : Color(0xFFF5F5F5).withOpacity(0.8), // Gray for unmatched
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isMatched
                                      ? Color(0xFF4CAF50).withOpacity(0.3)
                                      : Color(0xFFE0E0E0).withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isMatched)
                                    Icon(Icons.check_circle, size: 14, color: Color(0xFF4CAF50)),
                                  if (isMatched) const SizedBox(width: 4),
                                  Text(
                                    typeName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isMatched ? Color(0xFF2E7D32) : Color(0xFF6B5C75),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          // Mama Approved Badge
                          if (provider.mamaApproved)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF0E0E8),
                                    Color(0xFFF5E8F0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Color(0xFFE8D0E0).withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.workspace_premium,
                                    size: 14,
                                    color: Color(0xFFC9A9C0),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Mama Approved™',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFC9A9C0),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Match Score Indicator
                          if (matchScore > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFFE3F2FD).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Color(0xFF2196F3).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 14, color: Color(0xFF1976D2)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$matchScore filter${matchScore > 1 ? 's' : ''} match',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1976D2),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rating (matching NewUI)
                Container(
                  margin: const EdgeInsets.only(bottom: 20), // mb-5
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 20,
                            color: Color(0xFFC9B087),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            provider.rating != null && provider.rating! > 0
                                ? provider.rating!.toStringAsFixed(1)
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 18, // text-lg
                              fontWeight: FontWeight.w400, // font-normal
                              color: Color(0xFF4A3F52), // text-[#4a3f52]
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '(${provider.reviewCount ?? 0} reviews)',
                        style: TextStyle(
                          fontSize: 14, // text-sm
                          color: Color(0xFFA89CB5), // text-[#a89cb5]
                          fontWeight: FontWeight.w300, // font-light
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Info Grid (matching NewUI)
                Container(
                  margin: const EdgeInsets.only(bottom: 20), // mb-5
                  padding: const EdgeInsets.all(16), // p-4
                  decoration: BoxDecoration(
                    color: Color(0xFFF7F5F9), // bg-[#f7f5f9]
                    borderRadius: BorderRadius.circular(20), // rounded-[20px]
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Color(0xFFA89CB5),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    distance ?? location?.fullAddress ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8B7A95),
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (provider.phone != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Color(0xFFA89CB5),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatPhoneNumber(provider.phone!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8B7A95),
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Specialties (if available)
                if (provider.specialties.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 20), // mb-5
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.specialties.take(3).map((specialty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFE8E0F0).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Color(0xFFD4C5E0).withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            specialty,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B7A95),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Action Buttons (matching NewUI)
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'View full profile',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // gap-3
                    if (provider.phone != null)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.borderLighter.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: OutlinedButton(
                          onPressed: () async {
                            final uri = Uri.parse('tel:${provider.phone}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: BorderSide.none,
                          ),
                          child: Icon(
                            Icons.phone,
                            color: Color(0xFF8B7A95),
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
