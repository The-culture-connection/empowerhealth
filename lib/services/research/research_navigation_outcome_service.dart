import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Phase 4 — `submitNavigationOutcome` / `validateNavigationOutcome` / `linkOutcomeToNeedsEvent`.
class ResearchNavigationOutcomeService {
  ResearchNavigationOutcomeService._();
  static final ResearchNavigationOutcomeService instance = ResearchNavigationOutcomeService._();

  final FirebaseFunctions _fn = FirebaseFunctions.instance;

  /// Maps care access step string values to research codes 1–6 (0 reserved for N/A on server).
  static int careAccessToOutcomeCode(String raw) {
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

  static const List<(String careId, String outcomeKey)> _careToOutcome = [
    ('prenatal-postpartum', 'need_prenatal_postpartum_outcome'),
    ('labor-delivery', 'need_delivery_prep_outcome'),
    ('blood-pressure', 'need_med_followup_outcome'),
    ('mental-health', 'need_mental_health_outcome'),
    ('lactation', 'need_lactation_outcome'),
    ('infant-pediatric', 'need_infant_care_outcome'),
    ('benefits', 'need_benefits_outcome'),
    ('transportation', 'need_transport_outcome'),
    ('other', 'need_other_outcome'),
  ];

  /// Builds the callable payload: `0` for needs not selected; `1–6` for each answered selected need.
  static Map<String, dynamic> buildOutcomePayload({
    required String studyId,
    required String needsEventId,
    required List<String> selectedCareNeedIds,
    required Map<String, String> accessResponsesByCareId,
  }) {
    final payload = <String, dynamic>{
      'study_id': studyId,
      'needs_event_id': needsEventId,
    };
    for (final row in _careToOutcome) {
      final careId = row.$1;
      final key = row.$2;
      if (!selectedCareNeedIds.contains(careId)) {
        payload[key] = 0;
      } else {
        final raw = accessResponsesByCareId[careId];
        if (raw == null || raw.isEmpty) {
          throw StateError('Missing access response for $careId');
        }
        payload[key] = careAccessToOutcomeCode(raw);
      }
    }
    return payload;
  }

  Future<Map<String, dynamic>> validateNavigationOutcome(Map<String, dynamic> fields) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final callable = _fn.httpsCallable('validateNavigationOutcome');
    final res = await callable.call(fields);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> submitNavigationOutcome(Map<String, dynamic> fields) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final callable = _fn.httpsCallable('submitNavigationOutcome');
    await callable.call(fields);
  }

  Future<void> linkOutcomeToNeedsEvent({
    required String studyId,
    required String needsEventId,
    required String outcomeEventId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final callable = _fn.httpsCallable('linkOutcomeToNeedsEvent');
    await callable.call({
      'study_id': studyId,
      'needs_event_id': needsEventId,
      'outcome_event_id': outcomeEventId,
    });
  }
}
