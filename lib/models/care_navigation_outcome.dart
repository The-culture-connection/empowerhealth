/// Care Navigation Outcome Model
/// Represents a care navigation outcome submission
class CareNavigationOutcome {
  final String? userId;
  final String anonUserId;
  final DateTime timestamp;
  final String needType; // e.g., "find_provider", "understand_diagnosis"
  final String? sourceFeature; // e.g., "provider-search", "learning-modules"
  final bool neededHelp;
  final String outcome; // "yes" | "partly" | "no" | "didnt_try" | "didnt_know_how" | "couldnt_access"
  final String? notes;

  CareNavigationOutcome({
    required this.userId,
    required this.anonUserId,
    required this.timestamp,
    required this.needType,
    this.sourceFeature,
    required this.neededHelp,
    required this.outcome,
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'anonUserId': anonUserId,
      'timestamp': timestamp, // Will be converted to serverTimestamp in service
      'needType': needType,
      'sourceFeature': sourceFeature,
      'neededHelp': neededHelp,
      'outcome': outcome,
      'notes': notes,
    };
  }
}
