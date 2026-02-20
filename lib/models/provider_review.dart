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
    this.helpfulCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
  });

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
      'helpfulCount': helpfulCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerified': isVerified,
    };
  }
}
