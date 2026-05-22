import '../models/user_profile.dart';

/// Profile `currentSupportStage` values.
abstract final class SupportStage {
  static const pregnancyLoss = 'pregnancy_loss';
  static const pregnant = 'pregnant';
  static const postpartum = 'postpartum';
  static const preferNotToAnswer = 'prefer_not_to_answer';
}

/// Firestore `communityStage` on `community_posts`.
abstract final class CommunityStage {
  static const pregnancyLoss = 'pregnancy_loss';
  static const general = 'general';
}

/// Learning module / task category for pregnancy-loss content.
abstract final class LearningModuleCategory {
  static const pregnancyLoss = 'pregnancy_loss';
}

extension UserProfileSupportStage on UserProfile {
  bool get isInPregnancyLossMode {
    if (currentSupportStage == SupportStage.pregnancyLoss) return true;
    if (hidePregnancyMilestones) return true;
    return emotionalSupportPregnancyLoss;
  }
}
