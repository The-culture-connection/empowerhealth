/// Analytics Event Model
/// Represents a normalized analytics event for Firestore storage
class AnalyticsEvent {
  final String? userId;
  final String anonUserId;
  final String eventName;
  final String feature;
  final DateTime timestamp;
  final String sessionId;
  final String? cohortType;
  final int? gestationalWeek;
  final String? trimester;
  final Map<String, dynamic> metadata;

  AnalyticsEvent({
    required this.userId,
    required this.anonUserId,
    required this.eventName,
    required this.feature,
    required this.timestamp,
    required this.sessionId,
    this.cohortType,
    this.gestationalWeek,
    this.trimester,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'anonUserId': anonUserId,
      'eventName': eventName,
      'feature': feature,
      'timestamp': timestamp, // Will be converted to serverTimestamp in service
      'sessionId': sessionId,
      'cohortType': cohortType,
      'gestationalWeek': gestationalWeek,
      'trimester': trimester,
      'metadata': metadata,
    };
  }
}
