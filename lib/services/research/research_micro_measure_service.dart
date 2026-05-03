import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Phase 2 — `submitMicroMeasure` / `validateMicroMeasure` callables (see `researchMicroMeasure.ts`).
class ResearchMicroMeasureService {
  ResearchMicroMeasureService._();
  static final ResearchMicroMeasureService instance = ResearchMicroMeasureService._();

  final FirebaseFunctions _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<Map<String, dynamic>> validateMicroMeasure(Map<String, dynamic> fields) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    final callable = _fn.httpsCallable('validateMicroMeasure');
    final res = await callable.call(fields);
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Persists one `research_micro_measures` row (Likert 1–5, required `content_id` / `content_type`).
  Future<void> submitMicroMeasure({
    required String studyId,
    required int microUnderstand,
    required int microNextStep,
    required int microConfidence,
    required String contentId,
    required String contentType,
    String? microTsClientIso,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    final payload = <String, dynamic>{
      'study_id': studyId,
      'micro_understand': microUnderstand,
      'micro_next_step': microNextStep,
      'micro_confidence': microConfidence,
      'content_id': contentId,
      'content_type': contentType,
    };
    if (microTsClientIso != null && microTsClientIso.trim().isNotEmpty) {
      payload['micro_ts_client'] = microTsClientIso.trim();
    }
    final callable = _fn.httpsCallable('submitMicroMeasure');
    await callable.call(payload);
  }
}
