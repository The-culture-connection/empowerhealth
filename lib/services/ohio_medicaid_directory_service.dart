import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/provider.dart';
import '../constants/provider_types.dart';

class OhioMedicaidDirectoryService {
  static const String baseUrl = 'https://psapi.ohpnm.omes.maximus.com/fhir/PublicSearchFHIR';

  /// Debug/sanity check method - tests with known-good parameters
  /// This helps verify the API is working and parameter casing is correct
  Future<Map<String, dynamic>> runSanityCheck() async {
    print('🧪 [OhioMedicaid] Running sanity check with known-good parameters...');
    
    final queryParams = <String, String>{
      'state': 'OH',
      'zip': '45202',
      'City': 'Cincinnati',
      'healthplan': 'Buckeye',
      'ProviderTypeIDsDelimited': '01,09', // Hospital, OB-GYN
      'radius': '15',
      'Program': '1',
    };

    final uri = Uri.https(
      'psapi.ohpnm.omes.maximus.com',
      '/fhir/PublicSearchFHIR',
      queryParams,
    );

    try {
      print('🧪 [OhioMedicaid] Sanity check URL: ${uri.toString()}');
      
      final response = await http.get(uri);
      final data = json.decode(response.body) as Map<String, dynamic>;
      
      print('🧪 [OhioMedicaid] Sanity check response status: ${response.statusCode}');
      print('🧪 [OhioMedicaid] Sanity check response keys: ${data.keys.toList()}');
      print('🧪 [OhioMedicaid] Sanity check full JSON: ${json.encode(data)}');
      
      final hasEntry = data.containsKey('entry');
      final entryList = data['entry'] as List<dynamic>?;
      final entryCount = entryList?.length ?? 0;
      
      print('🧪 [OhioMedicaid] Has entry: $hasEntry, Count: $entryCount');
      
      return {
        'success': response.statusCode == 200,
        'hasEntry': hasEntry,
        'entryCount': entryCount,
        'response': data,
      };
    } catch (e) {
      print('❌ [OhioMedicaid] Sanity check failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Search providers using Ohio Medicaid Directory API
  /// 
  /// Required params:
  /// - healthplan: Must match dropdown options exactly
  /// - ProviderTypeIDsDelimited: Comma-delimited numeric strings (at least one)
  /// - City: Required
  /// - state: Fixed to "OH"
  /// - zip: 5-digit ZIP code
  /// - radius: Numeric value
  /// - Program: Always "1"
  /// 
  /// Optional params (from API documentation):
  /// - FacilityType, PrimaryCareProviders, OrgName, DMEProductsServices
  /// - AcceptsPatientsAsYoungAs, AcceptsPatientsAsOldAs, AcceptsPatientsofGender
  /// - AcceptsNewPatients, AcceptsNewborns, AcceptsPregnantWomen
  /// - County, SpecialtyTypeIDsDelimited, Gender, HospitalAffiliation
  /// - LanguagesSpoken, SpecializedTraining, CulturalCompetencies
  /// - ADAAccommodations, BoardCertifications, Telehealth, CHIP, NewMedicaidPatients
  Future<List<Provider>> searchProviders({
    required String zip,
    required String city,
    required String healthPlan,
    required List<String> providerTypeIds, // Provider type IDs like ['09', '71']
    required int radius,
    String? specialty, // Optional - for local filtering only
    // Optional API parameters
    String? program,
    String? facilityType,
    String? primaryCareProviders,
    String? orgName,
    String? dmeProductsServices,
    String? acceptsPatientsAsYoungAs,
    String? acceptsPatientsAsOldAs,
    String? acceptsPatientsofGender,
    bool? acceptsNewborns,
    bool? acceptsPregnantWomen,
    String? county,
    List<String>? specialtyTypeIds,
    String? gender,
    String? hospitalAffiliation,
    List<String>? languagesSpoken,
    List<String>? specializedTraining,
    List<String>? culturalCompetencies,
    List<String>? adaAccommodations,
    List<String>? boardCertifications,
    bool? telehealth,
    bool? chip,
    bool? newMedicaidPatients,
  }) async {
    if (providerTypeIds.isEmpty) {
      throw ArgumentError('At least one provider type must be selected');
    }

    if (zip.length != 5) {
      throw ArgumentError('ZIP code must be 5 digits');
    }

    if (!HealthPlans.isValid(healthPlan)) {
      throw ArgumentError('Invalid health plan: $healthPlan');
    }

    // Build query parameters - using exact casing from working API URL
    // Example: state=OH&zip=45202&healthplan=Buckeye&ProviderTypeIDsDelimited=09,01&radius=3&Program=1&City=Cincinnati
    final queryParams = <String, String>{
      'state': 'OH',
      'zip': zip,
      'City': city, // Note: Capital C in City
      'healthplan': healthPlan, // lowercase
      'ProviderTypeIDsDelimited': providerTypeIds.join(','), // Exact casing
      'radius': radius.toString(),
      'Program': '1', // Capital P, always '1' for pregnancy searches
    };

    // Add Pregnancy-Smart optional parameters if provided
    if (acceptsPregnantWomen != null) {
      queryParams['AcceptsPregnantWomen'] = acceptsPregnantWomen ? '1' : '0';
    }
    if (acceptsNewborns != null) {
      queryParams['AcceptsNewborns'] = acceptsNewborns ? '1' : '0';
    }
    if (telehealth != null) {
      queryParams['Telehealth'] = telehealth ? '1' : '0';
    }

    // Build URL safely
    final uri = Uri.https(
      'psapi.ohpnm.omes.maximus.com',
      '/fhir/PublicSearchFHIR',
      queryParams,
    );

    try {
      print('🔍 [OhioMedicaid] Searching with URL: ${uri.toString()}');
      print('🔍 [OhioMedicaid] Query params: $queryParams');
      print('🔍 [OhioMedicaid] Provider type IDs: $providerTypeIds');
      
      final response = await http.get(uri);
      
      print('🔍 [OhioMedicaid] Response status: ${response.statusCode}');
      print('🔍 [OhioMedicaid] Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Log raw response structure
        print('🔍 [OhioMedicaid] Response keys: ${data.keys.toList()}');
        print('🔍 [OhioMedicaid] Response type: ${data['type']}');
        
        // Check if entry exists
        final hasEntry = data.containsKey('entry');
        final entryList = data['entry'] as List<dynamic>?;
        final entryCount = entryList?.length ?? 0;
        
        print('🔍 [OhioMedicaid] Has entry field: $hasEntry');
        print('🔍 [OhioMedicaid] Entry count: $entryCount');
        
        if (!hasEntry || entryCount == 0) {
          print('ℹ️ [OhioMedicaid] No results found (empty or missing entry field)');
          return []; // Return empty list, not an error
        }
        
        return _parseMedicaidResponse(data, specialty);
      } else if (response.statusCode == 400) {
        print('❌ [OhioMedicaid] 400 Bad Request - Invalid parameters');
        print('❌ [OhioMedicaid] Response body: ${response.body}');
        throw Exception('Invalid search parameters. Please check your filters.');
      } else {
        print('❌ [OhioMedicaid] Error status: ${response.statusCode}');
        print('❌ [OhioMedicaid] Response body: ${response.body}');
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [OhioMedicaid] Exception: $e');
      rethrow;
    }
  }

  /// Parse FHIR Bundle response from Medicaid API
  List<Provider> _parseMedicaidResponse(Map<String, dynamic> data, String? specialtyFilter) {
    final List<Provider> providers = [];

    try {
      // FHIR Bundle structure: { "entry": [...] }
      final entries = data['entry'] as List<dynamic>?;
      
      if (entries == null || entries.isEmpty) {
        print('ℹ️ [OhioMedicaid] No entries in response');
        return providers; // Return empty list
      }

      print('🔍 [OhioMedicaid] Parsing ${entries.length} entries');

      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        
        if (entry is! Map<String, dynamic>) {
          print('⚠️ [OhioMedicaid] Entry $i is not a map, skipping');
          continue;
        }
        
        final resource = entry['resource'] as Map<String, dynamic>?;
        if (resource == null) {
          print('⚠️ [OhioMedicaid] Entry $i has no resource field, skipping');
          continue;
        }

        try {
          final provider = _parseFhirResource(resource);
          if (provider != null) {
            // Apply specialty filter locally if provided
            if (specialtyFilter == null || 
                provider.specialties.any((s) => 
                  s.toLowerCase().contains(specialtyFilter.toLowerCase()))) {
              providers.add(provider);
              print('✅ [OhioMedicaid] Parsed provider: ${provider.name}');
            } else {
              print('ℹ️ [OhioMedicaid] Provider ${provider.name} filtered out by specialty');
            }
          } else {
            print('⚠️ [OhioMedicaid] Entry $i parsed to null provider');
          }
        } catch (e, stackTrace) {
          print('⚠️ [OhioMedicaid] Error parsing provider entry $i: $e');
          print('⚠️ [OhioMedicaid] Stack trace: $stackTrace');
          continue;
        }
      }
      
      print('✅ [OhioMedicaid] Successfully parsed ${providers.length} providers');
    } catch (e, stackTrace) {
      print('❌ [OhioMedicaid] Error parsing Medicaid response: $e');
      print('❌ [OhioMedicaid] Stack trace: $stackTrace');
    }

    return providers;
  }

  /// Parse a single FHIR resource into a Provider model
  Provider? _parseFhirResource(Map<String, dynamic> resource) {
    try {
      // Extract name from FHIR resource
      final nameParts = <String>[];
      if (resource['name'] != null) {
        final name = resource['name'];
        if (name is List) {
          for (var n in name) {
            if (n is Map) {
              final given = (n['given'] as List<dynamic>?)?.join(' ') ?? '';
              final family = n['family'] ?? '';
              if (given.isNotEmpty || family.isNotEmpty) {
                nameParts.add('$given $family'.trim());
              }
            }
          }
        } else if (name is Map) {
          final given = (name['given'] as List<dynamic>?)?.join(' ') ?? '';
          final family = name['family'] ?? '';
          if (given.isNotEmpty || family.isNotEmpty) {
            nameParts.add('$given $family'.trim());
          }
        }
      }

      if (nameParts.isEmpty) {
        // Try organization name
        final orgName = resource['name']?.toString() ?? 
                       resource['organization']?['name']?.toString();
        if (orgName != null && orgName.isNotEmpty) {
          nameParts.add(orgName);
        } else {
          return null; // Skip if no name
        }
      }

      // Extract addresses
      final locations = <ProviderLocation>[];
      if (resource['address'] != null) {
        final addresses = resource['address'];
        final addressList = addresses is List ? addresses : [addresses];
        
        for (var addr in addressList) {
          if (addr is Map) {
            final addressLines = (addr['line'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
            final city = addr['city']?.toString() ?? '';
            final state = addr['state']?.toString() ?? 'OH';
            final zip = addr['postalCode']?.toString() ?? '';
            
            if (addressLines.isNotEmpty || city.isNotEmpty) {
              locations.add(ProviderLocation(
                address: addressLines.join(', '),
                city: city,
                state: state,
                zip: zip,
              ));
            }
          }
        }
      }

      // Extract provider types
      final providerTypes = <String>[];
      if (resource['type'] != null) {
        final types = resource['type'];
        if (types is List) {
          for (var type in types) {
            if (type is Map) {
              final coding = type['coding'] as List<dynamic>?;
              if (coding != null) {
                for (var code in coding) {
                  if (code is Map && code['code'] != null) {
                    providerTypes.add(code['code'].toString());
                  }
                }
              }
            }
          }
        }
      }

      // Extract specialties
      final specialties = <String>[];
      if (resource['specialty'] != null) {
        final specialtyList = resource['specialty'];
        if (specialtyList is List) {
          for (var spec in specialtyList) {
            if (spec is Map && spec['text'] != null) {
              specialties.add(spec['text'].toString());
            }
          }
        }
      }

      // Extract telecom (phone, email)
      String? phone;
      String? email;
      if (resource['telecom'] != null) {
        final telecom = resource['telecom'];
        final telecomList = telecom is List ? telecom : [telecom];
        
        for (var contact in telecomList) {
          if (contact is Map) {
            final system = contact['system']?.toString();
            final value = contact['value']?.toString();
            if (system == 'phone' && phone == null) {
              phone = value;
            } else if (system == 'email' && email == null) {
              email = value;
            }
          }
        }
      }

      return Provider(
        name: nameParts.join(', '),
        specialty: specialties.isNotEmpty ? specialties.first : null,
        practiceName: resource['organization']?['name']?.toString(),
        locations: locations,
        providerTypes: providerTypes,
        specialties: specialties,
        phone: phone,
        email: email,
        source: 'medicaid',
      );
    } catch (e) {
      print('⚠️ Error parsing FHIR resource: $e');
      return null;
    }
  }
}
