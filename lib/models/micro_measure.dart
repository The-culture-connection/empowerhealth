/// Micro Measure Model
/// Represents a confidence signal / micro measure submission
class MicroMeasure {
  final String? userId;
  final String anonUserId;
  final String feature;
  final String? sourceId; // e.g., module_id, summary_id
  final DateTime timestamp;
  final int? understandMeaningScore;
  final int? knowNextStepScore;
  final int? confidenceScore;

  MicroMeasure({
    required this.userId,
    required this.anonUserId,
    required this.feature,
    this.sourceId,
    required this.timestamp,
    this.understandMeaningScore,
    this.knowNextStepScore,
    this.confidenceScore,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'anonUserId': anonUserId,
      'feature': feature,
      'sourceId': sourceId,
      'timestamp': timestamp, // Will be converted to serverTimestamp in service
      'understandMeaningScore': understandMeaningScore,
      'knowNextStepScore': knowNextStepScore,
      'confidenceScore': confidenceScore,
    };
  }
}
