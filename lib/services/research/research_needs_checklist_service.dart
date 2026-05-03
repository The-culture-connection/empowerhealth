import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Phase 3 — `submitNeedsChecklist` / `validateNeedsChecklist` (see `researchNeedsChecklist.ts`).
class ResearchNeedsChecklistService {
  ResearchNeedsChecklistService._();
  static final ResearchNeedsChecklistService instance = ResearchNeedsChecklistService._();

  final FirebaseFunctions _fn = FirebaseFunctions.instance;

  /// Care survey chip ids from [CareNavigationSurveyScreen] → research binary columns.
  static const Map<String, String> _careIdToField = {
    'prenatal-postpartum': 'need_prenatal_postpartum',
    'labor-delivery': 'need_delivery_prep',
    'blood-pressure': 'need_med_followup',
    'mental-health': 'need_mental_health',
    'lactation': 'need_lactation',
    'infant-pediatric': 'need_infant_care',
    'benefits': 'need_benefits',
    'transportation': 'need_transport',
    'other': 'need_other',
  };

  Future<Map<String, dynamic>> validateNeedsChecklist(Map<String, dynamic> fields) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final callable = _fn.httpsCallable('validateNeedsChecklist');
    final res = await callable.call(fields);
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// All nine need_* fields are sent as `0` or `1`. [otherText] required when `other` is in [selectedCareNeedIds].
  /// Returns Firestore document id for `research_needs_checklists/{event_id}` when the callable succeeds.
  Future<String?> submitNeedsChecklist({
    required String studyId,
    required List<String> selectedCareNeedIds,
    String? otherText,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');

    final payload = <String, dynamic>{'study_id': studyId};
    for (final e in _careIdToField.entries) {
      final field = e.value;
      final v = selectedCareNeedIds.contains(e.key) ? 1 : 0;
      payload[field] = v;
    }

    final needOther = (payload['need_other'] as int) == 1;
    if (needOther) {
      final t = otherText?.trim() ?? '';
      if (t.isEmpty) {
        throw StateError('Describe what you mean by Other before submitting.');
      }
      payload['need_other_text'] = t;
    }

    final callable = _fn.httpsCallable('submitNeedsChecklist');
    final res = await callable.call(payload);
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['event_id'] as String?;
  }
}
