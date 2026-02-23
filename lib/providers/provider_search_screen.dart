import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_router.dart';
import '../services/provider_repository.dart';
import '../services/firebase_functions_service.dart';
import '../models/provider.dart';
import '../constants/provider_types.dart';
import '../cors/ui_theme.dart';
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
      
      // Sort: Mama Approved first, then by review count, then by rating
      providers.sort((a, b) {
        if (a.mamaApproved && !b.mamaApproved) return -1;
        if (!a.mamaApproved && b.mamaApproved) return 1;
        
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
    return Scaffold(
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
                                color: Color(0xFFF97316), // orange-500
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
                  const SizedBox(height: 20), // mb-5
                  // Search Bar
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.providerSearch);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24), // rounded-2xl
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search by name, location, or specialty...',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
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
                              // Mama Approved Section
                              Container(
                                padding: const EdgeInsets.all(16), // p-4
                                decoration: BoxDecoration(
                                  color: Color(0xFFFEF9F5), // warm background
                                  borderRadius: BorderRadius.circular(24), // rounded-3xl
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFFEF3F3), // rose-50
                                            Color(0xFFFFF0F8), // pink-50
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.verified,
                                        color: Color(0xFFE11D48), // rose-600
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Mama Approved™ providers',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Verified by community trust indicators and identity transparency.',
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
                                  color: Colors.white,
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
                                            color: Colors.white,
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
              onPressed: () {
                Navigator.pushNamed(context, Routes.providerSearch);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
                foregroundColor: Colors.white,
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
        color: Colors.white,
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
                                provider.name,
                                style: TextStyle(
                                  fontSize: 18, // text-lg
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (provider.mamaApproved)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: Color(0xFFE11D48), // rose-600
                                ),
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
                        if (provider.practiceName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            provider.practiceName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w300,
                            ),
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
