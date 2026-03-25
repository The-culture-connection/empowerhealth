/// Helpfulness Survey Model
/// Represents a helpfulness rating survey submission
class HelpfulnessSurvey {
  final String? userId;
  final String anonUserId;
  final String feature;
  final String? sourceId; // e.g., module_id, summary_id
  final DateTime timestamp;
  final int? helpfulnessRating;
  final bool? didHelpNextStep;
  final String? notes;

  HelpfulnessSurvey({
    required this.userId,
    required this.anonUserId,
    required this.feature,
    this.sourceId,
    required this.timestamp,
    this.helpfulnessRating,
    this.didHelpNextStep,
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'anonUserId': anonUserId,
      'feature': feature,
      'sourceId': sourceId,
      'timestamp': timestamp, // Will be converted to serverTimestamp in service
      'helpfulnessRating': helpfulnessRating,
      'didHelpNextStep': didHelpNextStep,
      'notes': notes,
    };
  }
}
