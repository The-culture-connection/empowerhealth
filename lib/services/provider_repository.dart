import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider.dart';
import '../models/provider_review.dart';
import 'firebase_functions_service.dart';
import '../constants/provider_types.dart';

class ProviderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();

  /// Search providers using Firebase function
  /// This calls the Cloud Function which handles Medicaid + NPI API calls and enrichment
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
    try {
      // Validate provider type IDs
      print('🔍 [ProviderRepository] Starting search via Firebase function');
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

      // Call Firebase function
      final result = await _functionsService.searchProviders(
        zip: zip,
        city: city,
        healthPlan: healthPlan,
        providerTypeIds: validatedProviderTypeIds,
        radius: radius,
        specialty: specialty,
        includeNpi: includeNpi,
        acceptsPregnantWomen: acceptsPregnantWomen,
        acceptsNewborns: acceptsNewborns,
        telehealth: telehealth,
      );

      // Parse providers from function response
      final providersList = result['providers'] as List<dynamic>? ?? [];
      final providers = providersList.map((p) {
        try {
          // Convert to Map<String, dynamic> safely
          if (p is Map) {
            final Map<String, dynamic> providerMap = Map<String, dynamic>.from(
              p.map((key, value) => MapEntry(key.toString(), value))
            );
            return Provider.fromMap(providerMap);
          }
          print('⚠️ [ProviderRepository] Provider is not a Map: ${p.runtimeType}');
          return null;
        } catch (e, stackTrace) {
          print('⚠️ [ProviderRepository] Error parsing provider: $e');
          print('⚠️ [ProviderRepository] Stack trace: $stackTrace');
          return null;
        }
      }).whereType<Provider>().toList();

      print('✅ [ProviderRepository] Total providers from function: ${providers.length}');
      
      return providers;
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
          // Calculate average rating from reviews if not already set
          double? calculatedRating = firestoreProvider.rating;
          int reviewCount = firestoreProvider.reviewCount ?? 0;
          
          if (calculatedRating == null || calculatedRating == 0) {
            // Try to calculate from reviews
            try {
              final reviews = await getProviderReviews(firestoreProvider.id ?? '');
              if (reviews.isNotEmpty) {
                final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
                calculatedRating = totalRating / reviews.length;
                reviewCount = reviews.length;
              }
            } catch (e) {
              // If review calculation fails, keep existing rating
              print('⚠️ [ProviderRepository] Could not calculate rating from reviews: $e');
            }
          }
          
          // Merge: Use API data but add Firestore enrichments
          enrichedProviders.add(provider.copyWith(
            id: firestoreProvider.id,
            mamaApproved: firestoreProvider.mamaApproved,
            mamaApprovedCount: firestoreProvider.mamaApprovedCount,
            identityTags: firestoreProvider.identityTags,
            rating: calculatedRating,
            reviewCount: reviewCount,
            acceptingNewPatients: firestoreProvider.acceptingNewPatients,
          ));
          enrichmentSuccesses++;
        } else {
          // New provider - try to calculate rating from reviews if provider has an ID
          if (provider.id != null && provider.id!.isNotEmpty) {
            try {
              final reviews = await getProviderReviews(provider.id!);
              if (reviews.isNotEmpty) {
                final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
                final calculatedRating = totalRating / reviews.length;
                enrichedProviders.add(provider.copyWith(
                  rating: calculatedRating,
                  reviewCount: reviews.length,
                ));
              } else {
                enrichedProviders.add(provider);
              }
            } catch (e) {
              // If review lookup fails, add provider as-is
              enrichedProviders.add(provider);
            }
          } else {
            // No ID, can't look up reviews - add as-is
            enrichedProviders.add(provider);
          }
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
  /// Also ensures provider is saved to Firestore and review count is updated
  Future<void> submitProviderReview(ProviderReview review, {String? firestoreProviderId}) async {
    try {
      print('💾 [ProviderRepository] Submitting review for providerId: ${review.providerId}');
      if (firestoreProviderId != null) {
        print('💾 [ProviderRepository] Using Firestore provider ID: $firestoreProviderId');
      }
      print('💾 [ProviderRepository] Review data: rating=${review.rating}, wouldRecommend=${review.wouldRecommend}, hasText=${review.reviewText != null}');
      
      // Use Firestore provider ID if available, otherwise use original providerId
      final effectiveProviderId = firestoreProviderId ?? review.providerId;
      
      // Check for duplicate review (same user, same provider, within last 2 minutes)
      // Query without orderBy to avoid index requirement, then filter in memory
      final now = DateTime.now();
      final twoMinutesAgo = now.subtract(const Duration(minutes: 2));
      
      // Check both providerId formats
      final existingReviewsQuery1 = await _firestore
          .collection('reviews')
          .where('providerId', isEqualTo: review.providerId)
          .where('userId', isEqualTo: review.userId)
          .get();
      
      final existingReviewsQuery2 = firestoreProviderId != null
          ? await _firestore
              .collection('reviews')
              .where('providerId', isEqualTo: firestoreProviderId)
              .where('userId', isEqualTo: review.userId)
              .get()
          : QuerySnapshot.empty;
      
      // Combine and filter in memory for recent reviews
      final allRecentDocs = <QueryDocumentSnapshot>[];
      for (var doc in existingReviewsQuery1.docs) {
        allRecentDocs.add(doc);
      }
      for (var doc in existingReviewsQuery2.docs) {
        if (!allRecentDocs.any((d) => d.id == doc.id)) {
          allRecentDocs.add(doc);
        }
      }
      
      final recentReviews = allRecentDocs.where((doc) {
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
      
      // Create review with effective provider ID
      final reviewData = review.toMap();
      reviewData['providerId'] = effectiveProviderId; // Use Firestore ID if available
      print('💾 [ProviderRepository] Review map keys: ${reviewData.keys.toList()}');
      
      final docRef = await _firestore.collection('reviews').add(reviewData);
      print('✅ [ProviderRepository] Review saved with ID: ${docRef.id}');
      
      // Update provider's review count after saving review
      await _updateProviderReviewCount(effectiveProviderId);
    } catch (e, stackTrace) {
      print('❌ [ProviderRepository] Error submitting review: $e');
      print('❌ [ProviderRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Save provider to Firestore when a review is submitted
  /// This ensures providers are saved with all their data for easy retrieval
  /// Returns the Firestore provider ID
  Future<String?> saveProviderOnReview(Provider provider) async {
    try {
      print('💾 [ProviderRepository] Saving provider to Firestore: ${provider.name}');
      
      // Try to find existing provider by NPI first
      String? providerId;
      if (provider.npi != null && provider.npi!.isNotEmpty) {
        final npiQuery = await _firestore
            .collection('providers')
            .where('npi', isEqualTo: provider.npi)
            .limit(1)
            .get();
        
        if (!npiQuery.docs.isEmpty) {
          providerId = npiQuery.docs.first.id;
          print('✅ [ProviderRepository] Found existing provider by NPI: $providerId');
        }
      }
      
      // If not found by NPI, try by name+location
      if (providerId == null && provider.locations.isNotEmpty) {
        final loc = provider.locations.first;
        final nameQuery = await _firestore
            .collection('providers')
            .where('name', isEqualTo: provider.name)
            .limit(10)
            .get();
        
        for (var doc in nameQuery.docs) {
          final data = doc.data();
          if (data['locations'] != null && data['locations'] is List) {
            final locations = data['locations'] as List;
            final match = locations.any((l) => 
              l is Map && 
              l['city'] == loc.city && 
              l['zip'] == loc.zip
            );
            if (match) {
              providerId = doc.id;
              print('✅ [ProviderRepository] Found existing provider by name+location: $providerId');
              break;
            }
          }
        }
      }
      
      // Prepare provider data
      final providerData = provider.toMap();
      providerData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Get current review count (will be updated after review is saved)
      // For now, set to 0 if new provider, or get existing count
      int reviewCount = 0;
      if (providerId != null) {
        try {
          // Count reviews by Firestore ID
          final reviewsByFirestoreId = await _firestore
              .collection('reviews')
              .where('providerId', isEqualTo: providerId)
              .get();
          
          // Also count by NPI if available
          if (provider.npi != null && provider.npi!.isNotEmpty) {
            final npiProviderId = 'npi_${provider.npi}';
            final reviewsByNpi = await _firestore
                .collection('reviews')
                .where('providerId', isEqualTo: npiProviderId)
                .get();
            
            // Combine and deduplicate
            final allReviewIds = <String>{};
            for (var doc in reviewsByFirestoreId.docs) {
              allReviewIds.add(doc.id);
            }
            for (var doc in reviewsByNpi.docs) {
              if (!allReviewIds.contains(doc.id)) {
                allReviewIds.add(doc.id);
              }
            }
            reviewCount = allReviewIds.length;
          } else {
            reviewCount = reviewsByFirestoreId.docs.length;
          }
        } catch (e) {
          print('⚠️ [ProviderRepository] Could not get review count: $e');
        }
      }
      
      // Add reviewCount index for easy sorting
      providerData['reviewCount'] = reviewCount;
      
      if (providerId != null) {
        // Update existing provider
        await _firestore.collection('providers').doc(providerId).update(providerData);
        print('✅ [ProviderRepository] Updated provider: $providerId');
      } else {
        // Create new provider
        providerData['createdAt'] = FieldValue.serverTimestamp();
        providerData['source'] = provider.source ?? 'review_submission';
        final docRef = await _firestore.collection('providers').add(providerData);
        providerId = docRef.id;
        print('✅ [ProviderRepository] Created new provider: $providerId');
      }
      
      return providerId;
    } catch (e, stackTrace) {
      print('❌ [ProviderRepository] Error saving provider: $e');
      print('❌ [ProviderRepository] Stack trace: $stackTrace');
      // Don't throw - allow review to be saved even if provider save fails
      return null;
    }
  }

  /// Update provider's review count after a review is submitted
  Future<void> _updateProviderReviewCount(String providerId) async {
    try {
      print('🔍 [ProviderRepository] Updating review count for providerId: $providerId');
      
      // Check if providerId is a Firestore ID or composite ID
      String? firestoreProviderId = providerId;
      
      // Handle NPI-based IDs
      if (providerId.startsWith('npi_')) {
        final npi = providerId.substring(4);
        final npiQuery = await _firestore
            .collection('providers')
            .where('npi', isEqualTo: npi)
            .limit(1)
            .get();
        
        if (!npiQuery.docs.isEmpty) {
          firestoreProviderId = npiQuery.docs.first.id;
          print('✅ [ProviderRepository] Found Firestore provider by NPI: $firestoreProviderId');
        } else {
          // Provider not in Firestore yet, can't update
          print('⚠️ [ProviderRepository] Provider with NPI $npi not found in Firestore');
          return;
        }
      }
      
      // Handle composite IDs (api_name_city_zip, name_name, etc.)
      if (firestoreProviderId == providerId && (providerId.startsWith('api_') || providerId.startsWith('name_'))) {
        // Try to find provider by extracting info from composite ID
        // For now, we'll need the provider to be saved first via saveProviderOnReview
        print('⚠️ [ProviderRepository] Composite ID detected, provider should be saved first');
        return;
      }
      
      if (firestoreProviderId == null) {
        print('⚠️ [ProviderRepository] Could not determine Firestore provider ID');
        return;
      }
      
      // Count ALL reviews for this provider (by both original providerId and Firestore ID)
      final reviewsByOriginalId = await _firestore
          .collection('reviews')
          .where('providerId', isEqualTo: providerId)
          .get();
      
      final reviewsByFirestoreId = await _firestore
          .collection('reviews')
          .where('providerId', isEqualTo: firestoreProviderId)
          .get();
      
      // Combine and deduplicate reviews
      final allReviewIds = <String>{};
      final allReviews = <Map<String, dynamic>>[];
      
      for (var doc in reviewsByOriginalId.docs) {
        if (!allReviewIds.contains(doc.id)) {
          allReviewIds.add(doc.id);
          allReviews.add(doc.data());
        }
      }
      
      for (var doc in reviewsByFirestoreId.docs) {
        if (!allReviewIds.contains(doc.id)) {
          allReviewIds.add(doc.id);
          allReviews.add(doc.data());
        }
      }
      
      final reviewCount = allReviews.length;
      
      // Calculate average rating
      double? averageRating;
      if (allReviews.isNotEmpty) {
        final totalRating = allReviews.fold<double>(
          0.0,
          (sum, review) => sum + ((review['rating'] as num?)?.toDouble() ?? 0.0),
        );
        averageRating = totalRating / reviewCount;
      }
      
      // Update provider with review count and rating
      final updateData = <String, dynamic>{
        'reviewCount': reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (averageRating != null) {
        updateData['rating'] = averageRating;
      }
      
      await _firestore.collection('providers').doc(firestoreProviderId).update(updateData);
      print('✅ [ProviderRepository] Updated provider $firestoreProviderId: reviewCount=$reviewCount, rating=$averageRating');
    } catch (e, stackTrace) {
      print('⚠️ [ProviderRepository] Error updating provider review count: $e');
      print('⚠️ [ProviderRepository] Stack trace: $stackTrace');
      // Don't throw - review is already saved
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
