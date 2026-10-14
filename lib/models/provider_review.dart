import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderReview {
  final String? id;
  final String providerId;
  final String userId;
  final String? userName; // Optional, can be anonymous
  final int rating; // 1-5
  final String? reviewText;
  final Map<String, dynamic>? experienceFields; // Custom experience fields
  final bool wouldRecommend;
  /// Experience prompts (optional; stored for transparency / filters later).
  final bool feltHeard;
  final bool feltRespected;
  final bool explainedClearly;
  /// Short answer: what the provider did especially well.
  final String? whatWentWell;
  /// Reviewer self-report: race/ethnicity labels (optional).
  final List<String> reviewerRaceEthnicity;
  /// Reviewer self-report: languages (optional).
  final List<String> reviewerLanguages;
  /// Reviewer self-report: cultural / community tags (optional).
  final List<String> reviewerCulturalTags;
  /// published | pending | removed | resolved — moderation (app lists published only).
  final String status;
  final int helpfulCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified; // Verified patient

  ProviderReview({
    this.id,
    required this.providerId,
    required this.userId,
    this.userName,
    required this.rating,
    this.reviewText,
    this.experienceFields,
    required this.wouldRecommend,
    this.feltHeard = false,
    this.feltRespected = false,
    this.explainedClearly = false,
    this.whatWentWell,
    this.reviewerRaceEthnicity = const [],
    this.reviewerLanguages = const [],
    this.reviewerCulturalTags = const [],
    this.status = 'published',
    this.helpfulCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
  });

  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  factory ProviderReview.fromMap(Map<String, dynamic> map, {String? id}) {
    return ProviderReview(
      id: id ?? map['id'],
      providerId: map['providerId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'],
      rating: map['rating'] ?? 0,
      reviewText: map['reviewText'],
      experienceFields: map['experienceFields'] as Map<String, dynamic>?,
      wouldRecommend: map['wouldRecommend'] ?? false,
      feltHeard: map['feltHeard'] ?? false,
      feltRespected: map['feltRespected'] ?? false,
      explainedClearly: map['explainedClearly'] ?? false,
      whatWentWell: map['whatWentWell'] as String?,
      reviewerRaceEthnicity: _stringList(map['reviewerRaceEthnicity']),
      reviewerLanguages: _stringList(map['reviewerLanguages']),
      reviewerCulturalTags: _stringList(map['reviewerCulturalTags']),
      status: map['status'] as String? ?? 'published',
      helpfulCount: map['helpfulCount'] ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'reviewText': reviewText,
      'experienceFields': experienceFields,
      'wouldRecommend': wouldRecommend,
      'feltHeard': feltHeard,
      'feltRespected': feltRespected,
      'explainedClearly': explainedClearly,
      'whatWentWell': whatWentWell,
      if (reviewerRaceEthnicity.isNotEmpty)
        'reviewerRaceEthnicity': reviewerRaceEthnicity,
      if (reviewerLanguages.isNotEmpty) 'reviewerLanguages': reviewerLanguages,
      if (reviewerCulturalTags.isNotEmpty)
        'reviewerCulturalTags': reviewerCulturalTags,
      'status': status,
      'helpfulCount': helpfulCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerified': isVerified,
    };
  }
}
