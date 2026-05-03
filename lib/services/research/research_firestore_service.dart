import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';

/// Structured research rows keyed by [studyId] (see admin `research_*` collections).
class ResearchFirestoreService {
  ResearchFirestoreService._();
  static final ResearchFirestoreService instance = ResearchFirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _newStudyId() {
    final t = DateTime.now().toUtc().millisecondsSinceEpoch;
    final r = Random().nextInt(1 << 20).toRadixString(16);
    return 'EH$t$r';
  }

  int _recruitmentSourceCode(String? source) {
    switch (source) {
      case 'research_participant':
        return 1;
      case 'clinic_partner':
      case 'clinic':
        return 2;
      case 'community':
        return 3;
      case 'social':
      case 'social_media':
        return 4;
      case 'referral':
        return 5;
      case 'search':
        return 6;
      case 'other':
        return 6;
      default:
        return 7;
    }
  }

  int _insuranceTypeCode(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('medicaid')) return 1;
    if (s.contains('medicare')) return 2;
    if (s.contains('private') || s.contains('employer')) return 3;
    if (s.isEmpty) return 4;
    return 4;
  }

  int _ppStatus(UserProfile p) {
    if (p.isPostpartum) return 2;
    return 1;
  }

  /// Ensures `users/{uid}.studyId` exists for enrolled research participants.
  Future<String?> ensureStudyId(UserProfile? profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || profile == null) return null;
    if (!profile.isResearchParticipant) return null;

    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    final existing = snap.data()?['studyId'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    final studyId = _newStudyId();
    await ref.set({'studyId': studyId, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    return studyId;
  }

  Future<void> syncParticipantAndBaseline({
    required String studyId,
    required UserProfile profile,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final recruitmentPathway = profile.hasPrimaryProvider ? 1 : 2;
    final recruitmentSource = _recruitmentSourceCode(profile.recruitmentSource);
    final recordedAt = FieldValue.serverTimestamp();

    final participant = {
      'study_id': studyId,
      'research_participant': 1,
      'recruitment_source': recruitmentSource,
      'recruitment_source_other': null,
      'recruitment_pathway': recruitmentPathway,
      'recorded_at': recordedAt,
    };

    await _db.collection('research_participants').doc(studyId).set(participant, SetOptions(merge: true));

    final baseline = {
      'study_id': studyId,
      'recruitment_pathway': recruitmentPathway,
      'age_years': profile.age,
      'age_group': _ageGroup(profile.age),
      'pp_status': _ppStatus(profile),
      'gest_week': null,
      'postpartum_month': profile.isPostpartum ? profile.childAgeMonths : null,
      'insurance_type': _insuranceTypeCode(profile.insuranceType),
      'insurance_other': null,
      'support_person_nav': profile.hasSupportPerson ? 1 : 0,
      'baseline_advocacy_conf': null,
      'baseline_ts': recordedAt,
      'recorded_at': recordedAt,
    };

    await _db.collection('research_baseline').doc(studyId).set(baseline, SetOptions(merge: true));
  }

  String _ageGroup(int age) {
    if (age < 18) return 'under_18';
    if (age <= 24) return '18_24';
    if (age <= 34) return '25_34';
    if (age <= 44) return '35_44';
    return '45_plus';
  }

  Future<void> recordMicroMeasure({
    required String studyId,
    required int? understand,
    required int? nextStep,
    required int? confidence,
    String? contentId,
    String contentType = 'micro_measure',
  }) async {
    final recordedAt = FieldValue.serverTimestamp();
    final microTs = recordedAt;
    await _db.collection('research_micro_measures').add({
      'study_id': studyId,
      'micro_understand': understand,
      'micro_next_step': nextStep,
      'micro_confidence': confidence,
      'content_id': contentId ?? '',
      'content_type': contentType,
      'micro_ts': microTs,
      'recorded_at': recordedAt,
    });
  }

  int? _boolNum(bool? v) {
    if (v == null) return null;
    return v ? 1 : 0;
  }

  Future<void> recordMilestoneCheckin({
    required String studyId,
    String? phase,
    bool? hadHealthQuestion,
    bool? feltClearOnNextStep,
    bool? appHelpedTakeNextStep,
  }) async {
    final recordedAt = FieldValue.serverTimestamp();
    await _db.collection('research_milestone_prompts').add({
      'study_id': studyId,
      'milestone_health_question': _boolNum(hadHealthQuestion),
      'milestone_clear_next_step': _boolNum(feltClearOnNextStep),
      'milestone_app_helped_next_step': _boolNum(appHelpedTakeNextStep),
      'milestone_type': phase ?? 'checkin',
      'milestone_ts': recordedAt,
      'recorded_at': recordedAt,
    });
  }

  int _navOutcomeCode(String raw) {
    switch (raw.toLowerCase().replaceAll('_', '-').replaceAll(' ', '')) {
      case 'yes':
        return 1;
      case 'partly':
        return 2;
      case 'no':
        return 3;
      case 'didnt-try':
      case 'didnttry':
        return 4;
      case 'didnt-know':
      case 'didntknow':
      case 'didnt-know-how':
      case 'didntknowhow':
        return 5;
      case 'couldnt-access':
      case 'couldntaccess':
        return 6;
      default:
        return 3;
    }
  }

  String? _outcomeFieldForNeed(String needType) {
    final n = needType.toLowerCase();
    const map = {
      'prenatal-postpartum': 'need_prenatal_postpartum_outcome',
      'labor-delivery': 'need_delivery_prep_outcome',
      'blood-pressure': 'need_med_followup_outcome',
      'mental-health': 'need_mental_health_outcome',
      'lactation': 'need_lactation_outcome',
      'infant-pediatric': 'need_infant_care_outcome',
      'benefits': 'need_benefits_outcome',
      'transportation': 'need_transport_outcome',
      'other': 'need_other_outcome',
    };
    return map[n];
  }

  Future<void> recordNavigationOutcomeRow({
    required String studyId,
    required String needType,
    required String outcome,
  }) async {
    final field = _outcomeFieldForNeed(needType);
    if (field == null) return;
    final recordedAt = FieldValue.serverTimestamp();
    await _db.collection('research_navigation_outcomes').add({
      'study_id': studyId,
      field: _navOutcomeCode(outcome),
      'navigation_ts': recordedAt,
      'recorded_at': recordedAt,
    });
  }

  Future<void> recordAppActivity({
    required String studyId,
    required String activityType,
    Map<String, dynamic>? extra,
  }) async {
    final recordedAt = FieldValue.serverTimestamp();
    await _db.collection('research_app_activity').add({
      'study_id': studyId,
      'activity_type': activityType,
      'module_id': extra?['module_id'],
      'avs_upload_type': extra?['avs_upload_type'],
      'library_section': extra?['library_section'],
      'provider_review_action': extra?['provider_review_action'],
      'extra': extra,
      'activity_ts': recordedAt,
      'recorded_at': recordedAt,
    });
  }
}
