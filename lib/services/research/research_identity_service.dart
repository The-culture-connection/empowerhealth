import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Callables for Phase 1 research identity + baseline (see `researchIdentity.ts`).
class ResearchIdentityService {
  ResearchIdentityService._();
  static final ResearchIdentityService instance = ResearchIdentityService._();

  final FirebaseFunctions _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<Map<String, dynamic>> createResearchParticipant({
    required int recruitmentSource,
    String? recruitmentSourceOtherText,
    required int recruitmentPathway,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    final callable = _fn.httpsCallable('createResearchParticipant');
    final payload = <String, dynamic>{
      'recruitment_source': recruitmentSource,
      'recruitment_pathway': recruitmentPathway,
    };
    if (recruitmentSource == 6 && recruitmentSourceOtherText != null) {
      payload['recruitment_source_other'] = recruitmentSourceOtherText;
    }
    final res = await callable.call(payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> validateResearchBaseline(Map<String, dynamic> fields) async {
    final callable = _fn.httpsCallable('validateResearchBaseline');
    final res = await callable.call(fields);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> submitBaselineResearchData(Map<String, dynamic> fields) async {
    final callable = _fn.httpsCallable('submitBaselineResearchData');
    final res = await callable.call(fields);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<MapEntry<int, String>>> listRecruitmentPathways() async {
    final callable = _fn.httpsCallable('listRecruitmentPathways');
    final res = await callable.call();
    final data = res.data as Map<dynamic, dynamic>;
    final raw = data['pathways'];
    if (raw is! List) return [];
    final out = <MapEntry<int, String>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final code = item['code'];
      final label = item['label'];
      if (code is num && label is String && label.trim().isNotEmpty) {
        out.add(MapEntry(code.toInt(), label.trim()));
      }
    }
    out.sort((a, b) => a.key.compareTo(b.key));
    return out;
  }

  Future<int> deriveAgeGroup(int ageYears) async {
    final callable = _fn.httpsCallable('deriveAgeGroup');
    final res = await callable.call({'age_years': ageYears});
    final data = res.data as Map<dynamic, dynamic>;
    return (data['age_group'] as num).toInt();
  }
}
