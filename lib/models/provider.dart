import 'package:cloud_firestore/cloud_firestore.dart';

class Provider {
  final String? id;
  final String name;
  final String? specialty;
  final String? practiceName;
  final String? npi;
  final List<ProviderLocation> locations;
  final List<String> providerTypes; // Provider type IDs
  final List<String> specialties;
  final String? phone;
  final String? email;
  final String? website;
  final bool? acceptingNewPatients;
  final bool? acceptsPregnantWomen;
  final bool? acceptsNewborns;
  final bool? telehealth;
  final double? rating;
  final int? reviewCount;
  final bool mamaApproved;
  final int mamaApprovedCount;
  final List<IdentityTag> identityTags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? source; // 'medicaid', 'npi', 'user_submission'
  /// When true, admin hid this Firestore directory row from in-app search / merges.
  final bool directoryHidden;
  /// Single label when present (e.g. "Medicaid", "Commercial").
  final String? acceptedHealthType;
  /// Multiple accepted plan / payer types from Firestore.
  final List<String> acceptedHealthTypes;

  Provider({
    this.id,
    required this.name,
    this.specialty,
    this.practiceName,
    this.npi,
    this.locations = const [],
    this.providerTypes = const [],
    this.specialties = const [],
    this.phone,
    this.email,
    this.website,
    this.acceptingNewPatients,
    this.acceptsPregnantWomen,
    this.acceptsNewborns,
    this.telehealth,
    this.rating,
    this.reviewCount,
    this.mamaApproved = false,
    this.mamaApprovedCount = 0,
    this.identityTags = const [],
    this.createdAt,
    this.updatedAt,
    this.source,
    this.directoryHidden = false,
    this.acceptedHealthType,
    this.acceptedHealthTypes = const [],
  });

  /// Prefer [practiceName] for directory-style listings when set.
  String get primaryDisplayName {
    final p = (practiceName ?? '').trim();
    if (p.isNotEmpty) return p;
    return name;
  }

  /// User-facing coverage / listing source for cards and profile.
  String? get healthCoverageLabel {
    if (acceptedHealthTypes.isNotEmpty) {
      return acceptedHealthTypes.join(' · ');
    }
    final t = (acceptedHealthType ?? '').trim();
    if (t.isNotEmpty) return t;
    return sourceCoverageLabel(source);
  }

  static String? sourceCoverageLabel(String? source) {
    switch (source) {
      case 'medicaid':
        return 'Ohio Medicaid directory';
      case 'npi':
        return 'NPI registry';
      case 'user_submission':
        return 'Community-submitted';
      default:
        if (source == null || source.isEmpty) return null;
        return source;
    }
  }

  /// Minimum reviews and average rating for the Mama Approved™ community badge.
  static const int mamaApprovedMinReviewCount = 3;
  static const double mamaApprovedMinAverageRating = 4.0;

  /// Mama Approved™ in the app: earned from **community reviews** only
  /// (3+ reviews and average ≥ 4★). Not the legacy Firestore `mamaApproved` flag.
  bool get showsMamaApprovedBadge {
    final r = rating;
    if (r == null || r < mamaApprovedMinAverageRating) return false;
    return (reviewCount ?? 0) >= mamaApprovedMinReviewCount;
  }

