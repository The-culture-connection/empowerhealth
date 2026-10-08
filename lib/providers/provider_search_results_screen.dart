import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/provider.dart';
import '../services/provider_repository.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../widgets/provider_search_loading.dart';
import '../constants/provider_types.dart';
import 'provider_profile_screen.dart';
import 'add_provider_screen.dart';
import '../widgets/qualitative_survey_dialog.dart';
import '../widgets/mama_approved_community_badge.dart';

class ProviderSearchResultsScreen extends StatefulWidget {
  final Map<String, dynamic> searchParams;

  const ProviderSearchResultsScreen({super.key, required this.searchParams});

  @override
  State<ProviderSearchResultsScreen> createState() =>
      _ProviderSearchResultsScreenState();
}

class _ProviderSearchResultsScreenState
    extends State<ProviderSearchResultsScreen> {
  final ProviderRepository _repository = ProviderRepository();
  List<Provider> _providers = [];
  bool _isLoading = true;
  String? _error;
  // Results arrive ranked by filter match, then Mama Approved™, then rating —
  // label the dropdown accordingly so it matches what is on screen.
  String _sortBy = 'Most relevant';
  Map<String, Map<String, dynamic>> _providerMatchInfo =
      {}; // Store match scores and filters
  List<String> _searchProviderTypeIds =
      []; // Store search provider type IDs for card display

  @override
  void initState() {
    super.initState();
    _trackScreenView();
    _performSearch();
  }

  Future<void> _trackScreenView() async {
    try {
      final analytics = AnalyticsService();
      final databaseService = DatabaseService();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProfile = await databaseService.getUserProfile(userId);
        await analytics.logScreenView(
          screenName: 'provider_search_results',
          feature: 'provider-search',
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking provider search results screen view: $e');
    }
  }

  /// Refresh provider data after returning from profile screen
  Future<void> _refreshProviderData(Provider provider) async {
    try {
      print('🔄 [ResultsScreen] Refreshing provider data for: ${provider.name}');
      // Wait a moment for Firestore to index the new review
      await Future.delayed(const Duration(milliseconds: 1000));

      // Find the provider in the list (it may have been updated with Firestore ID)
      final index = _providers.indexWhere(
        (p) =>
            p.name == provider.name &&
            (p.id == provider.id ||
                (p.locations.isNotEmpty &&
                    provider.locations.isNotEmpty &&
                    p.locations.first.city == provider.locations.first.city)),
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
            final updatedProvider = await _repository.getProvider(
              providerIdToUse,
            );
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
          final namePart = provider.name
              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
              .toLowerCase();
          reviewProviderId = 'api_${namePart}_${loc.city}_${loc.zip}';
        } else if (provider.name.isNotEmpty) {
          final namePart = provider.name
              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
              .toLowerCase();
          reviewProviderId = 'name_$namePart';
        }
      }

      if (reviewProviderId != null && reviewProviderId.isNotEmpty) {
        final reviews = ProviderRepository.publishedOnly(
          await _repository.getProviderReviews(reviewProviderId),
        );
        if (reviews.isNotEmpty && mounted) {
          final totalRating = reviews.fold<double>(
            0.0,
            (sum, review) => sum + review.rating,
          );
          final averageRating = totalRating / reviews.length;

          setState(() {
            final index = _providers.indexWhere(
              (p) =>
                  p.name == provider.name &&
                  (p.locations.isEmpty ||
                      provider.locations.isEmpty ||
                      p.locations.first.city == provider.locations.first.city),
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

  /// Incremented per search so a slower, superseded request (e.g. after
  /// "Try Again") can't overwrite newer results or end the loading state.
  int _searchGeneration = 0;

  Future<void> _performSearch() async {
    print('🔍 [ResultsScreen] Search started');
    final generation = ++_searchGeneration;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final providerTypeIds =
          widget.searchParams['providerTypeIds'] as List<String>;
      print('🔍 [ResultsScreen] Calling repository.searchProviders...');
      print('🔍 [ResultsScreen] Payload details:');
      print('🔍 [ResultsScreen]   - ZIP: ${widget.searchParams['zip']}');
      print('🔍 [ResultsScreen]   - City: ${widget.searchParams['city']}');
      print('🔍 [ResultsScreen]   - Health Plan: ${widget.searchParams['healthPlan']}');
      print('🔍 [ResultsScreen]   - Provider Type IDs: $providerTypeIds');
      print('🔍 [ResultsScreen]   - Provider Type IDs count: ${providerTypeIds.length}');
      print('🔍 [ResultsScreen]   - Radius: ${widget.searchParams['radius']}');
      print('🔍 [ResultsScreen]   - Include NPI: ${widget.searchParams['includeNPI']}');

      final nameContains = widget.searchParams['nameContains'] as String?;
      final directoryQuery = widget.searchParams['directoryQuery'] as String?;

      var results = await _repository.searchProviders(
        zip: widget.searchParams['zip'] as String,
        city: widget.searchParams['city'] as String,
        healthPlan: widget.searchParams['healthPlan'] as String,
        providerTypeIds: providerTypeIds,
        radius: widget.searchParams['radius'] as int,
        specialty:
            (widget.searchParams['specialties'] as List<String>?)?.isNotEmpty ==
                true
            ? (widget.searchParams['specialties'] as List<String>).first
            : null,
        includeNpi: widget.searchParams['includeNPI'] as bool? ?? false,
        // Pregnancy-Smart filters only
        acceptsPregnantWomen: widget.searchParams['acceptsPregnant'] as bool?,
        acceptsNewborns: widget.searchParams['acceptsNewborns'] as bool?,
        telehealth: widget.searchParams['telehealth'] as bool?,
        nameContains: nameContains,
        directoryQuery: directoryQuery,
      );

      print('✅ [ResultsScreen] Repository returned ${results.length} providers');

      // Calculate match scores for each provider based on active filters
      // Show all providers, but prioritize by how many filters they match
      final activeFilters = <String, dynamic>{};

      // Log provider type IDs being searched
      print('🔍 [ResultsScreen] Searching with provider type IDs: $providerTypeIds');
      if (providerTypeIds.isNotEmpty) {
        final providerTypeNames = providerTypeIds
            .map((id) {
              final name = ProviderTypes.getDisplayName(id);
              return '$id (${name ?? "Unknown"})';
            })
            .join(', ');
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
        activeFilters['specialty'] =
            (widget.searchParams['specialties'] as List).first;
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
        if (activeFilters.containsKey('providerTypeIds') &&
            provider.providerTypes.isNotEmpty) {
          final selectedTypeIds =
              activeFilters['providerTypeIds'] as List<String>;
          // Normalize IDs to API format (single digits 1-9 WITH leading zeros: "01", "02", "09")
          final normalizedSelected = selectedTypeIds.map((id) {
            final numId = int.tryParse(id);
            if (numId != null && numId >= 1 && numId <= 9) {
              return id.padLeft(
                2,
                '0',
              ); // Add leading zero (API format: "01", "09")
            }
            return id; // Return as-is for double digits (10+)
          }).toList();

          final normalizedProvider = provider.providerTypes.map((id) {
            final numId = int.tryParse(id);
            if (numId != null && numId >= 1 && numId <= 9) {
              return id.padLeft(
                2,
                '0',
              ); // Add leading zero (API format: "01", "09")
            }
            return id; // Return as-is for double digits (10+)
          }).toList();

          // Check if any provider type matches
          final matchingTypes = normalizedSelected
              .where((selectedId) => normalizedProvider.contains(selectedId))
              .toList();

          if (matchingTypes.isNotEmpty) {
            matchScore +=
                matchingTypes.length; // Weight provider type matches more
            final typeNames = matchingTypes
                .map((id) => ProviderTypes.getDisplayName(id) ?? id)
                .join(', ');
            matchedFilters.add('Provider type: $typeNames');
            print('✅ [ResultsScreen] Provider ${provider.name} matches types: $typeNames');
          } else {
            print('⚠️ [ResultsScreen] Provider ${provider.name} types (${provider.providerTypes}) do not match search types ($normalizedSelected)');
          }
        }

        if (activeFilters.containsKey('mamaApproved') &&
            provider.showsMamaApprovedBadge) {
          matchScore++;
          matchedFilters.add('Mama Approved');
        }
        if (activeFilters.containsKey('acceptsPregnantWomen') &&
            provider.acceptsPregnantWomen == true) {
          matchScore++;
          matchedFilters.add('Accepts pregnant patients');
        }
        if (activeFilters.containsKey('acceptsNewborns') &&
            provider.acceptsNewborns == true) {
          matchScore++;
          matchedFilters.add('Accepts newborns');
        }
        if (activeFilters.containsKey('telehealth') &&
            provider.telehealth == true) {
          matchScore++;
          matchedFilters.add('Telehealth');
        }
        if (activeFilters.containsKey('specialty') &&
            provider.specialty != null) {
          final selectedSpecialty = activeFilters['specialty'] as String;
          if (provider.specialty!.toLowerCase().contains(
                selectedSpecialty.toLowerCase(),
              ) ||
              provider.specialties.any(
                (s) =>
                    s.toLowerCase().contains(selectedSpecialty.toLowerCase()),
              )) {
            matchScore++;
            matchedFilters.add('Specialty match');
          }
        }
        if (activeFilters.containsKey('identityTags') &&
            provider.identityTags.isNotEmpty) {
          final selectedTags = (activeFilters['identityTags'] as List)
              .map((t) => t.toString().toLowerCase())
              .toList();
          final providerTags = provider.identityTags
              .map((t) => t.name.toLowerCase())
              .toList();
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

        // Second priority: Mama Approved (community reviews) providers
        if (providerA.showsMamaApprovedBadge &&
            !providerB.showsMamaApprovedBadge) {
          return -1;
        }
        if (!providerA.showsMamaApprovedBadge &&
            providerB.showsMamaApprovedBadge) {
          return 1;
        }

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
      final filtered = await Future.wait(
        providersWithScores.map((item) async {
          final provider = item['provider'] as Provider;
          // Debug: log rating info
          print('🔍 [ResultsScreen] Provider: ${provider.name}, Rating: ${provider.rating}, ReviewCount: ${provider.reviewCount}, ID: ${provider.id}');

          // Use the repository method to enrich provider with reviews
          // This will find the provider in Firestore first, then fetch reviews using the correct ID
          try {
            final enrichedProvider = await _repository
                .enrichProviderWithReviews(provider);
            print('✅ [ResultsScreen] Enriched ${provider.name}: rating=${enrichedProvider.rating}, reviewCount=${enrichedProvider.reviewCount}, FirestoreID=${enrichedProvider.id}');
            return enrichedProvider;
          } catch (e) {
            print('⚠️ [ResultsScreen] Error enriching provider ${provider.name}: $e');
            return provider; // Return original provider on error
          }
        }),
      );

      var listForUi = filtered;
      if (widget.searchParams['mamaApprovedOnly'] == true) {
        listForUi = filtered
            .where((p) => p.showsMamaApprovedBadge)
            .toList();
      }

      // Store match info for display
      _providerMatchInfo = Map.fromEntries(
        providersWithScores.map(
          (item) => MapEntry((item['provider'] as Provider).id ?? '', {
            'score': item['matchScore'] as int,
            'filters': item['matchedFilters'] as List<String>,
          }),
        ),
      );

      if (!mounted || generation != _searchGeneration) return;

      print('✅ [ResultsScreen] After scoring: ${listForUi.length} providers');
      print('📊 [ResultsScreen] Match scores: ${_providerMatchInfo.values.map((v) => v['score']).join(', ')}');

      setState(() {
        _providers = listForUi;
        _isLoading = false;
        _searchProviderTypeIds = providerTypeIds; // Store for card display
        print('✅ [ResultsScreen] setState called with ${listForUi.length} providers');
        // Clear error if we got results (even if empty)
        if (listForUi.isEmpty) {
          _error = null; // Empty results is not an error
          print('ℹ️ [ResultsScreen] Empty results - will show empty state');
        }
      });
    } catch (e, stackTrace) {
      print('❌ [ResultsScreen] Error in _performSearch: $e');
      print('❌ [ResultsScreen] Stack trace: $stackTrace');
      if (!mounted || generation != _searchGeneration) return;
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
          final distA = a.distanceMiles ??
              (a.locations.isNotEmpty ? a.locations.first.distance : null);
          final distB = b.distanceMiles ??
              (b.locations.isNotEmpty ? b.locations.first.distance : null);
          final distAValue = distA ?? double.infinity;
          final distBValue = distB ?? double.infinity;
          return distAValue.compareTo(distBValue);
        });
        break;
      case 'Most reviewed':
        providers.sort(
          (a, b) => (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0),
        );
        break;
      case 'Mama Approved first':
        providers.sort((a, b) {
          if (a.showsMamaApprovedBadge && !b.showsMamaApprovedBadge) {
            return -1;
          }
          if (!a.showsMamaApprovedBadge && b.showsMamaApprovedBadge) {
            return 1;
          }
          return (b.rating ?? 0).compareTo(a.rating ?? 0);
        });
        break;
      default: // Most relevant
        providers.sort((a, b) {
          if (a.showsMamaApprovedBadge && !b.showsMamaApprovedBadge) {
            return -1;
          }
          if (!a.showsMamaApprovedBadge && b.showsMamaApprovedBadge) {
            return 1;
          }
          return (b.rating ?? 0).compareTo(a.rating ?? 0);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
          child: Column(
            children: [
              HearthPushedHeader(
                title: 'Search results',
                onBack: () => Navigator.pop(context),
                // Only report a count once the search has finished — never
                // "0 providers" while results are still loading.
                subtitle: _isLoading
                    ? 'Searching for providers near you…'
                    : _error != null
                    ? 'Search didn\'t finish'
                    : _providers.length == 1
                    ? '1 provider found near you'
                    : '${_providers.length} providers found near you',
              ),

              Expanded(
                child: _isLoading
                    ? const ProviderSearchLoading()
                    : _error != null
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HearthIconChip(
                                Icons.error_outline,
                                size: 64,
                                iconSize: 30,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'We couldn\'t load providers right now',
                                textAlign: TextAlign.center,
                                style: textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check your internet connection and try again. If it keeps happening, go back and adjust your search.',
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              HearthButton.primary(
                                label: 'Try Again',
                                onPressed: _performSearch,
                                expand: false,
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
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HearthNote(
                                    icon: Icons.shield_outlined,
                                    text:
                                        'Listings come from Ohio Medicaid and/or the national provider registry. Stars and tags reflect community input.',
                                  ),
                                  const SizedBox(height: 20),

                                  // Sorting
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Sort by',
                                            style: textTheme.bodyMedium,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          constraints: const BoxConstraints(
                                            minHeight: 44,
                                          ),
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          decoration: const ShapeDecoration(
                                            color: AppTheme.surface,
                                            shape: StadiumBorder(
                                              side: BorderSide(
                                                color: AppTheme.borderWarm,
                                              ),
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _sortBy,
                                            underline: const SizedBox(),
                                            isDense: true,
                                            icon: const Icon(
                                              Icons.expand_more,
                                              size: 20,
                                              color: AppTheme.textSecondary,
                                            ),
                                            dropdownColor: AppTheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.fieldRadius,
                                            ),
                                            style: const TextStyle(
                                              fontFamily: AppTheme.sansFamily,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.ink,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Most relevant',
                                                child: Text('Most relevant'),
                                              ),
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
                                    final matchInfo =
                                        _providerMatchInfo[provider.id ?? ''] ??
                                        {'score': 0, 'filters': <String>[]};
                                    return _ProviderCard(
                                      provider: provider,
                                      repository: _repository,
                                      matchedFilters:
                                          (matchInfo['filters']
                                              as List<String>?) ??
                                          [],
                                      matchScore:
                                          (matchInfo['score'] as int?) ?? 0,
                                      searchProviderTypeIds:
                                          _searchProviderTypeIds,
                                      onTap: () async {
                                        // Track provider profile view
                                        try {
                                          final analytics = AnalyticsService();
                                          final databaseService =
                                              DatabaseService();
                                          final userId = FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid;
                                          if (userId != null) {
                                            final userProfile =
                                                await databaseService
                                                    .getUserProfile(userId);
                                            await analytics
                                                .logProviderProfileViewed(
                                                  providerId:
                                                      provider.id ?? 'unknown',
                                                  userProfile: userProfile,
                                                );
                                            await analytics
                                                .logProviderSelectedSuccess(
                                                  providerId:
                                                      provider.id ?? 'unknown',
                                                  selectionMethod:
                                                      'search_results_tap',
                                                  userProfile: userProfile,
                                                );
                                          }
                                        } catch (e) {
                                          print(
                                            'Error tracking provider profile view: $e',
                                          );
                                        }

                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProviderProfileScreen(
                                                  provider: provider,
                                                  providerId: provider.id,
                                                ),
                                          ),
                                        );
                                        // If a review was submitted, refresh the provider data
                                        if (result != null && mounted) {
                                          // Result contains the Firestore provider ID
                                          final firestoreProviderId =
                                              result is String ? result : null;
                                          print('✅ [ResultsScreen] Review submitted, Firestore ID: $firestoreProviderId');

                                          // Update provider ID if we got a Firestore ID
                                          if (firestoreProviderId != null &&
                                              firestoreProviderId !=
                                                  provider.id &&
                                              !firestoreProviderId.startsWith(
                                                'api_',
                                              ) &&
                                              !firestoreProviderId.startsWith(
                                                'name_',
                                              ) &&
                                              !firestoreProviderId.startsWith(
                                                'npi_',
                                              )) {
                                            // Update the provider in the list with the Firestore ID
                                            final index = _providers.indexWhere(
                                              (p) =>
                                                  p.name == provider.name &&
                                                  (p.id == provider.id ||
                                                      (p.locations.isNotEmpty &&
                                                          provider
                                                              .locations
                                                              .isNotEmpty &&
                                                          p
                                                                  .locations
                                                                  .first
                                                                  .city ==
                                                              provider
                                                                  .locations
                                                                  .first
                                                                  .city)),
                                            );
                                            if (index >= 0) {
                                              setState(() {
                                                _providers[index] =
                                                    _providers[index].copyWith(
                                                      id: firestoreProviderId,
                                                    );
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

                                  const SizedBox(height: 12),
                                  // Can't Find Provider
                                  SizedBox(
                                    width: double.infinity,
                                    child: HearthFeatureCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Can\'t find who you\'re looking for?',
                                            style: hearthFeatureTitleStyle(),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Help build this directory by adding providers you trust. Your contribution helps other mothers find quality care.',
                                            style: hearthCardBodyStyle,
                                          ),
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const AddProviderScreen(),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                minHeight: 44,
                                              ),
                                              child: const Align(
                                                alignment: AlignmentDirectional
                                                    .centerStart,
                                                widthFactor: 1,
                                                child: Text(
                                                  'Add a provider →',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppTheme.sansFamily,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.brandPurple,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 100,
                                  ), // Space for bottom nav
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
    );
  }

  Widget _buildFilterChip(String label) {
    return HearthTag(label);
  }

  Widget _buildCulturalMatchDisclaimer() {
    // Check if any providers have verified identity tags matching the search
    final identityTags =
        widget.searchParams['identityTags'] as List<String>? ?? [];
    if (identityTags.isEmpty) return const SizedBox.shrink();

    final hasVerifiedMatches = _providers.any((provider) {
      if (provider.identityTags.isEmpty) return false;
      // Check if provider has any verified identity tags that match the search
      return provider.identityTags.any(
        (tag) =>
            identityTags.contains(tag.name) &&
            tag.verificationStatus == 'verified',
      );
    });

    if (hasVerifiedMatches) return const SizedBox.shrink();

    // No verified matches found - show disclaimer (matching NewUI)
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: HearthNote(
        icon: Icons.info_outline,
        title: 'No community-verified matches found',
        text:
            'We found ${_providers.length} providers matching your search, but none have been community-verified for the identity tags you selected. These providers may still be a good match.',
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSpecialty =
        (widget.searchParams['specialties'] as List<String>?)?.isNotEmpty ==
        true;
    final includeNPI = widget.searchParams['includeNPI'] as bool? ?? false;
    final currentRadius = widget.searchParams['radius'] as int? ?? 10;
    final mamaApprovedOnly = widget.searchParams['mamaApprovedOnly'] == true;
    final hasIdentityTags =
        (widget.searchParams['identityTags'] as List?)?.isNotEmpty == true;

    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HearthIconChip(Icons.search_off, size: 64, iconSize: 30),
            const SizedBox(height: 16),
            Text(
              'No providers matched this search',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              mamaApprovedOnly
                  ? 'You searched for Mama Approved™ providers only. Few providers have enough reviews yet, so try turning that filter off.'
                  : 'That doesn\'t mean there is no care near you. A small change usually helps.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            HearthCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What to try next:',
                    style: hearthCardTitleStyle,
                  ),
                  const SizedBox(height: 12),
                  if (mamaApprovedOnly)
                    _buildSuggestion('Turn off "Mama Approved™ only"'),
                  _buildSuggestion(
                    'Widen your search radius (now $currentRadius miles)',
                  ),
                  if (!includeNPI)
                    _buildSuggestion(
                      'Use Expanded search and include the national provider list',
                    ),
                  _buildSuggestion('Choose "All plans" or a different health plan'),
                  if (hasSpecialty || hasIdentityTags)
                    _buildSuggestion('Remove a specialty or identity filter'),
                  _buildSuggestion('Try a nearby city or ZIP code'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                HearthButton.primary(
                  onPressed: () {
                    Navigator.pop(context); // Go back to search
                  },
                  icon: Icons.tune,
                  label: 'Adjust search',
                  expand: false,
                ),
                HearthButton.secondary(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddProviderScreen(),
                      ),
                    );
                  },
                  icon: Icons.add,
                  label: 'Add Provider',
                  expand: false,
                ),
                HearthButton.secondary(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => QualitativeSurveyDialog(
                        feature: 'provider-search',
                        questions: [
                          'I found providers I trust.',
                          'The search results were relevant to my needs.',
                          'I feel confident about the providers I found.',
                        ],
                        title: 'Provider Search Feedback',
                      ),
                    );
                  },
                  icon: Icons.chat_bubble_outline,
                  label: 'Feedback',
                  expand: false,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: AppTheme.brandPurple,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: hearthCardBodyStyle.copyWith(fontSize: 15, height: 22 / 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersInScrollView() {
    return HearthCard(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Within ${widget.searchParams['radius']} miles of ${(widget.searchParams['zip'] as String).length > 5 ? (widget.searchParams['zip'] as String).substring(0, 5) : widget.searchParams['zip']}',
                  style: hearthCardBodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              HearthButton.text(
                label: 'Edit filters',
                onPressed: () => Navigator.pop(context),
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
              if ((widget.searchParams['specialties'] as List?)?.isNotEmpty ==
                  true)
                _buildFilterChip('Specialty'),
              if ((widget.searchParams['identityTags'] as List?)?.isNotEmpty ==
                  true)
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
    final location = provider.locations.isNotEmpty
        ? provider.locations.first
        : null;
    // locations.first is the nearest location inside the search radius.
    final miles = provider.distanceMiles ?? location?.distance;
    final distance =
        miles != null ? '${miles.toStringAsFixed(1)} miles' : null;

    return HearthCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Initial on a warm band.
          Container(
            height: 88,
            color: AppTheme.tintWarm,
            alignment: Alignment.center,
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
              ),
              child: Text(
                provider.primaryDisplayName.isNotEmpty
                    ? provider.primaryDisplayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontFamily: AppTheme.serifFamily,
                  fontSize: 24,
                  height: 1,
                  color: AppTheme.brandPurple,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Tags
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                                  provider.primaryDisplayName,
                                  softWrap: true,
                                  style: hearthCardTitleStyle.copyWith(
                                    fontSize: 17,
                                    height: 24 / 17,
                                  ),
                                ),
                                const SizedBox(height: 4), // mb-1
                                Builder(
                                  builder: (context) {
                                    final parts = <String>[];
                                    final spec = provider.specialty?.trim();
                                    if (spec != null && spec.isNotEmpty) {
                                      parts.add(spec);
                                    }
                                    final legal = provider.name.trim();
                                    if (legal.isNotEmpty &&
                                        legal.toLowerCase() !=
                                            provider.primaryDisplayName
                                                .toLowerCase()) {
                                      parts.add(legal);
                                    }
                                    final sub = parts.join(' · ');
                                    if (sub.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      sub,
                                      style: hearthCardBodyStyle,
                                    );
                                  },
                                ),
                                if (provider.healthCoverageLabel != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 1),
                                        child: Icon(
                                          Icons.health_and_safety_outlined,
                                          size: 16,
                                          color: AppTheme.textMuted,
                                        ),
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
                                if (Provider.sourceCoverageLabel(provider.source) !=
                                    null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 1),
                                        child: Icon(
                                          Icons.description_outlined,
                                          size: 16,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Listing: ${Provider.sourceCoverageLabel(provider.source)}',
                                          style: hearthCaptionStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Provider Type Tags and Match Indicators. Status chips
                      // (Mama Approved™, Accepting) live here — below the name —
                      // so they never squeeze the name at large text sizes.
                      const SizedBox(height: 12),
                      // Mama Approved™ gets its own line so it never shares a
                      // row with (or squeezes) the other tags.
                      if (provider.showsMamaApprovedBadge) ...[
                        const MamaApprovedCommunityBadge(),
                        const SizedBox(height: 8),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (provider.acceptingNewPatients ?? false)
                            const HearthTag('✓ Accepting new patients'),

                          // Provider Type Tags (only show types with display names)
                          ...provider.providerTypes
                              .where(
                                (typeId) =>
                                    ProviderTypes.getDisplayName(typeId) !=
                                    null,
                              ) // Filter out codes without display names
                              .map((typeId) {
                                final typeName = ProviderTypes.getDisplayName(
                                  typeId,
                                )!; // Safe to use ! since we filtered
                                final isMatched = searchProviderTypeIds.any((
                                  searchId,
                                ) {
                                  // Normalize to API format (single digits 1-9 WITH leading zeros: "01", "02", "09")
                                  final normalizedSearch =
                                      int.tryParse(searchId) != null &&
                                          int.parse(searchId) >= 1 &&
                                          int.parse(searchId) <= 9
                                      ? searchId.padLeft(
                                          2,
                                          '0',
                                        ) // Add leading zero (API format: "01", "09")
                                      : searchId;
                                  final normalizedType =
                                      int.tryParse(typeId) != null &&
                                          int.parse(typeId) >= 1 &&
                                          int.parse(typeId) <= 9
                                      ? typeId.padLeft(
                                          2,
                                          '0',
                                        ) // Add leading zero (API format: "01", "09")
                                      : typeId;
                                  return normalizedSearch == normalizedType;
                                });

                                // Matched types are tinted with a check;
                                // the rest are outlined.
                                return isMatched
                                    ? HearthTag(
                                        typeName,
                                        icon: Icons.check_circle_outline,
                                      )
                                    : _OutlineTag(typeName);
                              }),

                          // Identity Tags (including BIPOC)
                          ...provider.identityTags.map((tag) {
                            final isVerified =
                                tag.verificationStatus == 'verified';
                            final isBipoc = tag.name.toLowerCase() == 'bipoc';

                            // Verified (and BIPOC) tags carry a check; pending
                            // ones are plain. No green or blue in Hearth.
                            return _OutlineTag(
                              tag.name,
                              icon: isBipoc
                                  ? Icons.verified_outlined
                                  : (isVerified
                                        ? Icons.check_circle_outline
                                        : null),
                            );
                          }),

                          // Match Score Indicator
                          if (matchScore > 0)
                            HearthTag(
                              '$matchScore filter${matchScore > 1 ? 's' : ''} match',
                              tone: HearthTagTone.tintPurple,
                              icon: Icons.star_outline_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rating
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          // Gold star with a dark rim, as in HearthStarRating;
                          // an empty outline when there is no rating yet.
                          if (provider.rating != null && provider.rating! > 0)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 20,
                                    color: AppTheme.starStroke,
                                  ),
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: AppTheme.brandGold,
                                  ),
                                ],
                              ),
                            )
                          else
                            const Icon(
                              Icons.star_outline_rounded,
                              size: 20,
                              color: AppTheme.brandTerracotta,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            provider.rating != null && provider.rating! > 0
                                ? Provider.formatAverageRating(provider.rating!)
                                : 'N/A',
                            style: hearthCardTitleStyle.copyWith(
                              fontSize: 17,
                              height: 24 / 17,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '(${provider.reviewCount ?? 0} review${(provider.reviewCount ?? 0) == 1 ? '' : 's'})',
                          style: hearthCardBodyStyle.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick info — distance + multiline address
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceInset,
                    borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppTheme.brandPurple,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (distance != null) ...[
                                  Text(
                                    distance!,
                                    style: hearthCaptionStyle.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  if (location != null &&
                                      location!.addressLines.isNotEmpty)
                                    const SizedBox(height: 2),
                                ],
                                if (location != null)
                                  ...location!.addressLines.map(
                                    (line) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        line,
                                        style: hearthCaptionStyle.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (location == null && distance == null)
                                  Text(
                                    'Address not listed',
                                    style: hearthCaptionStyle,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (provider.phone != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: AppTheme.brandPurple,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatPhoneNumber(provider.phone!),
                                style: hearthCaptionStyle.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Specialties (if available)
                if (provider.specialties.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.specialties.take(3).map((specialty) {
                        return _OutlineTag(specialty);
                      }).toList(),
                    ),
                  ),
                ],

                // Action Buttons (matching NewUI)
                Row(
                  children: [
                    Expanded(
                      child: HearthButton.primary(
                        label: 'View full profile',
                        onPressed: onTap,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (provider.phone != null)
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () async {
                            final uri = Uri.parse('tel:${provider.phone}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(52, 52),
                            shape: const CircleBorder(),
                            side: const BorderSide(
                              color: AppTheme.brandPurple,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.phone_outlined,
                            color: AppTheme.brandPurple,
                            size: 20,
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

/// Outlined variant of [HearthTag] for secondary tags (specialties, identity,
/// unmatched provider types), so they sit back from the tinted ones.
class _OutlineTag extends StatelessWidget {
  const _OutlineTag(this.text, {this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: AppTheme.ground,
        shape: StadiumBorder(side: BorderSide(color: AppTheme.borderWarm)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: AppTheme.brandPurple),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 12,
                  height: 18 / 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
