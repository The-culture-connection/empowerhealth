import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/provider.dart';
import '../services/provider_repository.dart';
import '../cors/ui_theme.dart';
import '../widgets/provider_search_loading.dart';
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

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    print('🔍 [ResultsScreen] Search started');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 [ResultsScreen] Calling repository.searchProviders...');
      final results = await _repository.searchProviders(
        zip: widget.searchParams['zip'] as String,
        city: widget.searchParams['city'] as String,
        healthPlan: widget.searchParams['healthPlan'] as String,
        providerTypeIds: widget.searchParams['providerTypeIds'] as List<String>,
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

      // Calculate match score for each provider
      final providersWithScores = results.map((provider) {
        int matchScore = 0;
        final matchedFilters = <String>[];

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

      // Sort by: Mama Approved first, then match score, then rating
      providersWithScores.sort((a, b) {
        final providerA = a['provider'] as Provider;
        final providerB = b['provider'] as Provider;
        
        // Mama Approved providers first
        if (providerA.mamaApproved && !providerB.mamaApproved) return -1;
        if (!providerA.mamaApproved && providerB.mamaApproved) return 1;
        
        // Then by match score
        final scoreA = a['matchScore'] as int;
        final scoreB = b['matchScore'] as int;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA); // Higher score first
        }
        
        // If scores are equal, sort by rating
        final ratingA = providerA.rating ?? 0.0;
        final ratingB = providerB.rating ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      // Extract providers and store match info, calculate ratings from reviews
      final filtered = await Future.wait(providersWithScores.map((item) async {
        final provider = item['provider'] as Provider;
        // Debug: log rating info
        print('🔍 [ResultsScreen] Provider: ${provider.name}, Rating: ${provider.rating}, ReviewCount: ${provider.reviewCount}, ID: ${provider.id}');
        
        // If provider has no rating but has an ID, try to calculate from reviews
        if ((provider.rating == null || provider.rating == 0) && provider.id != null && provider.id!.isNotEmpty) {
          try {
            final reviews = await _repository.getProviderReviews(provider.id!);
            if (reviews.isNotEmpty) {
              final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
              final averageRating = totalRating / reviews.length;
              print('✅ [ResultsScreen] Calculated rating for ${provider.name}: $averageRating from ${reviews.length} reviews');
              return provider.copyWith(
                rating: averageRating,
                reviewCount: reviews.length,
              );
            }
          } catch (e) {
            print('⚠️ [ResultsScreen] Could not calculate rating for ${provider.id}: $e');
          }
        }
        return provider;
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF8F6F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_providers.length} providers near ${widget.searchParams['city']}, OH',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filters Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3E5F5), Color(0xFFE3F2FD)],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade100),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Edit filters',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF663399),
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
              ),

              // Sort & Results
              Expanded(
                child: _isLoading
                    ? const ProviderSearchLoading()
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading providers',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _performSearch,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              print('🔍 [ResultsScreen] Build: _providers.length = ${_providers.length}, _isLoading = $_isLoading, _error = $_error');
                              if (_providers.isEmpty) {
                                print('🔍 [ResultsScreen] Rendering empty state');
                                return _buildEmptyState();
                              } else {
                                print('🔍 [ResultsScreen] Rendering provider list with ${_providers.length} providers');
                                return Column(
                                children: [
                                  // Result count and sort - matching NewUI
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_providers.length} providers near you',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _sortBy,
                                            underline: const SizedBox(),
                                            isDense: true,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Highest rated',
                                                child: Text('Highest rated'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Most reviewed',
                                                child: Text('Most reviewed'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Nearest',
                                                child: Text('Nearest'),
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
                                  
                                  // Cultural match disclaimer if identity tags selected but no verified matches
                                  if ((widget.searchParams['identityTags'] as List?)?.isNotEmpty == true)
                                    _buildCulturalMatchDisclaimer(),

                                  // Results List with filters and disclaimer in scroll view
                                  Expanded(
                                    child: ListView(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      children: [
                                        // Filters header in scroll view
                                        _buildFiltersInScrollView(),
                                        
                                        // Disclaimer in scroll view
                                        if ((widget.searchParams['identityTags'] as List?)?.isNotEmpty == true)
                                          _buildCulturalMatchDisclaimer(),
                                        
                                        // Provider cards
                                        ..._providers.map((provider) => _ProviderCard(
                                          provider: provider,
                                          repository: _repository,
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
                                        )),
                                      ],
                                    ),
                                  ),
                                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
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
    
    // No verified matches found - show disclaimer
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No community-verified matches found',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We found ${_providers.length} providers matching your search, but none have been community-verified for the identity tags you selected. These providers may still be a good match.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade800,
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E5F5), Color(0xFFE3F2FD)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Within ${widget.searchParams['radius']} miles of ${(widget.searchParams['zip'] as String).length > 5 ? (widget.searchParams['zip'] as String).substring(0, 5) : widget.searchParams['zip']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Edit filters',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF663399),
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
    print('🔍 [ResultsScreen] Search started');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 [ResultsScreen] Calling repository.searchProviders...');
      final results = await _repository.searchProviders(
        zip: widget.searchParams['zip'] as String,
        city: widget.searchParams['city'] as String,
        healthPlan: widget.searchParams['healthPlan'] as String,
        providerTypeIds: widget.searchParams['providerTypeIds'] as List<String>,
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

      // Calculate match score for each provider
      final providersWithScores = results.map((provider) {
        int matchScore = 0;
        final matchedFilters = <String>[];

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

      // Sort by: Mama Approved first, then match score, then rating
      providersWithScores.sort((a, b) {
        final providerA = a['provider'] as Provider;
        final providerB = b['provider'] as Provider;
        
        // Mama Approved providers first
        if (providerA.mamaApproved && !providerB.mamaApproved) return -1;
        if (!providerA.mamaApproved && providerB.mamaApproved) return 1;
        
        // Then by match score
        final scoreA = a['matchScore'] as int;
        final scoreB = b['matchScore'] as int;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA); // Higher score first
        }
        
        // If scores are equal, sort by rating
        final ratingA = providerA.rating ?? 0.0;
        final ratingB = providerB.rating ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      // Extract providers and store match info, calculate ratings from reviews
      final filtered = await Future.wait(providersWithScores.map((item) async {
        final provider = item['provider'] as Provider;
        // Debug: log rating info
        print('🔍 [ResultsScreen] Provider: ${provider.name}, Rating: ${provider.rating}, ReviewCount: ${provider.reviewCount}, ID: ${provider.id}');
        
        // If provider has no rating but has an ID, try to calculate from reviews
        if ((provider.rating == null || provider.rating == 0) && provider.id != null && provider.id!.isNotEmpty) {
          try {
            final reviews = await _repository.getProviderReviews(provider.id!);
            if (reviews.isNotEmpty) {
              final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
              final averageRating = totalRating / reviews.length;
              print('✅ [ResultsScreen] Calculated rating for ${provider.name}: $averageRating from ${reviews.length} reviews');
              return provider.copyWith(
                rating: averageRating,
                reviewCount: reviews.length,
              );
            }
          } catch (e) {
            print('⚠️ [ResultsScreen] Could not calculate rating for ${provider.id}: $e');
          }
        }
        return provider;
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF8F6F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_providers.length} providers near ${widget.searchParams['city']}, OH',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filters Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3E5F5), Color(0xFFE3F2FD)],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade100),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Edit filters',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF663399),
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
              ),

              // Sort & Results
              Expanded(
                child: _isLoading
                    ? const ProviderSearchLoading()
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading providers',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _performSearch,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              print('🔍 [ResultsScreen] Build: _providers.length = ${_providers.length}, _isLoading = $_isLoading, _error = $_error');
                              if (_providers.isEmpty) {
                                print('🔍 [ResultsScreen] Rendering empty state');
                                return _buildEmptyState();
                              } else {
                                print('🔍 [ResultsScreen] Rendering provider list with ${_providers.length} providers');
                                return Column(
                                children: [
                                  // Result count and sort - matching NewUI
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_providers.length} providers near you',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _sortBy,
                                            underline: const SizedBox(),
                                            isDense: true,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Highest rated',
                                                child: Text('Highest rated'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Most reviewed',
                                                child: Text('Most reviewed'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Nearest',
                                                child: Text('Nearest'),
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
                                  
                                  // Cultural match disclaimer if identity tags selected but no verified matches
                                  if ((widget.searchParams['identityTags'] as List?)?.isNotEmpty == true)
                                    _buildCulturalMatchDisclaimer(),

                                  // Results List with filters and disclaimer in scroll view
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: _providers.length + 2, // +2 for filters and disclaimer
                                      itemBuilder: (context, index) {
                                        // Filters header (index 0)
                                        if (index == 0) {
                                          return _buildFiltersInScrollView();
                                        }
                                        
                                        // Disclaimer (index 1)
                                        if (index == 1) {
                                          if ((widget.searchParams['identityTags'] as List?)?.isNotEmpty == true) {
                                            return _buildCulturalMatchDisclaimer();
                                          }
                                          return const SizedBox.shrink();
                                        }
                                        
                                        // Provider cards (index 2+)
                                        final providerIndex = index - 2;
                                        return _ProviderCard(
                                          provider: _providers[providerIndex],
                                          repository: _repository,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ProviderProfileScreen(
                                                  provider: _providers[providerIndex], // Pass provider directly
                                                  providerId: _providers[providerIndex].id, // Also pass ID if available
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
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
    
    // No verified matches found - show disclaimer
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No community-verified matches found',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We found ${_providers.length} providers matching your search, but none have been community-verified for the identity tags you selected. These providers may still be a good match.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade800,
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E5F5), Color(0xFFE3F2FD)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Within ${widget.searchParams['radius']} miles of ${(widget.searchParams['zip'] as String).length > 5 ? (widget.searchParams['zip'] as String).substring(0, 5) : widget.searchParams['zip']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Edit filters',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF663399),
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
