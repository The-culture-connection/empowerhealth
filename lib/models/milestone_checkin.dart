/// Milestone Checkin Model
/// Represents a milestone check-in submission
class MilestoneCheckin {
  final String? userId;
  final String anonUserId;
  final DateTime timestamp;
  final String? phase; // e.g., "first_trimester", "postpartum"
  final bool? hadHealthQuestion;
  final bool? feltClearOnNextStep;
  final bool? appHelpedTakeNextStep;

  MilestoneCheckin({
    required this.userId,
    required this.anonUserId,
    required this.timestamp,
    this.phase,
    this.hadHealthQuestion,
    this.feltClearOnNextStep,
    this.appHelpedTakeNextStep,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'anonUserId': anonUserId,
      'timestamp': timestamp, // Will be converted to serverTimestamp in service
      'phase': phase,
      'hadHealthQuestion': hadHealthQuestion,
      'feltClearOnNextStep': feltClearOnNextStep,
      'appHelpedTakeNextStep': appHelpedTakeNextStep,
    };
  }
}
