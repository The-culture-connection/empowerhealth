import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider.dart';
import '../models/provider_review.dart';
import 'ohio_medicaid_directory_service.dart';
import 'npi_registry_service.dart';
import '../constants/provider_types.dart';

class ProviderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OhioMedicaidDirectoryService _medicaidService = OhioMedicaidDirectoryService();
  final NpiRegistryService _npiService = NpiRegistryService();

  /// Search providers combining Medicaid and NPI results
  /// Pregnancy-Smart filters only to keep URLs manageable
  Future<List<Provider>> searchProviders({
    required String zip,
    required String city,
    required String healthPlan,
    required List<String> providerTypeIds,
    required int radius,
    String? specialty,
    bool includeNpi = false,
    // Pregnancy-Smart optional filters
    bool? acceptsPregnantWomen,
    bool? acceptsNewborns,
    bool? telehealth,
  }) async {
    final List<Provider> allProviders = [];

    try {
      // Validate provider type IDs
      print('🔍 [ProviderRepository] Starting search');
      print('🔍 [ProviderRepository] ZIP: $zip, City: $city, Health Plan: $healthPlan');
      print('🔍 [ProviderRepository] Provider type IDs: $providerTypeIds');
      print('🔍 [ProviderRepository] Radius: $radius, Specialty: $specialty');
      print('🔍 [ProviderRepository] Include NPI: $includeNpi');
      
      // Ensure provider type IDs have leading zeros
      final validatedProviderTypeIds = providerTypeIds.map((id) {
        // Ensure leading zeros are preserved (e.g., "09" not "9")
        final numId = int.tryParse(id);
        if (numId != null && numId < 10) {
          return id.padLeft(2, '0');
        }
        return id;
      }).toList();
      
      print('🔍 [ProviderRepository] Validated provider type IDs: $validatedProviderTypeIds');

      // Search Medicaid directory
      List<Provider> medicaidProviders = [];
      try {
        medicaidProviders = await _medicaidService.searchProviders(
          zip: zip,
          city: city,
          healthPlan: healthPlan,
          providerTypeIds: validatedProviderTypeIds,
          radius: radius,
          specialty: specialty,
          // Pregnancy-Smart filters only
          acceptsPregnantWomen: acceptsPregnantWomen,
          acceptsNewborns: acceptsNewborns,
          telehealth: telehealth,
        );
        print('✅ [ProviderRepository] Medicaid returned ${medicaidProviders.length} providers');
      } catch (e) {
        print('❌ [ProviderRepository] Medicaid search failed: $e');
        // Continue to NPI search if enabled
      }

      allProviders.addAll(medicaidProviders);

      // If zero results or NPI toggle is on, search NPI
      if (includeNpi || medicaidProviders.isEmpty) {
        try {
          // NPI requires specialty or mappable provider types
          if (specialty == null || specialty.isEmpty) {
            // Check if we can infer from provider types
            final canInferTaxonomy = validatedProviderTypeIds.any((id) => 
              ['09', '01', '71', '46', '44', '19', '20'].contains(id));
            
            if (!canInferTaxonomy) {
              print('⚠️ [ProviderRepository] NPI search skipped: no specialty and provider types cannot be mapped to NPI taxonomy');
              // Don't throw - just skip NPI search
            } else {
              final npiProviders = await _npiService.searchProviders(
                state: 'OH',
                specialty: specialty,
                zip: zip,
                city: city,
                providerTypeIds: validatedProviderTypeIds,
              );
              print('✅ [ProviderRepository] NPI returned ${npiProviders.length} providers');
              allProviders.addAll(npiProviders);
            }
          } else {
            try {
              final npiProviders = await _npiService.searchProviders(
                state: 'OH',
                specialty: specialty,
                zip: zip,
                city: city,
                providerTypeIds: validatedProviderTypeIds,
              );
              print('✅ [ProviderRepository] NPI returned ${npiProviders.length} providers');
              allProviders.addAll(npiProviders);
            } catch (e) {
              // If NPI fails due to missing criteria, log but don't fail the whole search
              if (e.toString().contains('Select a specialty') || 
                  e.toString().contains('cannot be searched')) {
                print('ℹ️ [ProviderRepository] NPI search skipped: $e');
              } else {
                rethrow; // Re-throw other errors
              }
            }
          }
        } catch (e) {
          print('❌ [ProviderRepository] NPI search failed: $e');
          // Continue with Medicaid results only - don't throw, just log
        }
      }

      print('✅ [ProviderRepository] Total providers before enrichment: ${allProviders.length}');

      // Merge with Firestore data (identity tags, Mama Approved status, reviews)
      final enriched = await _enrichProvidersWithFirestoreData(allProviders);
      print('✅ [ProviderRepository] Total providers after enrichment: ${enriched.length}');
      
      return enriched;
    } catch (e, stackTrace) {
      print('❌ [ProviderRepository] Error searching providers: $e');
      print('❌ [ProviderRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Enrich providers with Firestore data (identity tags, Mama Approved, reviews)
  /// This is non-blocking - Firestore errors will not cause providers to be dropped
  Future<List<Provider>> _enrichProvidersWithFirestoreData(List<Provider> providers) async {
    final enrichedProviders = <Provider>[];
    var enrichmentErrors = 0;
    var enrichmentSuccesses = 0;

    print('🔍 [ProviderRepository] Starting enrichment for ${providers.length} providers');

    for (var i = 0; i < providers.length; i++) {
      final provider = providers[i];
      try {
        // Try to find existing provider by NPI or name+location match
        // Wrap in try/catch to handle permission errors gracefully
        Provider? firestoreProvider;
        try {
          firestoreProvider = await _findProviderInFirestore(provider);
        } catch (e) {
          // Firestore permission errors or other errors - log once per 10 providers to avoid spam
          if (enrichmentErrors % 10 == 0) {
            print('⚠️ [ProviderRepository] Firestore enrichment error (logged once per 10): ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}');
          }
          enrichmentErrors++;
          // Continue with original provider - don't drop it
          firestoreProvider = null;
        }

        if (firestoreProvider != null) {
          // Merge: Use API data but add Firestore enrichments
          enrichedProviders.add(provider.copyWith(
            id: firestoreProvider.id,
            mamaApproved: firestoreProvider.mamaApproved,
            mamaApprovedCount: firestoreProvider.mamaApprovedCount,
            identityTags: firestoreProvider.identityTags,
            rating: firestoreProvider.rating,
            reviewCount: firestoreProvider.reviewCount,
            acceptingNewPatients: firestoreProvider.acceptingNewPatients,
          ));
          enrichmentSuccesses++;
        } else {
          // New provider or Firestore lookup failed - just add as-is
          enrichedProviders.add(provider);
        }
      } catch (e) {
        // Catch any other errors during enrichment
        if (enrichmentErrors % 10 == 0) {
          print('⚠️ [ProviderRepository] Error enriching provider ${provider.name}: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}');
        }
        enrichmentErrors++;
        // Always add the provider - never drop it due to enrichment errors
        enrichedProviders.add(provider);
      }
    }

    print('✅ [ProviderRepository] Enrichment complete: ${enrichmentSuccesses} enriched, ${enrichmentErrors} errors (providers not dropped)');
    print('✅ [ProviderRepository] Final provider count: ${enrichedProviders.length} (input: ${providers.length})');

    // Ensure we never return fewer providers than we started with
    if (enrichedProviders.length < providers.length) {
      print('❌ [ProviderRepository] CRITICAL: Enrichment dropped providers! Input: ${providers.length}, Output: ${enrichedProviders.length}');
      // This should never happen, but if it does, return original list
      return providers;
    }

    return enrichedProviders;
  }

  /// Find provider in Firestore by NPI or name+location match
  /// Returns null on any error (permission-denied, not found, etc.)
  /// This method should never throw - all errors are caught and return null
  Future<Provider?> _findProviderInFirestore(Provider provider) async {
    try {
      // Try by NPI first
      if (provider.npi != null && provider.npi!.isNotEmpty) {
        try {
          final query = await _firestore
              .collection('providers')
              .where('npi', isEqualTo: provider.npi)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            return Provider.fromMap(query.docs.first.data(), id: query.docs.first.id);
          }
        } catch (e) {
          // Permission denied or other Firestore error - return null silently
          // Error is logged at enrichment level to avoid spam
          return null;
        }
      }

      // Try by name + city match (only if NPI lookup failed)
      // Note: This query may also fail due to permissions or missing index
      if (provider.locations.isNotEmpty) {
        try {
          final city = provider.locations.first.city;
          if (city.isNotEmpty) {
            final query = await _firestore
                .collection('providers')
                .where('name', isEqualTo: provider.name)
                .where('locations.city', isEqualTo: city)
                .limit(1)
                .get();

            if (query.docs.isNotEmpty) {
              return Provider.fromMap(query.docs.first.data(), id: query.docs.first.id);
            }
          }
        } catch (e) {
          // Permission denied or other Firestore error - return null silently
          // Error is logged at enrichment level to avoid spam
          return null;
        }
      }
    } catch (e) {
      // Catch any unexpected errors
      return null;
    }

    return null;
  }

  /// Get provider by ID from Firestore
  Future<Provider?> getProvider(String providerId) async {
    try {
      final doc = await _firestore.collection('providers').doc(providerId).get();
      if (doc.exists) {
        return Provider.fromMap(doc.data()!, id: doc.id);
      }
    } catch (e) {
      print('❌ Error getting provider: $e');
    }
    return null;
  }

  /// Get reviews for a provider
  /// Can search by Firestore ID, NPI (with 'npi_' prefix), or composite API ID
  Future<List<ProviderReview>> getProviderReviews(String providerId) async {
    try {
      print('🔍 [ProviderRepository] Getting reviews for providerId: $providerId');
      
      // If providerId starts with 'npi_', try to find Firestore provider first
      if (providerId.startsWith('npi_')) {
        final npi = providerId.substring(4);
        print('🔍 [ProviderRepository] NPI-based ID detected, NPI: $npi');
        
        // First find provider by NPI, then get reviews
        try {
          final providerQuery = await _firestore
              .collection('providers')
              .where('npi', isEqualTo: npi)
              .limit(1)
              .get();
          
          if (providerQuery.docs.isNotEmpty) {
            final firestoreProviderId = providerQuery.docs.first.id;
            print('✅ [ProviderRepository] Found Firestore provider with ID: $firestoreProviderId');
            // Search reviews by Firestore ID
            final reviewsQuery = await _firestore
                .collection('reviews')
                .where('providerId', isEqualTo: firestoreProviderId)
                .get();
            
        // Sort in memory to avoid index requirement and deduplicate
        final reviews = reviewsQuery.docs
            .map((doc) => ProviderReview.fromMap(doc.data(), id: doc.id))
            .toList();
        
        // Deduplicate reviews
        final uniqueReviews = <String, ProviderReview>{};
        for (final review in reviews) {
          if (review.id != null) {
            uniqueReviews[review.id!] = review;
          } else {
            final key = '${review.userId}_${review.providerId}_${review.rating}_${review.createdAt.millisecondsSinceEpoch}';
            if (!uniqueReviews.containsKey(key)) {
              uniqueReviews[key] = review;
            }
          }
        }
        
        final deduplicatedReviews = uniqueReviews.values.toList();
        deduplicatedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('✅ [ProviderRepository] Found ${reviews.length} reviews by Firestore ID, ${deduplicatedReviews.length} unique');
        return deduplicatedReviews.take(50).toList();
          }
        } catch (e) {
          print('⚠️ [ProviderRepository] Error finding Firestore provider by NPI: $e');
        }
        
        // If no Firestore provider found, search reviews by the NPI-based ID
        print('🔍 [ProviderRepository] Searching reviews by NPI-based ID: $providerId');
        final reviewsQuery = await _firestore
            .collection('reviews')
            .where('providerId', isEqualTo: providerId)
            .get();
        
        final reviews = reviewsQuery.docs
            .map((doc) => ProviderReview.fromMap(doc.data(), id: doc.id))
            .toList();
        
        // Deduplicate reviews
        final uniqueReviews = <String, ProviderReview>{};
        for (final review in reviews) {
          if (review.id != null) {
            uniqueReviews[review.id!] = review;
          } else {
            final key = '${review.userId}_${review.providerId}_${review.rating}_${review.createdAt.millisecondsSinceEpoch}';
            if (!uniqueReviews.containsKey(key)) {
              uniqueReviews[key] = review;
            }
          }
        }
        
        final deduplicatedReviews = uniqueReviews.values.toList();
        deduplicatedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('✅ [ProviderRepository] Found ${reviews.length} reviews by NPI-based ID, ${deduplicatedReviews.length} unique');
        return deduplicatedReviews.take(50).toList();
      }
      
      // Standard search by providerId
      print('🔍 [ProviderRepository] Searching reviews by providerId: $providerId');
      final query = await _firestore
          .collection('reviews')
          .where('providerId', isEqualTo: providerId)
          .get();

      // Sort in memory to avoid index requirement
      final reviews = query.docs
          .map((doc) => ProviderReview.fromMap(doc.data(), id: doc.id))
          .toList();
      
      // Deduplicate reviews by ID (in case of any duplicates)
      final uniqueReviews = <String, ProviderReview>{};
      for (final review in reviews) {
        if (review.id != null) {
          uniqueReviews[review.id!] = review;
        } else {
          // If no ID, use a combination of userId, providerId, rating, and createdAt as key
          final key = '${review.userId}_${review.providerId}_${review.rating}_${review.createdAt.millisecondsSinceEpoch}';
          if (!uniqueReviews.containsKey(key)) {
            uniqueReviews[key] = review;
          }
        }
      }
      
      final deduplicatedReviews = uniqueReviews.values.toList();
      deduplicatedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('✅ [ProviderRepository] Found ${reviews.length} reviews, ${deduplicatedReviews.length} unique');
      return deduplicatedReviews.take(50).toList();
    } catch (e, stackTrace) {
      print('❌ [ProviderRepository] Error getting reviews: $e');
      print('❌ [ProviderRepository] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Submit a provider review
  /// Prevents duplicates by checking for existing review from same user for same provider within last minute
  Future<void> submitProviderReview(ProviderReview review) async {
    try {
      print('💾 [ProviderRepository] Submitting review for providerId: ${review.providerId}');
      print('💾 [ProviderRepository] Review data: rating=${review.rating}, wouldRecommend=${review.wouldRecommend}, hasText=${review.reviewText != null}');
      
      // Check for duplicate review (same user, same provider, within last 2 minutes)
      // Query without orderBy to avoid index requirement, then filter in memory
      final now = DateTime.now();
      final twoMinutesAgo = now.subtract(const Duration(minutes: 2));
      
      final existingReviewsQuery = await _firestore
          .collection('reviews')
          .where('providerId', isEqualTo: review.providerId)
          .where('userId', isEqualTo: review.userId)
          .get();
      
      // Filter in memory for recent reviews
      final recentReviews = existingReviewsQuery.docs.where((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp) {
          return createdAt.toDate().isAfter(twoMinutesAgo);
        }
        return false;
      }).toList();
      
      if (recentReviews.isNotEmpty) {
        print('⚠️ [ProviderRepository] Duplicate review detected (${recentReviews.length} recent reviews), skipping save');
        throw Exception('You have already submitted a review for this provider recently. Please wait a moment.');
      }
      
      final reviewData = review.toMap();
      print('💾 [ProviderRepository] Review map keys: ${reviewData.keys.toList()}');
      
      final docRef = await _firestore.collection('reviews').add(reviewData);
      print('✅ [ProviderRepository] Review saved with ID: ${docRef.id}');
    } catch (e, stackTrace) {
      print('❌ [ProviderRepository] Error submitting review: $e');
      print('❌ [ProviderRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Submit a provider for moderation
  Future<void> submitProvider(Provider provider, {String? userId, String? notes}) async {
    try {
      await _firestore.collection('provider_submissions').add({
        'provider': provider.toMap(),
        'submittedBy': userId,
        'notes': notes,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error submitting provider: $e');
      rethrow;
    }
  }

  /// Save provider to favorites
  Future<void> saveProvider(String userId, String providerId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_providers')
          .doc(providerId)
          .set({
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error saving provider: $e');
      rethrow;
    }
  }

  /// Remove provider from favorites
  Future<void> unsaveProvider(String userId, String providerId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_providers')
          .doc(providerId)
          .delete();
    } catch (e) {
      print('❌ Error unsaving provider: $e');
      rethrow;
    }
  }

  /// Check if provider is saved
  Future<bool> isProviderSaved(String userId, String providerId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_providers')
          .doc(providerId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
