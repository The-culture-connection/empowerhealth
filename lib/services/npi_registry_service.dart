import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/provider.dart';
import '../constants/npi_taxonomy_codes.dart';

class NpiRegistryService {
  static const String baseUrl = 'https://npiregistry.cms.hhs.gov/api/';

  /// Search providers using NPI Registry API
  /// 
  /// Used when:
  /// - User toggles "Include providers from NPI directory"
  /// - Medicaid returns zero results
  /// - Health plan is not selected (optional)
  /// 
  /// Note: Uses taxonomy_code instead of taxonomy_description for accurate results
  /// Requires: Either specialty (mapped to taxonomy_code) OR provider type IDs (mapped to taxonomy_code)
  /// Also requires: postal_code (ZIP) and city for accurate results
  Future<List<Provider>> searchProviders({
    required String state,
    String? specialty, // Specialty display name (e.g., "OB-GYN")
    String? zip, // ZIP code (required for accurate results)
    String? city, // City name (required for accurate results)
    List<String>? providerTypeIds, // Provider type IDs - can infer taxonomy_code if specialty not provided
    int limit = 50,
  }) async {
    // NPI API requires additional criteria beyond just state
    // We need at least: taxonomy_code (from specialty or provider types)
    // AND location criteria (postal_code and/or city) for accurate results
    
    // Validate we have location criteria
    if ((zip == null || zip.isEmpty) && (city == null || city.isEmpty)) {
      print('⚠️ [NPI] Cannot search NPI: missing location criteria (ZIP and city)');
      throw Exception('NPI search requires location information. Please provide ZIP code and city.');
    }
    
    if (specialty == null || specialty.isEmpty) {
      // Try to infer from provider type IDs
      if (providerTypeIds == null || providerTypeIds.isEmpty) {
        print('⚠️ [NPI] Cannot search NPI: missing specialty and provider type IDs');
        throw Exception('Select a specialty for NPI search, or choose provider types that can be mapped to NPI taxonomy codes.');
      }
      
      // Map provider types to taxonomy codes
      final taxonomyCode = _inferTaxonomyFromProviderTypes(providerTypeIds);
      if (taxonomyCode == null) {
        print('⚠️ [NPI] Cannot infer taxonomy code from provider types: $providerTypeIds');
        throw Exception('Selected provider types cannot be searched in NPI registry. Please select a specialty.');
      }
      
      return _searchWithTaxonomyCode(
        state: state,
        taxonomyCode: taxonomyCode,
        zip: zip,
        city: city,
        limit: limit,
      );
    }

    // Check if it's a doula (not in NPI taxonomy)
    if (NpiTaxonomyCodes.isDoula(specialty)) {
      print('ℹ️ [NPI] Doula specialty not available in NPI registry, skipping NPI search');
      return []; // Return empty - doulas must come from Medicaid or user submissions
    }
    
    final taxonomyCode = NpiTaxonomyCodes.getTaxonomyCode(specialty);
    
    if (taxonomyCode == null) {
      print('⚠️ [NPI] Specialty "$specialty" is not mappable to NPI taxonomy code');
      throw Exception('Specialty "$specialty" cannot be searched in NPI registry. Please try a different specialty.');
    }
    
    return _searchWithTaxonomyCode(
      state: state,
      taxonomyCode: taxonomyCode,
      zip: zip,
      city: city,
      limit: limit,
    );
  }

  /// Infer taxonomy code from provider type IDs
  String? _inferTaxonomyFromProviderTypes(List<String> providerTypeIds) {
    // Map common provider type IDs to taxonomy codes
    for (var typeId in providerTypeIds) {
      switch (typeId) {
        case '09': // OB-GYN
        case '01': // Hospital (may have OB-GYN)
          return '207V00000X'; // Obstetrics & Gynecology
        case '71': // Nurse Midwife Individual
        case '46': // Certified Nurse Midwife
          return '367A00000X'; // Advanced Practice Midwife
        case '44': // Nurse Practitioner
          return '363L00000X'; // Nurse Practitioner
        case '19': // Osteopathic Physician
        case '20': // Physician / Osteopath Individual
          return '207V00000X'; // Obstetrics & Gynecology (if OB-GYN context)
        default:
          continue;
      }
    }
    return null;
  }

  /// Search NPI with taxonomy code and location criteria
  Future<List<Provider>> _searchWithTaxonomyCode({
    required String state,
    required String taxonomyCode,
    String? zip,
    String? city,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'version': '2.1',
      'state': state,
      'taxonomy_code': taxonomyCode,
      'limit': limit.toString(),
    };

    // Add location criteria (required for accurate results)
    if (zip != null && zip.isNotEmpty) {
      queryParams['postal_code'] = zip;
    } else {
      print('⚠️ [NPI] Warning: ZIP code not provided, results may be less accurate');
    }
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    } else {
      print('⚠️ [NPI] Warning: City not provided, results may be less accurate');
    }
    
    // Ensure we have at least one location criterion
    if (!queryParams.containsKey('postal_code') && !queryParams.containsKey('city')) {
      throw Exception('NPI search requires at least ZIP code or city for accurate results.');
    }

    final uri = Uri.https(
      'npiregistry.cms.hhs.gov',
      '/api/',
      queryParams,
    );

