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
  });

  factory Provider.fromMap(Map<String, dynamic> map, {String? id}) {
    return Provider(
      id: id ?? map['id'],
      name: map['name'] ?? '',
      specialty: map['specialty'],
      practiceName: map['practiceName'],
      npi: map['npi'],
      locations: (map['locations'] as List<dynamic>?)
              ?.map((l) => ProviderLocation.fromMap(l as Map<String, dynamic>))
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
              ?.map((t) => IdentityTag.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      source: map['source'],
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
    double? rating,
    int? reviewCount,
    bool? mamaApproved,
    int? mamaApprovedCount,
    List<IdentityTag>? identityTags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
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
