import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Phase 6 — structured `research_app_activity` rows via Cloud Functions only.
class ResearchAppActivityService {
  ResearchAppActivityService._();
  static final ResearchAppActivityService instance = ResearchAppActivityService._();

  final FirebaseFunctions _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> recordModuleCompletion({
    required String studyId,
    required String moduleId,
    int moduleCompletion = 1,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await _fn.httpsCallable('recordModuleCompletion').call(<String, dynamic>{
      'study_id': studyId,
      'module_id': moduleId,
      'module_completion': moduleCompletion,
    });
  }

  Future<void> recordProviderReviewActivity({
    required String studyId,
    required int providerReviewActivity,
    String? moduleId,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final payload = <String, dynamic>{
      'study_id': studyId,
      'provider_review_activity': providerReviewActivity,
    };
    if (moduleId != null && moduleId.isNotEmpty) {
      payload['module_id'] = moduleId;
    }
    await _fn.httpsCallable('recordProviderReviewActivity').call(payload);
  }

  Future<void> recordAvsUploadActivity({
    required String studyId,
    required String avsUploadType,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await _fn.httpsCallable('recordAvsUploadActivity').call(<String, dynamic>{
      'study_id': studyId,
      'avs_upload_type': avsUploadType,
    });
  }

  Future<void> recordHealthMadeSimpleAccess({
    required String studyId,
    required String healthMadeSimpleAccess,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await _fn.httpsCallable('recordHealthMadeSimpleAccess').call(<String, dynamic>{
      'study_id': studyId,
      'health_made_simple_access': healthMadeSimpleAccess,
    });
  }
}