    try {
      print('🔍 [NPI] Searching with URL: ${uri.toString()}');
      print('🔍 [NPI] Query params: $queryParams');
      
      final response = await http.get(uri);
      
      print('🔍 [NPI] Response status: ${response.statusCode}');
      print('🔍 [NPI] Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Check for errors in response
        if (data.containsKey('Errors')) {
          final errors = data['Errors'] as List<dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            print('❌ [NPI] API returned errors: $errors');
            final errorMsg = errors.map((e) => e['description']?.toString() ?? 'Unknown error').join(', ');
            throw Exception('NPI search error: $errorMsg');
          }
        }
        
        return _parseNpiResponse(data);
      } else {
        print('❌ [NPI] Error status: ${response.statusCode}');
        print('❌ [NPI] Response body: ${response.body}');
        throw Exception('NPI search failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [NPI] Exception: $e');
      rethrow;
    }
  }

  /// Parse NPI Registry API response
  List<Provider> _parseNpiResponse(Map<String, dynamic> data) {
    final List<Provider> providers = [];

    try {
      final results = data['result_count'] as int?;
      final resultList = data['results'] as List<dynamic>?;
      
      print('🔍 [NPI] Result count: $results');
      print('🔍 [NPI] Results list length: ${resultList?.length ?? 0}');
      
      if (resultList == null || resultList.isEmpty) {
        print('ℹ️ [NPI] No results in response');
        return providers;
      }

      for (var i = 0; i < resultList.length; i++) {
        final result = resultList[i];
        if (result is! Map<String, dynamic>) {
          print('⚠️ [NPI] Result $i is not a map, skipping');
          continue;
        }

        try {
          final provider = _parseNpiResult(result);
          if (provider != null) {
            providers.add(provider);
            print('✅ [NPI] Parsed provider: ${provider.name}');
          } else {
            print('⚠️ [NPI] Result $i parsed to null provider');
          }
        } catch (e, stackTrace) {
          print('⚠️ [NPI] Error parsing result $i: $e');
          print('⚠️ [NPI] Stack trace: $stackTrace');
          continue;
        }
      }
      
      print('✅ [NPI] Successfully parsed ${providers.length} providers');
    } catch (e, stackTrace) {
      print('❌ [NPI] Error parsing NPI response: $e');
      print('❌ [NPI] Stack trace: $stackTrace');
    }

    return providers;
  }

  /// Parse a single NPI result into a Provider model
  Provider? _parseNpiResult(Map<String, dynamic> result) {
    try {
      // Extract basic info
      final npi = result['number']?.toString();
      final basicInfo = result['basic'] as Map<String, dynamic>?;
      final addresses = result['addresses'] as List<dynamic>?;
      final taxonomies = result['taxonomies'] as List<dynamic>?;

      if (basicInfo == null) return null;

      // Extract name
      String name = '';
      if (basicInfo['organization_name'] != null) {
        name = basicInfo['organization_name'].toString();
      } else {
        final firstName = basicInfo['first_name']?.toString() ?? '';
        final lastName = basicInfo['last_name']?.toString() ?? '';
        final middleName = basicInfo['middle_name']?.toString() ?? '';
        final credential = basicInfo['credential']?.toString() ?? '';
        
        name = [firstName, middleName, lastName].where((n) => n.isNotEmpty).join(' ');
        if (credential.isNotEmpty) {
          name = '$name, $credential';
        }
      }

      if (name.isEmpty) return null;

      // Extract addresses
      final locations = <ProviderLocation>[];
      if (addresses != null) {
        for (var addr in addresses) {
          if (addr is Map<String, dynamic>) {
            final address1 = addr['address_1']?.toString() ?? '';
            final address2 = addr['address_2']?.toString();
            final city = addr['city']?.toString() ?? '';
            final state = addr['state']?.toString() ?? '';
            final zip = addr['postal_code']?.toString() ?? '';
            final phone = addr['telephone_number']?.toString();

            if (address1.isNotEmpty || city.isNotEmpty) {
              locations.add(ProviderLocation(
                address: address1,
                address2: address2,
                city: city,
                state: state,
                zip: zip,
                phone: phone,
              ));
            }
          }
        }
      }

      // Extract specialties from taxonomies
      final specialties = <String>[];
      final providerTypes = <String>[];
      if (taxonomies != null) {
        for (var tax in taxonomies) {
          if (tax is Map<String, dynamic>) {
            final desc = tax['desc']?.toString();
            final code = tax['code']?.toString();
            if (desc != null) {
              specialties.add(desc);
            }
            if (code != null) {
              providerTypes.add(code);
            }
          }
        }
      }

      // Extract phone from addresses (first address with phone)
      String? phone;
      if (addresses != null && addresses.isNotEmpty) {
        final firstAddr = addresses[0];
        if (firstAddr is Map) {
          phone = firstAddr['telephone_number']?.toString();
        }
      }

      return Provider(
        name: name,
        npi: npi,
        specialty: specialties.isNotEmpty ? specialties.first : null,
        locations: locations,
        providerTypes: providerTypes,
        specialties: specialties,
        phone: phone,
        source: 'npi',
      );
    } catch (e) {
      print('⚠️ Error parsing NPI result: $e');
      return null;
    }
  }
}
