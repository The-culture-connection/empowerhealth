import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Phase 5 — `scheduleMilestonePrompt`, `submitMilestoneCheckIn`, `validateMilestoneCheckIn`.
class ResearchMilestoneService {
  ResearchMilestoneService._();
  static final ResearchMilestoneService instance = ResearchMilestoneService._();

  /// Match [AnalyticsService] and deployed Gen-2 callables (us-central1).
  final FirebaseFunctions _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Maps legacy string `phase` labels (e.g. from [MilestoneCheckin]) to server milestone_type codes.
  static int milestoneTypeFromLegacyPhase(String? phase) {
    switch (phase) {
      case 'late_pregnancy':
      case 'late_third_trimester':
        return 1;
      case 'third_trimester':
        return 2;
      case 'postpartum_early':
        return 3;
      case 'postpartum':
      case 'postpartum_mid':
        return 4;
      case 'postpartum_later':
        return 5;
      default:
        return 9;
    }
  }

  static int boolToYesNo(bool v) => v ? 1 : 0;

  /// Participant tracker: journey steps, completion flags, [badge_dot] for home bell.
  Future<Map<String, dynamic>> getMilestoneTrackerSummary({String? studyId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final callable = _fn.httpsCallable('getMilestoneTrackerSummary');
    final payload = <String, dynamic>{};
    if (studyId != null && studyId.isNotEmpty) payload['study_id'] = studyId;
    final res = await callable.call(payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> scheduleMilestonePrompt({required String studyId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final callable = _fn.httpsCallable('scheduleMilestonePrompt');
    final res = await callable.call({'study_id': studyId});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> validateMilestoneCheckIn(Map<String, dynamic> fields) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final callable = _fn.httpsCallable('validateMilestoneCheckIn');
    final res = await callable.call(fields);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> submitMilestoneCheckIn({
    required String studyId,
    required int milestoneType,
    required bool milestoneHealthQuestion,
    required bool milestoneClearNextStep,
    required bool milestoneAppHelpedNextStep,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final callable = _fn.httpsCallable('submitMilestoneCheckIn');
    await callable.call({
      'study_id': studyId,
      'milestone_type': milestoneType,
      'milestone_health_question': boolToYesNo(milestoneHealthQuestion),
      'milestone_clear_next_step': boolToYesNo(milestoneClearNextStep),
      'milestone_app_helped_next_step': boolToYesNo(milestoneAppHelpedNextStep),
    });
  }
}
