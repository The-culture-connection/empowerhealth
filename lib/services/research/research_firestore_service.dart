import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import 'research_micro_measure_service.dart';

/// Structured research rows keyed by [studyId] (see admin `research_*` collections).
class ResearchFirestoreService {
  ResearchFirestoreService._();
  static final ResearchFirestoreService instance = ResearchFirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns `users/{uid}.studyId` when Phase 1 research onboarding has completed (server-issued ID).
  Future<String?> ensureStudyId(UserProfile? profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || profile == null) return null;
    if (!profile.isResearchParticipant) return null;

    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    final existing = snap.data()?['studyId'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    return null;
  }

  /// Initial participant + baseline rows are created by Cloud Functions during research onboarding.
  /// Micro-measures are written only via [submitMicroMeasure] (see `researchMicroMeasure.ts`).
  Future<void> syncParticipantAndBaseline({
    required String studyId,
    required UserProfile profile,
  }) async {
    // No-op: avoids client-authored baseline that bypasses server validation and skip logic.
  }

  Future<void> recordMicroMeasure({
    required String studyId,
    required int understand,
    required int nextStep,
    required int confidence,
    required String contentId,
    String contentType = 'micro_measure',
    String? microTsClientIso,
  }) async {
    await ResearchMicroMeasureService.instance.submitMicroMeasure(
      studyId: studyId,
      microUnderstand: understand,
      microNextStep: nextStep,
      microConfidence: confidence,
      contentId: contentId,
      contentType: contentType,
      microTsClientIso: microTsClientIso,
    );
  }
}