  factory Provider.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawName = (map['name'] as String?)?.trim() ?? '';
    final rawPractice = (map['practiceName'] as String?)?.trim() ?? '';
    final resolvedName =
        rawName.isNotEmpty ? rawName : (rawPractice.isNotEmpty ? rawPractice : '');
    return Provider(
      id: id ?? map['id'],
      name: resolvedName,
      specialty: map['specialty'],
      practiceName: map['practiceName'],
      npi: map['npi'],
      locations: (map['locations'] as List<dynamic>?)
              ?.map((l) {
                if (l is Map) {
                  final Map<String, dynamic> locationMap = Map<String, dynamic>.from(
                    (l as Map).map((key, value) => MapEntry(key.toString(), value))
                  );
                  return ProviderLocation.fromMap(locationMap);
                }
                return null;
              })
              .whereType<ProviderLocation>()
              .toList() ??
          [],
      providerTypes: (map['providerTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      specialties: (map['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      acceptingNewPatients: map['acceptingNewPatients'] as bool?,
      acceptsPregnantWomen: map['acceptsPregnantWomen'] as bool?,
      acceptsNewborns: map['acceptsNewborns'] as bool?,
      telehealth: map['telehealth'] as bool?,
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount'] as int?,
      mamaApproved: map['mamaApproved'] ?? false,
      mamaApprovedCount: map['mamaApprovedCount'] ?? 0,
      identityTags: (map['identityTags'] as List<dynamic>?)
              ?.map((t) {
                if (t is Map) {
                  final Map<String, dynamic> tagMap = Map<String, dynamic>.from(
                    (t as Map).map((key, value) => MapEntry(key.toString(), value))
                  );
                  return IdentityTag.fromMap(tagMap);
                }
                return null;
              })
              .whereType<IdentityTag>()
              .toList() ??
          [],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      source: map['source'],
      directoryHidden: map['directoryHidden'] == true,
      acceptedHealthType: map['acceptedHealthType'] as String?,
      acceptedHealthTypes: (map['acceptedHealthTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'practiceName': practiceName,
      'npi': npi,
      'locations': locations.map((l) => l.toMap()).toList(),
      'providerTypes': providerTypes,
      'specialties': specialties,
      'phone': phone,
      'email': email,
      'website': website,
      'acceptingNewPatients': acceptingNewPatients,
      'acceptsPregnantWomen': acceptsPregnantWomen,
      'acceptsNewborns': acceptsNewborns,
      'telehealth': telehealth,
      'rating': rating,
      'reviewCount': reviewCount,
      'mamaApproved': mamaApproved,
      'mamaApprovedCount': mamaApprovedCount,
      'identityTags': identityTags.map((t) => t.toMap()).toList(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'source': source,
      'directoryHidden': directoryHidden,
      'acceptedHealthType': acceptedHealthType,
      'acceptedHealthTypes': acceptedHealthTypes,
    };
  }

  Provider copyWith({
    String? id,
    String? name,
    String? specialty,
    String? practiceName,
    String? npi,
    List<ProviderLocation>? locations,
    List<String>? providerTypes,
    List<String>? specialties,
    String? phone,
    String? email,
    String? website,
    bool? acceptingNewPatients,
    bool? acceptsPregnantWomen,
    bool? acceptsNewborns,
    bool? telehealth,
    double? rating,
    int? reviewCount,
    bool? mamaApproved,
    int? mamaApprovedCount,
    List<IdentityTag>? identityTags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
    bool? directoryHidden,
    String? acceptedHealthType,
    List<String>? acceptedHealthTypes,
  }) {
    return Provider(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      practiceName: practiceName ?? this.practiceName,
      npi: npi ?? this.npi,
      locations: locations ?? this.locations,
      providerTypes: providerTypes ?? this.providerTypes,
      specialties: specialties ?? this.specialties,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      acceptingNewPatients: acceptingNewPatients ?? this.acceptingNewPatients,
      acceptsPregnantWomen: acceptsPregnantWomen ?? this.acceptsPregnantWomen,
      acceptsNewborns: acceptsNewborns ?? this.acceptsNewborns,
      telehealth: telehealth ?? this.telehealth,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      mamaApproved: mamaApproved ?? this.mamaApproved,
      mamaApprovedCount: mamaApprovedCount ?? this.mamaApprovedCount,
      identityTags: identityTags ?? this.identityTags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      directoryHidden: directoryHidden ?? this.directoryHidden,
      acceptedHealthType: acceptedHealthType ?? this.acceptedHealthType,
      acceptedHealthTypes: acceptedHealthTypes ?? this.acceptedHealthTypes,
    );
  }
}

class ProviderLocation {
  final String? id;
  final String address;
  final String? address2;
  final String city;
  final String state;
  final String zip;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? distance; // Distance in miles from search location

  ProviderLocation({
    this.id,
    required this.address,
    this.address2,
    required this.city,
    required this.state,
    required this.zip,
    this.phone,
    this.latitude,
    this.longitude,
    this.distance,
  });

  factory ProviderLocation.fromMap(Map<String, dynamic> map) {
    return ProviderLocation(
      id: map['id'],
      address: map['address'] ?? '',
      address2: map['address2'],
      city: map['city'] ?? '',
      state: map['state'] ?? 'OH',
      zip: map['zip'] ?? '',
      phone: map['phone'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      distance: map['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'address2': address2,
      'city': city,
      'state': state,
      'zip': zip,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
    };
  }

  String get fullAddress {
    final parts = [address];
    if (address2 != null && address2!.isNotEmpty) parts.add(address2!);
    // Ensure ZIP is only 5 digits
    final zipCode = zip.length > 5 ? zip.substring(0, 5) : zip;
    parts.add('$city, $state $zipCode');
    return parts.join(', ');
  }

  /// ZIP normalized for display (5 digits when longer).
  String get zipDisplay {
    final z = zip.trim();
    return z.length > 5 ? z.substring(0, 5) : z;
  }

  /// City, ST ZIP on one line (readable spacing).
  String get cityStateZipLine {
    final c = city.trim();
    final s = state.trim();
    return '$c, $s $zipDisplay'.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Street line(s) without duplicating city/state when the API puts everything in [address].
  List<String> get addressLines {
    final zip5 = zipDisplay;
    final cityLine = cityStateZipLine;
    var street = address.trim();
    final suite = (address2 ?? '').trim();
    if (suite.isNotEmpty) {
      street = street.isEmpty ? suite : '$street, $suite';
    }
    if (street.isEmpty) {
      return cityLine.isNotEmpty ? [cityLine] : [];
    }
    final lower = street.toLowerCase();
    final cityLower = city.trim().toLowerCase();
    final hasCity = cityLower.isNotEmpty && lower.contains(cityLower);
    final hasZip = zip5.isNotEmpty && lower.contains(zip5);
    final hasState = state.trim().length == 2 &&
        lower.contains(state.trim().toLowerCase());
    if (hasCity && (hasZip || hasState)) {
      return [street];
    }
    return [street, cityLine];
  }
}

class IdentityTag {
  final String id;
  final String name;
  final String category; // e.g., 'race', 'language', 'specialty', 'certification'
  final String source; // 'user_claim', 'verified', 'admin'
  final String verificationStatus; // 'pending', 'verified', 'disputed'
  final DateTime? verifiedAt;
  final String? verifiedBy;

  IdentityTag({
    required this.id,
    required this.name,
    required this.category,
    required this.source,
    required this.verificationStatus,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory IdentityTag.fromMap(Map<String, dynamic> map) {
    return IdentityTag(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      source: map['source'] ?? 'user_claim',
      verificationStatus: map['verificationStatus'] ?? 'pending',
      verifiedAt: map['verifiedAt'] is Timestamp
          ? (map['verifiedAt'] as Timestamp).toDate()
          : null,
      verifiedBy: map['verifiedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'source': source,
      'verificationStatus': verificationStatus,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
    };
  }
}
