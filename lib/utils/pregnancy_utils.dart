class PregnancyUtils {
  /// Calculate current trimester based on due date
  static String calculateTrimester(DateTime? dueDate) {
    if (dueDate == null) return 'First';
    
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    final weeksPregnant = 40 - (daysUntilDue / 7).floor();
    
    if (weeksPregnant <= 0) return 'First';
    if (weeksPregnant <= 13) return 'First';
    if (weeksPregnant <= 27) return 'Second';
    return 'Third';
  }

  /// Calculate weeks pregnant based on due date
  static int calculateWeeksPregnant(DateTime? dueDate) {
    if (dueDate == null) return 0;
    
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    final weeksPregnant = 40 - (daysUntilDue / 7).floor();
    
    return weeksPregnant > 0 ? weeksPregnant : 0;
  }

  /// Get trimester-specific information
  static String getTrimesterInfo(String trimester) {
    switch (trimester) {
      case 'First':
        return 'Weeks 1-13';
      case 'Second':
        return 'Weeks 14-27';
      case 'Third':
        return 'Weeks 28-40';
      default:
        return '';
    }
  }

  /// Check if pregnancy is high-risk based on conditions
  static bool isHighRisk(List<String> chronicConditions) {
    const highRiskConditions = [
      'Diabetes',
      'Hypertension',
      'Heart Disease',
      'Kidney Disease',
      'Autoimmune Disease',
      'Blood Clotting Disorder',
    ];

    for (var condition in chronicConditions) {
      if (highRiskConditions.any((risk) => 
        condition.toLowerCase().contains(risk.toLowerCase()))) {
        return true;
      }
    }
    return false;
  }
}

