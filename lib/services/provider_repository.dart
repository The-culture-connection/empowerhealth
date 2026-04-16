import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider.dart';
import '../models/provider_report.dart';
import '../models/provider_review.dart';
import 'firebase_functions_service.dart';

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
    /// When set, API results are filtered by name/practiceName and Firestore
    /// `providers` directory rows matching the same text are merged in (types
    /// like ambulance "82" that Medicaid/NPI may not return under MVP types).
    String? nameContains,
  }) async {
    try {
      // Validate provider type IDs
      print('🔍 [ProviderRepository] Starting search via Firebase function');
      print('🔍 [ProviderRepository] ZIP: $zip, City: $city, Health Plan: $healthPlan');
      print('🔍 [ProviderRepository] Provider type IDs: $providerTypeIds');
      print('🔍 [ProviderRepository] Radius: $radius, Specialty: $specialty');
      print('🔍 [ProviderRepository] Include NPI: $includeNpi');
      
      // Normalize provider type IDs to API format
      // IMPORTANT: Ohio Medicaid API uses single digits (1-9) WITH leading zeros ("01", "02", "09")
      final validatedProviderTypeIds = providerTypeIds.map((id) {
        // Add leading zeros for single digits (API format: "01", "02", "09", not "1", "2", "9")
        final numId = int.tryParse(id);
        if (numId != null && numId >= 1 && numId <= 9) {
          return id.padLeft(2, '0'); // Add leading zero (API format: "01", "09")
        }
        return id; // Return as-is for double digits (10+)
      }).toList();
      
      print('🔍 [ProviderRepository] Normalized provider type IDs (API format with leading zeros): $validatedProviderTypeIds');

      // Fetch providers from Ohio Maximus API
      print('🔗 [ProviderRepository] Attempting to fetch providers from Ohio Maximus API...');
      print('🔗 [ProviderRepository] Provider type IDs count: ${validatedProviderTypeIds.length}');
      List<Provider> ohioMaximusProviders = [];
      
      try {
        if (validatedProviderTypeIds.isNotEmpty) {
          print('🔗 [ProviderRepository] Calling ohioMaximusSearch with:');
          print('🔗 [ProviderRepository]   - zip: $zip');
          print('🔗 [ProviderRepository]   - radius: $radius');
          print('🔗 [ProviderRepository]   - city: $city');
          print('🔗 [ProviderRepository]   - healthPlan: $healthPlan');
          print('🔗 [ProviderRepository]   - providerType: ${validatedProviderTypeIds.length == 1 ? validatedProviderTypeIds.first : validatedProviderTypeIds}');
          
          // Call OhioMaximusSearch to get providers
          final ohioResult = await _functionsService.ohioMaximusSearch(
            zip: zip,
            radius: radius.toString(),
            city: city,
            healthPlan: healthPlan,
            providerType: validatedProviderTypeIds.length == 1 
                ? validatedProviderTypeIds.first 
                : validatedProviderTypeIds,
            state: "OH",
          );
          
          print('🔗 [ProviderRepository] ✅ Ohio Maximus search completed!');
          print('🔗 [ProviderRepository] URL: ${ohioResult['url']}');
          print('🔗 [ProviderRepository] Found ${ohioResult['count']} providers');
          
          // Parse providers from the result
          final providersList = ohioResult['providers'] as List<dynamic>? ?? [];
          ohioMaximusProviders = providersList.map((p) {
            try {
              if (p is Map) {
                final Map<String, dynamic> providerMap = Map<String, dynamic>.from(
                  p.map((key, value) => MapEntry(key.toString(), value))
                );
                return Provider.fromMap(providerMap);
              }
              return null;
            } catch (e) {
              print('⚠️ [ProviderRepository] Error parsing Ohio Maximus provider: $e');
              return null;
            }
          }).whereType<Provider>().toList();
          
          print('🔗 [ProviderRepository] Parsed ${ohioMaximusProviders.length} providers from Ohio Maximus API');
        } else {
          print('⚠️ [ProviderRepository] Skipping Ohio Maximus search - provider type IDs list is empty');
        }
      } catch (e, stackTrace) {
        // Don't fail the search if Ohio Maximus search fails, just log it
        print('⚠️ [ProviderRepository] ❌ Could not fetch from Ohio Maximus API: $e');
        print('⚠️ [ProviderRepository] Stack trace: $stackTrace');
      }

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
      final searchProviders = providersList.map((p) {
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

      print('✅ [ProviderRepository] Total providers from searchProviders function: ${searchProviders.length}');
      
      // Combine Ohio Maximus providers with searchProviders results
      // Use a Set to deduplicate by name + location
      var allProviders = <Provider>[];
      final seenProviders = <String>{};
      
      // Add Ohio Maximus providers first
      for (final provider in ohioMaximusProviders) {
        final key = _getProviderKey(provider);
        if (!seenProviders.contains(key)) {
          seenProviders.add(key);
          allProviders.add(provider);
        }
      }
      
      // Add searchProviders results (avoiding duplicates)
      for (final provider in searchProviders) {
        final key = _getProviderKey(provider);
        if (!seenProviders.contains(key)) {
          seenProviders.add(key);
          allProviders.add(provider);
        }
      }
      
      print('✅ [ProviderRepository] Combined results: ${ohioMaximusProviders.length} from Ohio Maximus + ${searchProviders.length} from searchProviders = ${allProviders.length} total (${ohioMaximusProviders.length + searchProviders.length - allProviders.length} duplicates removed)');

      final nameQ = nameContains?.trim();
      if (nameQ != null && nameQ.isNotEmpty) {
        final low = nameQ.toLowerCase();
        allProviders = allProviders.where((p) {
          final n = p.name.toLowerCase();
          final pr = (p.practiceName ?? '').toLowerCase();
          return n.contains(low) || pr.contains(low);
        }).toList();

        final directoryMatches =
            await _fetchFirestoreDirectoryProvidersByName(nameQ, zip: zip);
        final seenKeys = <String>{
          for (final p in allProviders) _providerDedupeKey(p),
        };
        for (final p in directoryMatches) {
          final n = p.name.toLowerCase();
          final pr = (p.practiceName ?? '').toLowerCase();
          if (!n.contains(low) && !pr.contains(low)) continue;
          final key = _providerDedupeKey(p);
          if (seenKeys.contains(key)) continue;
          seenKeys.add(key);
          allProviders.add(p);
        }
        print(
          '✅ [ProviderRepository] After name filter + directory merge: ${allProviders.length} providers (query: "$nameQ")',
        );
      }

      allProviders =
          await _applyDirectoryHiddenFilterToSearchResults(allProviders);

      return allProviders;
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
  /// Skips [directoryHidden] rows so removed listings are not reattached.
  /// This method should never throw - all errors are caught and return null
  Future<Provider?> _findProviderInFirestore(Provider provider) async {
    try {
      // Try by NPI first
      if (provider.npi != null && provider.npi!.isNotEmpty) {
        try {
          final query = await _firestore
              .collection('providers')
              .where('npi', isEqualTo: provider.npi)
              .limit(10)
              .get();

          for (final doc in query.docs) {
            final data = doc.data();
            if (data['directoryHidden'] == true) continue;
            return Provider.fromMap(data, id: doc.id);
          }
        } catch (e) {
          // Permission denied or other Firestore error - return null silently
          // Error is logged at enrichment level to avoid spam
          return null;
        }
      }

      // Try by name + location match (only if NPI lookup failed)
      // Note: This query may also fail due to permissions or missing index
      // We query by name first, then filter by location in memory since Firestore doesn't support array-contains-any for nested fields easily
      if (provider.locations.isNotEmpty) {
        try {
          final loc = provider.locations.first;
          final city = loc.city;
          final zip = loc.zip;
          
          if (city.isNotEmpty || zip.isNotEmpty) {
            // Query by name first
            final nameQuery = await _firestore
                .collection('providers')
                .where('name', isEqualTo: provider.name)
                .limit(10) // Get multiple matches, then filter by location
                .get();

            // Filter by location in memory
            for (var doc in nameQuery.docs) {
              final data = doc.data();
              if (data['directoryHidden'] == true) continue;
              if (data['locations'] != null && data['locations'] is List) {
                final locations = data['locations'] as List;
                final match = locations.any((l) =>
                  l is Map &&
                  (city.isEmpty || (l['city']?.toString().toUpperCase() ?? '') == city.toUpperCase()) &&
                  (zip.isEmpty || l['zip']?.toString() == zip)
                );
                if (match) {
                  return Provider.fromMap(data, id: doc.id);
                }
              }
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
        final p = Provider.fromMap(doc.data()!, id: doc.id);
        if (p.directoryHidden) return null;
        return p;
      }
    } catch (e) {
      print('❌ Error getting provider: $e');
    }
    return null;
  }

  /// When opening a profile from search, re-check Firestore so [directoryHidden]
  /// and fresh fields apply. Returns null if this listing was removed from the app directory.
  Future<Provider?> resolveDirectoryListingForProfile(Provider p) async {
    try {
      if (p.id != null && p.id!.isNotEmpty) {
        final snap =
            await _firestore.collection('providers').doc(p.id!).get();
        if (snap.exists) {
          final data = snap.data()!;
          if (data['directoryHidden'] == true) return null;
          return Provider.fromMap(data, id: snap.id);
        }
        return p;
      }

      if (p.npi != null && p.npi!.isNotEmpty) {
        final q = await _firestore
            .collection('providers')
            .where('npi', isEqualTo: p.npi)
            .limit(20)
            .get();
        if (q.docs.isEmpty) return p;

        final hiddenOnly = q.docs.every(
          (d) => d.data()['directoryHidden'] == true,
        );
        if (hiddenOnly) return null;

        final visible = q.docs.where(
          (d) => d.data()['directoryHidden'] != true,
        );
        if (visible.isEmpty) return p;
        final first = visible.first;
        return p.copyWith(id: first.id);
      }

      return p;
    } catch (e) {
      print('⚠️ [ProviderRepository] resolveDirectoryListingForProfile: $e');
      return p;
    }
  }

  /// Enrich a provider with reviews by finding it in Firestore first
  /// This ensures we use the correct Firestore ID that was used when reviews were saved
  Future<Provider> enrichProviderWithReviews(Provider provider) async {
    try {
      print('🔍 [ProviderRepository] Enriching provider with reviews: ${provider.name}');
      
      // First, try to find the provider in Firestore to get its Firestore ID
      final firestoreProvider = await _findProviderInFirestore(provider);
      String? reviewProviderId;
      
      if (firestoreProvider != null && firestoreProvider.id != null) {
        // Use Firestore ID if we found the provider
        reviewProviderId = firestoreProvider.id;
        print('✅ [ProviderRepository] Found provider in Firestore with ID: $reviewProviderId');
      } else {
        // Fallback: construct ID from available data
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
        print('ℹ️ [ProviderRepository] Provider not in Firestore, using constructed ID: $reviewProviderId');
      }
      
      // Fetch reviews using the provider ID
      if (reviewProviderId != null && reviewProviderId.isNotEmpty) {
        final reviews = await getProviderReviews(reviewProviderId);
        if (reviews.isNotEmpty) {
          final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
          final averageRating = totalRating / reviews.length;
          print('✅ [ProviderRepository] Found ${reviews.length} reviews for ${provider.name}, rating: $averageRating');
          
          // Update provider with Firestore ID if we found it, and add reviews/rating
          return provider.copyWith(
            id: firestoreProvider?.id ?? provider.id,
            rating: averageRating,
            reviewCount: reviews.length,
          );
        } else {
          print('ℹ️ [ProviderRepository] No reviews found for ${provider.name}');
        }
      }
      
      // Return provider with Firestore ID if we found it, even if no reviews
      if (firestoreProvider != null && firestoreProvider.id != null) {
        return provider.copyWith(id: firestoreProvider.id);
      }
      
      return provider;
    } catch (e, stackTrace) {
      print('⚠️ [ProviderRepository] Error enriching provider with reviews: $e');
      print('⚠️ [ProviderRepository] Stack trace: $stackTrace');
      return provider; // Return original provider on error
    }
  }

  /// Get reviews for a provider
  /// Can search by Firestore ID, NPI (with 'npi_' prefix), or composite API ID
  /// Also checks for reviews saved with Firestore provider ID
  Future<List<ProviderReview>> getProviderReviews(String providerId) async {
    try {
      print('🔍 [ProviderRepository] Getting reviews for providerId: $providerId');
      
      final allReviews = <ProviderReview>[];
      final seenReviewIds = <String>{};
      
      // First, try to get reviews by the provided providerId
      try {
        final reviewsQuery = await _firestore
            .collection('reviews')
            .where('providerId', isEqualTo: providerId)
            .get();
        
        for (var doc in reviewsQuery.docs) {
          if (!seenReviewIds.contains(doc.id)) {
            seenReviewIds.add(doc.id);
            allReviews.add(ProviderReview.fromMap(doc.data(), id: doc.id));
          }
        }
        print('✅ [ProviderRepository] Found ${reviewsQuery.docs.length} reviews by providerId: $providerId');
      } catch (e) {
        print('⚠️ [ProviderRepository] Error getting reviews by providerId: $e');
      }
      
      // If providerId starts with 'npi_', try to find Firestore provider and get reviews by Firestore ID
      if (providerId.startsWith('npi_')) {
        final npi = providerId.substring(4);
        print('🔍 [ProviderRepository] NPI-based ID detected, NPI: $npi');
        
        // First find provider by NPI, then get reviews
        try {
          final providerQuery = await _firestore
              .collection('providers')
              .where('npi', isEqualTo: npi)
              .limit(10)
              .get();

          for (final doc in providerQuery.docs) {
            if (doc.data()['directoryHidden'] == true) continue;
            final firestoreProviderId = doc.id;
            print('✅ [ProviderRepository] Found Firestore provider with ID: $firestoreProviderId');
            try {
              final reviewsQuery = await _firestore
                  .collection('reviews')
                  .where('providerId', isEqualTo: firestoreProviderId)
                  .get();

              for (var rdoc in reviewsQuery.docs) {
                if (!seenReviewIds.contains(rdoc.id)) {
                  seenReviewIds.add(rdoc.id);
                  allReviews.add(ProviderReview.fromMap(rdoc.data(), id: rdoc.id));
                }
              }
              print('✅ [ProviderRepository] Found ${reviewsQuery.docs.length} additional reviews by Firestore ID: $firestoreProviderId');
            } catch (e) {
              print('⚠️ [ProviderRepository] Error getting reviews by Firestore ID: $e');
            }
            break;
          }
        } catch (e) {
          print('⚠️ [ProviderRepository] Error finding Firestore provider by NPI: $e');
        }
      }
      
      // Also try to find provider by composite ID patterns and get reviews by Firestore ID
      if (providerId.startsWith('api_') || providerId.startsWith('name_')) {
        try {
          // Try to find provider by extracting info from composite ID
          String? searchName;
          String? searchCity;
          
          if (providerId.startsWith('api_')) {
            final parts = providerId.substring(4).split('_');
            if (parts.length >= 3) {
              searchName = parts[0].replaceAll('_', ' ');
              searchCity = parts[parts.length - 2]; // City is second to last
            }
          } else if (providerId.startsWith('name_')) {
            searchName = providerId.substring(5).replaceAll('_', ' ');
          }
          
          if (searchName != null) {
            // Try to find provider by name
            final nameQuery = await _firestore
                .collection('providers')
                .where('name', isEqualTo: searchName)
                .limit(5)
                .get();
            
            for (var doc in nameQuery.docs) {
              final providerData = doc.data();
              if (providerData['directoryHidden'] == true) continue;
              // If we have city, match it
              if (searchCity == null || 
                  (providerData['locations'] != null && 
                   providerData['locations'] is List &&
                   (providerData['locations'] as List).any((l) => 
                     l is Map && (l['city']?.toString()?.toUpperCase() ?? '') == (searchCity?.toUpperCase() ?? '')))) {
                final firestoreProviderId = doc.id;
                try {
                  final reviewsQuery = await _firestore
                      .collection('reviews')
                      .where('providerId', isEqualTo: firestoreProviderId)
                      .get();
                  
                  for (var reviewDoc in reviewsQuery.docs) {
                    if (!seenReviewIds.contains(reviewDoc.id)) {
                      seenReviewIds.add(reviewDoc.id);
                      allReviews.add(ProviderReview.fromMap(reviewDoc.data(), id: reviewDoc.id));
                    }
                  }
                  print('✅ [ProviderRepository] Found ${reviewsQuery.docs.length} additional reviews by Firestore ID from composite ID: $firestoreProviderId');
                } catch (e) {
                  print('⚠️ [ProviderRepository] Error getting reviews for Firestore provider: $e');
                }
                break; // Use first match
              }
            }
          }
        } catch (e) {
          print('⚠️ [ProviderRepository] Error finding provider by composite ID: $e');
        }
      }
      
      // Deduplicate and sort all reviews
      final uniqueReviews = <String, ProviderReview>{};
      for (final review in allReviews) {
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
      print('✅ [ProviderRepository] Total reviews found: ${allReviews.length}, unique: ${deduplicatedReviews.length}');
      return deduplicatedReviews.take(50).toList();
    } catch (e, stackTrace) {
      print('❌ [ProviderRepository] Error getting reviews: $e');
      print('❌ [ProviderRepository] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Report a provider listing (stored for admin review).
  Future<void> submitProviderReport({
    required String providerId,
    required String providerName,
    required String userId,
    required String reasonCategory,
    String? details,
  }) async {
    final reasonLabel =
        ProviderReportReason.labels[reasonCategory] ?? reasonCategory;
    await _firestore.collection('provider_reports').add({
      'providerId': providerId,
      'providerName': providerName,
      'userId': userId,
      'reasonCategory': reasonCategory,
      'reasonCategoryLabel': reasonLabel,
      if (details != null && details.isNotEmpty) 'details': details,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Submit a provider review
  /// Prevents duplicates by checking for existing review from same user for same provider within last minute
  /// Also ensures provider is saved to Firestore and review count is updated
  /// If markMamaApproved is true, marks the provider as Mama Approved
  Future<void> submitProviderReview(
    ProviderReview review, {
    String? firestoreProviderId,
    bool markMamaApproved = false,
  }) async {
    try {
      print('💾 [ProviderRepository] Submitting review for providerId: ${review.providerId}');
      if (firestoreProviderId != null) {
        print('💾 [ProviderRepository] Using Firestore provider ID: $firestoreProviderId');
      }
      print('💾 [ProviderRepository] Review data: rating=${review.rating}, wouldRecommend=${review.wouldRecommend}, hasText=${review.reviewText != null}, markMamaApproved=$markMamaApproved');
      
      // Use Firestore provider ID if available, otherwise use original providerId
      final effectiveProviderId = firestoreProviderId ?? review.providerId;
      
      // Create review with effective provider ID
      final reviewData = review.toMap();
      reviewData['providerId'] = effectiveProviderId; // Use Firestore ID if available
      print('💾 [ProviderRepository] Review map keys: ${reviewData.keys.toList()}');
      
      final docRef = await _firestore.collection('reviews').add(reviewData);
      print('✅ [ProviderRepository] Review saved with ID: ${docRef.id}');
      
      // Update provider's review count after saving review
      await _updateProviderReviewCount(effectiveProviderId);
      await _mergeReviewIdentityIntoProvider(
        effectiveProviderId,
        review,
        reviewDocId: docRef.id,
      );

      // If admin marked as Mama Approved, update provider
      if (markMamaApproved && effectiveProviderId.isNotEmpty) {
        try {
          // Check if provider exists in Firestore
          final providerDoc = await _firestore.collection('providers').doc(effectiveProviderId).get();
          if (providerDoc.exists) {
            // Update existing provider
            await _firestore.collection('providers').doc(effectiveProviderId).update({
              'mamaApproved': true,
              'mamaApprovedCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('✅ [ProviderRepository] Provider marked as Mama Approved: $effectiveProviderId');
          } else {
            // Provider doesn't exist in Firestore yet
            // Try to find it by the original providerId pattern or save it
            print('⚠️ [ProviderRepository] Provider not found in Firestore with ID: $effectiveProviderId');
            print('⚠️ [ProviderRepository] Attempting to find or create provider...');
            
            // If we have a provider object from the review screen, try to save it
            // This should have been done earlier, but if not, we'll need the provider data
            // For now, log that we need the provider to be saved first
            print('⚠️ [ProviderRepository] Provider must be saved to Firestore first before marking as Mama Approved');
          }
        } catch (e) {
          print('⚠️ [ProviderRepository] Error marking provider as Mama Approved: $e');
          // Don't fail the review submission if this fails
        }
      }
    } catch (e, stackTrace) {
      print('❌ [ProviderRepository] Error submitting review: $e');
      print('❌ [ProviderRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Save provider to Firestore when a review is submitted
  /// This ensures providers are saved with all their data for easy retrieval
  /// Returns the Firestore provider ID
  /// If markMamaApproved is true, also marks the provider as Mama Approved
  Future<String?> saveProviderOnReview(Provider provider, {bool markMamaApproved = false}) async {
    try {
      print('💾 [ProviderRepository] Saving provider to Firestore: ${provider.name}');
      
      // Try to find existing provider by NPI first (skip directory-hidden rows)
      String? providerId;
      if (provider.npi != null && provider.npi!.isNotEmpty) {
        final npiQuery = await _firestore
            .collection('providers')
            .where('npi', isEqualTo: provider.npi)
            .limit(10)
            .get();

        for (final doc in npiQuery.docs) {
          if (doc.data()['directoryHidden'] == true) continue;
          providerId = doc.id;
          print('✅ [ProviderRepository] Found existing provider by NPI: $providerId');
          break;
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
          if (data['directoryHidden'] == true) continue;
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
      
      // If marking as Mama Approved, add that flag
      if (markMamaApproved) {
        providerData['mamaApproved'] = true;
        if (providerId != null) {
          // Increment count for existing provider
          providerData['mamaApprovedCount'] = FieldValue.increment(1);
        } else {
          // Set initial count for new provider
          providerData['mamaApprovedCount'] = 1;
        }
      }
      
      if (providerId != null) {
        // Update existing provider
        await _firestore.collection('providers').doc(providerId).update(providerData);
        print('✅ [ProviderRepository] Updated provider: $providerId${markMamaApproved ? " (Mama Approved)" : ""}');
      } else {
        // Create new provider
        providerData['createdAt'] = FieldValue.serverTimestamp();
        providerData['source'] = provider.source ?? 'review_submission';
        final docRef = await _firestore.collection('providers').add(providerData);
        providerId = docRef.id;
        print('✅ [ProviderRepository] Created new provider: $providerId${markMamaApproved ? " (Mama Approved)" : ""}');
      }
      
      return providerId;
    } catch (e, stackTrace) {
      print('❌ [ProviderRepository] Error saving provider: $e');
      print('❌ [ProviderRepository] Stack trace: $stackTrace');
      // Don't throw - allow review to be saved even if provider save fails
      return null;
    }
  }

  /// Resolves a Firestore `providers` document id for review-side updates, or null if hidden/missing.
  Future<String?> _resolveVisibleFirestoreProviderDocId(String providerId) async {
    if (providerId.isEmpty) return null;

    if (providerId.startsWith('npi_')) {
      final npi = providerId.substring(4);
      final npiQuery = await _firestore
          .collection('providers')
          .where('npi', isEqualTo: npi)
          .limit(10)
          .get();
      for (final d in npiQuery.docs) {
        if (d.data()['directoryHidden'] == true) continue;
        return d.id;
      }
      return null;
    }

    final doc = await _firestore.collection('providers').doc(providerId).get();
    if (!doc.exists || doc.data()?['directoryHidden'] == true) return null;
    return providerId;
  }

  /// Merges visit prompts and self-report labels from a review into `identityTags` (source: review).
  /// Also creates one [provider_identity_claims] document per **new** tag so the admin dashboard can triage.
  Future<void> _mergeReviewIdentityIntoProvider(
    String providerId,
    ProviderReview review, {
    required String reviewDocId,
  }) async {
    final docId = await _resolveVisibleFirestoreProviderDocId(providerId);
    if (docId == null) return;

    final hasInput = review.feltHeard ||
        review.feltRespected ||
        review.explainedClearly ||
        review.reviewerRaceEthnicity.isNotEmpty ||
        review.reviewerLanguages.isNotEmpty ||
        review.reviewerCulturalTags.isNotEmpty;
    if (!hasInput) return;

    final snap = await _firestore.collection('providers').doc(docId).get();
    if (!snap.exists || snap.data()?['directoryHidden'] == true) return;

    final data = snap.data()!;
    final existing = (data['identityTags'] as List<dynamic>?) ?? [];
    final byNameKey = <String, Map<String, dynamic>>{};
    for (final e in existing) {
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        final n = (m['name'] as String?)?.trim().toLowerCase() ?? '';
        if (n.isEmpty) continue;
        byNameKey[n] = m;
      }
    }

    final addedTagMaps = <Map<String, dynamic>>[];

    void tryAdd(String label, String category) {
      final trimmed = label.trim();
      if (trimmed.isEmpty) return;
      final key = trimmed.toLowerCase();
      if (byNameKey.containsKey(key)) return;
      final slug = key.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      var id = 'review_${category}_${slug.isEmpty ? 'x' : slug}';
      if (id.length > 120) id = id.substring(0, 120);
      final map = <String, dynamic>{
        'id': id,
        'name': trimmed,
        'category': category,
        'source': 'review',
        'verificationStatus': 'pending',
      };
      byNameKey[key] = map;
      addedTagMaps.add(map);
    }

    if (review.feltHeard) tryAdd('Felt heard', 'visit');
    if (review.feltRespected) tryAdd('Felt respected', 'visit');
    if (review.explainedClearly) tryAdd('Explained clearly', 'visit');
    for (final t in review.reviewerRaceEthnicity) {
      tryAdd(t, 'race');
    }
    for (final t in review.reviewerLanguages) {
      tryAdd(t, 'language');
    }
    for (final t in review.reviewerCulturalTags) {
      tryAdd(t, 'cultural');
    }

    if (addedTagMaps.isEmpty) return;

    final batch = _firestore.batch();
    final pRef = _firestore.collection('providers').doc(docId);
    batch.update(pRef, {
      'identityTags': byNameKey.values.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final m in addedTagMaps) {
      final cRef = _firestore.collection('provider_identity_claims').doc();
      batch.set(cRef, {
        'providerId': docId,
        'userId': review.userId,
        'tagId': m['id'],
        'tagName': m['name'],
        'category': m['category'],
        'status': 'pending',
        'sourceType': 'review',
        'sourceReviewId': reviewDocId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Update provider's review count after a review is submitted
  Future<void> _updateProviderReviewCount(String providerId) async {
    try {
      print('🔍 [ProviderRepository] Updating review count for providerId: $providerId');
      
      // Check if providerId is a Firestore ID or composite ID
      String? firestoreProviderId = providerId;
      
      // Handle NPI-based IDs (ignore directory-hidden matches)
      if (providerId.startsWith('npi_')) {
        final npi = providerId.substring(4);
        final npiQuery = await _firestore
            .collection('providers')
            .where('npi', isEqualTo: npi)
            .limit(10)
            .get();

        String? foundId;
        for (final d in npiQuery.docs) {
          if (d.data()['directoryHidden'] == true) continue;
          foundId = d.id;
          break;
        }
        if (foundId != null) {
          firestoreProviderId = foundId;
          print('✅ [ProviderRepository] Found Firestore provider by NPI: $firestoreProviderId');
        } else {
          print('⚠️ [ProviderRepository] Provider with NPI $npi not found in Firestore (or hidden)');
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

      final providerSnap =
          await _firestore.collection('providers').doc(firestoreProviderId).get();
      if (!providerSnap.exists || providerSnap.data()?['directoryHidden'] == true) {
        print('⚠️ [ProviderRepository] Skip review count update: doc missing or directoryHidden');
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
      
      final publishedOnly = allReviews
          .where((r) => (r['status'] as String? ?? 'published') == 'published')
          .toList();
      final reviewCount = publishedOnly.length;

      // Calculate average rating (published reviews only — matches app profile)
      double? averageRating;
      if (publishedOnly.isNotEmpty) {
        final totalRating = publishedOnly.fold<double>(
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
      print('💾 [ProviderRepository] Submitting provider to UserProviders: ${provider.name}');
      
      final providerData = provider.toMap();
      providerData['source'] = provider.source ?? 'user_submission';
      providerData['submittedBy'] = userId;
      providerData['userId'] = userId; // Also add userId for Firestore rules
      providerData['submissionNotes'] = notes;
      providerData['status'] = 'pending'; // User-submitted providers start as pending
      providerData['createdAt'] = FieldValue.serverTimestamp();
      providerData['updatedAt'] = FieldValue.serverTimestamp();
      providerData['reviewCount'] = 0;
      providerData['mamaApproved'] = false;
      providerData['mamaApprovedCount'] = 0;
      
      // Save to UserProviders collection
      final docRef = await _firestore.collection('UserProviders').add(providerData);
      print('✅ [ProviderRepository] Created user provider in UserProviders: ${docRef.id}');
      
      // Also save to provider_submissions for moderation tracking
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

  /// Generate a unique key for a provider to detect duplicates
  /// Uses name + first location (city + zip) as the key
  String _getProviderKey(Provider provider) {
    final locationKey = provider.locations.isNotEmpty
        ? '${provider.locations.first.city}_${provider.locations.first.zip}'
        : 'no_location';
    return '${provider.name.toLowerCase().trim()}_$locationKey';
  }

  String _providerDedupeKey(Provider p) {
    if (p.id != null && p.id!.isNotEmpty) return 'id:${p.id}';
    if (p.npi != null && p.npi!.isNotEmpty) return 'npi:${p.npi}';
    return _getProviderKey(p);
  }

  /// Removes admin-hidden directory rows from search output. Also drops Medicaid/API
  /// rows whose NPI matches only [directoryHidden] Firestore docs (so results stay
  /// correct even if the Cloud Function is not redeployed yet).
  Future<List<Provider>> _applyDirectoryHiddenFilterToSearchResults(
    List<Provider> providers,
  ) async {
    if (providers.isEmpty) return providers;

    var out = providers.where((p) => !p.directoryHidden).toList();
    if (out.isEmpty) return out;

    final hiddenDocIds = await _firestoreProviderDocIdsThatAreHidden(
      out.map((p) => p.id).whereType<String>().toSet(),
    );
    if (hiddenDocIds.isNotEmpty) {
      out = out
          .where((p) => p.id == null || !hiddenDocIds.contains(p.id))
          .toList();
    }

    final npis = out
        .map((p) => p.npi)
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toSet();
    if (npis.isEmpty) return out;

    final npiHiddenOnly = await _npisWithNoVisibleDirectoryRow(npis);
    if (npiHiddenOnly.isEmpty) return out;
    return out.where((p) {
      final n = p.npi;
      if (n == null || n.isEmpty) return true;
      return !npiHiddenOnly.contains(n);
    }).toList();
  }

  bool _looksLikeFirestoreProviderDocId(String id) {
    if (id.isEmpty) return false;
    if (id.startsWith('api_') ||
        id.startsWith('name_') ||
        id.startsWith('npi_')) {
      return false;
    }
    return true;
  }

  Future<Set<String>> _firestoreProviderDocIdsThatAreHidden(
    Set<String> ids,
  ) async {
    final hidden = <String>{};
    final list = ids.where(_looksLikeFirestoreProviderDocId).toList();
    for (var i = 0; i < list.length; i += 10) {
      final end = (i + 10 > list.length) ? list.length : i + 10;
      final chunk = list.sublist(i, end);
      try {
        final snaps = await Future.wait(
          chunk.map(
            (id) => _firestore.collection('providers').doc(id).get(),
          ),
        );
        for (var j = 0; j < chunk.length; j++) {
          final s = snaps[j];
          if (s.exists && s.data()?['directoryHidden'] == true) {
            hidden.add(chunk[j]);
          }
        }
      } catch (e) {
        print('⚠️ [ProviderRepository] directoryHidden doc batch: $e');
      }
    }
    return hidden;
  }

  /// NPIs for which every matching `providers` row is [directoryHidden].
  Future<Set<String>> _npisWithNoVisibleDirectoryRow(Set<String> npis) async {
    final hiddenOnly = <String>{};
    final list = npis.toList();
    for (var i = 0; i < list.length; i += 10) {
      final end = (i + 10 > list.length) ? list.length : i + 10;
      final chunk = list.sublist(i, end);
      try {
        final snap = await _firestore
            .collection('providers')
            .where('npi', whereIn: chunk)
            .get();
        final byNpi = <String, List<bool>>{};
        for (final doc in snap.docs) {
          final m = doc.data();
          final n = m['npi']?.toString();
          if (n == null || n.isEmpty) continue;
          byNpi.putIfAbsent(n, () => []).add(m['directoryHidden'] == true);
        }
        for (final n in chunk) {
          final statuses = byNpi[n];
          if (statuses == null || statuses.isEmpty) continue;
          final anyVisible = statuses.any((h) => !h);
          if (!anyVisible) hiddenOnly.add(n);
        }
      } catch (e) {
        print('⚠️ [ProviderRepository] directoryHidden NPI batch: $e');
      }
    }
    return hiddenOnly;
  }

  /// Firestore `providers` collection — name / practiceName (prefix + limited scan).
  Future<List<Provider>> _fetchFirestoreDirectoryProvidersByName(
    String nameQuery, {
    required String zip,
  }) async {
    final q = nameQuery.trim();
    if (q.isEmpty) return [];
    final low = q.toLowerCase();
    final seen = <String>{};
    final out = <Provider>[];

    void tryAdd(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      if (!seen.add(doc.id)) return;
      try {
        final m = doc.data();
        if (m['directoryHidden'] == true) return;
        out.add(Provider.fromMap(m, id: doc.id));
      } catch (_) {}
    }

    final col = _firestore.collection('providers');

    try {
      final snap = await col
          .orderBy('practiceName')
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(40)
          .get();
      for (final d in snap.docs) {
        tryAdd(d);
      }
    } catch (e) {
      print('⚠️ [ProviderRepository] Directory orderBy(practiceName): $e');
    }

    try {
      final snap = await col
          .orderBy('name')
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(40)
          .get();
      for (final d in snap.docs) {
        tryAdd(d);
      }
    } catch (e) {
      print('⚠️ [ProviderRepository] Directory orderBy(name): $e');
    }

    try {
      if (out.length < 45) {
        final broad = await col.limit(400).get();
        for (final d in broad.docs) {
          if (seen.contains(d.id)) continue;
          final m = d.data();
          final pn = (m['practiceName'] as String? ?? '').toLowerCase();
          final n = (m['name'] as String? ?? '').toLowerCase();
          if (pn.contains(low) || n.contains(low)) {
            tryAdd(d);
            if (out.length >= 100) break;
          }
        }
      }
    } catch (e) {
      print('⚠️ [ProviderRepository] Directory broad name scan: $e');
    }

    final zipDigits = zip.replaceAll(RegExp(r'\D'), '');
    if (zipDigits.length == 5) {
      out.sort((a, b) {
        int zipScore(Provider p) {
          for (final loc in p.locations) {
            if (loc.zip.replaceAll(RegExp(r'\D'), '') == zipDigits) return 0;
          }
          return 1;
        }

        final c = zipScore(a).compareTo(zipScore(b));
        if (c != 0) return c;
        return a.primaryDisplayName.toLowerCase().compareTo(
              b.primaryDisplayName.toLowerCase(),
            );
      });
    }

    return out;
  }

  /// Directory providers that qualify for the community Mama Approved™ badge
  /// (same rules as [Provider.showsMamaApprovedBadge]).
  Future<List<Provider>> fetchMamaApprovedCommunityBadgeProviders({
    int limit = 150,
  }) async {
    try {
      final snap = await _firestore
          .collection('providers')
          .where(
            'reviewCount',
            isGreaterThanOrEqualTo: Provider.mamaApprovedMinReviewCount,
          )
          .limit(limit * 3)
          .get();

      final list = <Provider>[];
      for (final doc in snap.docs) {
        try {
          final m = doc.data();
          if (m['directoryHidden'] == true) continue;
          final p = Provider.fromMap(m, id: doc.id);
          if (p.showsMamaApprovedBadge) {
            list.add(p);
          }
        } catch (_) {}
      }

      list.sort((a, b) {
        final rb = b.rating ?? 0.0;
        final ra = a.rating ?? 0.0;
        final c = rb.compareTo(ra);
        if (c != 0) return c;
        return (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0);
      });

      if (list.length > limit) {
        return list.sublist(0, limit);
      }
      return list;
    } catch (e, st) {
      print(
        '⚠️ [ProviderRepository] fetchMamaApprovedCommunityBadgeProviders: $e',
      );
      print('⚠️ Stack: $st');
      final snap = await _firestore.collection('providers').limit(400).get();
      final list = <Provider>[];
      for (final doc in snap.docs) {
        try {
          final m = doc.data();
          if (m['directoryHidden'] == true) continue;
          final p = Provider.fromMap(m, id: doc.id);
          if (p.showsMamaApprovedBadge) {
            list.add(p);
          }
        } catch (_) {}
      }
      list.sort((a, b) {
        final rb = b.rating ?? 0.0;
        final ra = a.rating ?? 0.0;
        final c = rb.compareTo(ra);
        if (c != 0) return c;
        return (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0);
      });
      return list.length > limit ? list.sublist(0, limit) : list;
    }
  }
}
