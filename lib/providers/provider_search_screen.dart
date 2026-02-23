import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_router.dart';
import '../services/provider_repository.dart';
import '../services/firebase_functions_service.dart';
import '../models/provider.dart';
import 'provider_profile_screen.dart';
import 'add_provider_screen.dart';

class ProviderSearchScreen extends StatefulWidget {
  const ProviderSearchScreen({super.key});

  @override
  State<ProviderSearchScreen> createState() => _ProviderSearchScreenState();
}

class _ProviderSearchScreenState extends State<ProviderSearchScreen> {
  final ProviderRepository _repository = ProviderRepository();
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  List<Provider> _reviewedProviders = [];
  bool _isLoadingProviders = true;

  // Admin user IDs
  static const List<String> _adminUserIds = [
    'weKLwLgHegeMKv87ArTbYBMm64M2', // msrinntaylor@gmail.com
    'UVuNYbfrtGNlZYTVEu7w5UQPzI62', // gshort03@gmail.com
  ];

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && _adminUserIds.contains(user.uid);
  }

  @override
  void initState() {
    super.initState();
    _loadReviewedProviders();
  }

  Future<void> _loadReviewedProviders() async {
    try {
      print('🔍 [ProviderSearch] Loading top-rated providers...');
      
      // Query providers with reviews, sorted by reviewCount (highest first)
      // If index doesn't exist, fall back to getting all providers and sorting in memory
      QuerySnapshot providersQuery;
      try {
        providersQuery = await FirebaseFirestore.instance
            .collection('providers')
            .where('reviewCount', isGreaterThan: 0)
            .orderBy('reviewCount', descending: true)
            .limit(20) // Get more to sort by Mama Approved
            .get();
      } catch (e) {
        // If index doesn't exist, get all providers and filter/sort in memory
        print('⚠️ [ProviderSearch] Index error, falling back to in-memory sort: $e');
        providersQuery = await FirebaseFirestore.instance
            .collection('providers')
            .limit(100) // Get more to filter
            .get();
      }
      
      print('✅ [ProviderSearch] Found ${providersQuery.docs.length} providers');
      
      // Load providers and filter/sort
      final providers = <Provider>[];
      for (var doc in providersQuery.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final reviewCount = data['reviewCount'] as int? ?? 0;
          
          // Only include providers with reviews
          if (reviewCount > 0) {
            final provider = Provider.fromMap(data, id: doc.id);
            providers.add(provider);
            print('✅ [ProviderSearch] Loaded provider: ${provider.name}, rating: ${provider.rating}, reviews: ${provider.reviewCount}, Mama Approved: ${provider.mamaApproved}');
          }
        } catch (e) {
          print('⚠️ [ProviderSearch] Error parsing provider ${doc.id}: $e');
        }
      }
      
      // Sort: Mama Approved first, then by review count (highest first), then by rating
      providers.sort((a, b) {
        // Mama Approved first
        if (a.mamaApproved && !b.mamaApproved) return -1;
        if (!a.mamaApproved && b.mamaApproved) return 1;
        
        // Then by review count (highest first)
        final countA = a.reviewCount ?? 0;
        final countB = b.reviewCount ?? 0;
        if (countA != countB) {
          return countB.compareTo(countA);
        }
        
        // Then by rating (highest first)
        final ratingA = a.rating ?? 0.0;
        final ratingB = b.rating ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
      
      // Take top 10 after sorting
      final topProviders = providers.take(10).toList();
      
      print('✅ [ProviderSearch] Loaded ${topProviders.length} top-rated providers (${topProviders.where((p) => p.mamaApproved).length} Mama Approved)');
      
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Hero Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF663399), Color(0xFF8855BB)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Find Your Care Team',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_isAdmin)
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                            tooltip: 'Upload Mama Approved Provider',
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddProviderScreen(
                                    isMamaApproved: true, // Mark as Mama Approved
                                  ),
                                ),
                              );
                              if (result == true) {
                                // Reload providers after adding
                                _loadReviewedProviders();
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trusted providers reviewed by mothers like you',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, Routes.providerSearch);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[400]),
                            const SizedBox(width: 12),
                            Text(
                              'Search providers, specialties, or location',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content - Show reviewed providers or landing page
              Expanded(
                child: _isLoadingProviders
                    ? const Center(child: CircularProgressIndicator())
                    : _reviewedProviders.isNotEmpty
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Top-Rated Providers',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._reviewedProviders.map((provider) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF663399),
                                        child: Text(
                                          provider.name.isNotEmpty
                                              ? provider.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(
                                        provider.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        provider.specialty ?? 'Provider',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: provider.rating != null && provider.rating! > 0
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.star, size: 16, color: Colors.amber),
                                                const SizedBox(width: 4),
                                                Text(
                                                  provider.rating!.toStringAsFixed(1),
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            )
                                          : null,
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
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 24),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, Routes.providerSearch);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF663399),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Search More Providers',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 64,
                                    color: Colors.purple.shade300,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Find Your Care Team',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Search for trusted providers reviewed by mothers like you',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, Routes.providerSearch);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF663399),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Start Searching',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
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
}

