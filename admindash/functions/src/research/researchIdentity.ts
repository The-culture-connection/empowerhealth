/**
 * Phase 1 — Research identity + baseline: callable APIs (admin SDK; bypasses client rules safely).
 */
import * as crypto from 'crypto';
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  CODE_PP_STATUS,
  deriveAgeGroupCode,
  INSURANCE_TYPE_CODES,
  LIKERT_MAX,
  LIKERT_MIN,
} from './researchFieldSpec';

const db = admin.firestore();

function newStudyId(): string {
  const t = Date.now().toString(36);
  const r = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `EH${t}${r}`;
}

const EMAIL_LIKE = /@|\bmail\b|\bemail\b/i;

function containsPiiPayload(data: unknown): boolean {
  if (data == null) return false;
  if (typeof data === 'string') {
    if (EMAIL_LIKE.test(data)) return true;
    return false;
  }
  if (typeof data === 'object' && !Array.isArray(data)) {
    for (const [k, v] of Object.entries(data as Record<string, unknown>)) {
      const key = k.toLowerCase();
      if (
        key.includes('email') ||
        key.includes('displayname') ||
        key.includes('phone') ||
        key.includes('name') && key.includes('first')
      ) {
        return true;
      }
      if (containsPiiPayload(v)) return true;
    }
  }
  if (Array.isArray(data)) {
    return data.some((x) => containsPiiPayload(x));
  }
  return false;
}

function asInt(n: unknown, min: number, max: number): number | undefined {
  const x = typeof n === 'number' ? n : typeof n === 'string' ? parseInt(String(n), 10) : NaN;
  if (!Number.isFinite(x)) return undefined;
  const f = Math.floor(x);
  if (f < min || f > max) return undefined;
  return f;
}

function coerceRecruitmentSource(raw: unknown): number | undefined {
  const n = asInt(raw, 1, 7);
  if (n != null) return n;
  if (typeof raw !== 'string') return undefined;
  switch (raw) {
    case 'doula':
    case 'chw':
    case 'home_visitor':
    case 'cbo':
    case 'event':
      return 2;
    case 'social_media':
      return 3;
    case 'research_participant':
      return 4;
    case 'other':
      return 6;
    default:
      return 7;
  }
}

export function validateResearchBaselinePayload(data: Record<string, unknown>): string[] {
  const errors: string[] = [];
  if (containsPiiPayload(data)) {
    errors.push('payload_contains_disallowed_identifiers');
  }

  const pp = asInt(data.pp_status, 1, 2);
  if (pp == null) errors.push('pp_status_invalid');

  const ageYears = asInt(data.age_years, 13, 100);
  if (ageYears == null) errors.push('age_years_invalid');

  const pathway = asInt(data.recruitment_pathway, 1, 2);
  if (pathway == null) errors.push('recruitment_pathway_invalid');

  const insuranceType = asInt(data.insurance_type, 1, 6);
  if (insuranceType == null) errors.push('insurance_type_invalid');

  const nav = asInt(data.support_person_nav, 1, 6);
  if (nav == null) errors.push('support_person_nav_invalid');

  const adv = data.baseline_advocacy_conf;
  if (adv != null && adv !== '') {
    const a = asInt(adv, LIKERT_MIN, LIKERT_MAX);
    if (a == null) errors.push('baseline_advocacy_conf_invalid');
  } else {
    errors.push('baseline_advocacy_conf_required');
  }

  const gest = data.gest_week;
  const ppm = data.postpartum_month;

  if (pp === CODE_PP_STATUS.pregnant) {
    const g = gest == null || gest === '' ? undefined : asInt(gest, 4, 42);
    if (g == null) errors.push('gest_week_required_when_pregnant');
    if (ppm != null && ppm !== '') errors.push('postpartum_month_must_be_null_when_pregnant');
  } else if (pp === CODE_PP_STATUS.postpartum) {
    const m = ppm == null || ppm === '' ? undefined : asInt(ppm, 0, 48);
    if (m == null) errors.push('postpartum_month_required_when_postpartum');
    if (gest != null && gest !== '') errors.push('gest_week_must_be_null_when_postpartum');
  }

  if (insuranceType === INSURANCE_TYPE_CODES.other) {
    const other = data.insurance_other;
    if (typeof other !== 'string' || !other.trim()) {
      errors.push('insurance_other_required_when_insurance_other');
    } else if (EMAIL_LIKE.test(other)) {
      errors.push('insurance_other_invalid');
    }
  } else if (data.insurance_other != null && String(data.insurance_other).trim() !== '') {
    errors.push('insurance_other_must_be_empty_unless_insurance_other');
  }

  return errors;
}

export const deriveAgeGroup = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const ageYears = asInt((request.data as { age_years?: unknown })?.age_years, 13, 100);
  if (ageYears == null) {
    throw new functions.https.HttpsError('invalid-argument', 'age_years is required (13–100)');
  }
  return { age_group: deriveAgeGroupCode(ageYears) };
});

export const validateResearchBaseline = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const data = (request.data ?? {}) as Record<string, unknown>;
  const errors = validateResearchBaselinePayload(data);
  return { ok: errors.length === 0, errors };
});

export const createResearchParticipant = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const data = (request.data ?? {}) as Record<string, unknown>;

  if (containsPiiPayload(data)) {
    throw new functions.https.HttpsError('invalid-argument', 'Disallowed fields in payload');
  }

  const recruitment_source = coerceRecruitmentSource(data.recruitment_source);
  if (recruitment_source == null) {
    throw new functions.https.HttpsError('invalid-argument', 'recruitment_source is required (1–7 or known string)');
  }

  const recruitment_pathway = asInt(data.recruitment_pathway, 1, 2);
  if (recruitment_pathway == null) {
    throw new functions.https.HttpsError('invalid-argument', 'recruitment_pathway must be 1 or 2');
  }

  let recruitment_source_other: string | null = null;
  if (recruitment_source === 6) {
    const o = data.recruitment_source_other;
    if (typeof o !== 'string' || !o.trim()) {
      throw new functions.https.HttpsError('invalid-argument', 'recruitment_source_other required when source is other (6)');
    }
    if (EMAIL_LIKE.test(o)) {
      throw new functions.https.HttpsError('invalid-argument', 'recruitment_source_other invalid');
    }
    recruitment_source_other = o.trim().slice(0, 500);
  } else if (data.recruitment_source_other != null && String(data.recruitment_source_other).trim() !== '') {
    throw new functions.https.HttpsError('invalid-argument', 'recruitment_source_other must be empty unless source is 6');
  }

  const userRef = db.collection('users').doc(uid);
  const userSnap = await userRef.get();
  const existing = userSnap.get('studyId') as string | undefined;

  const recordedAt = admin.firestore.FieldValue.serverTimestamp();
  const research_participant = 1;

  if (existing && typeof existing === 'string' && existing.length > 0) {
    const participantRef = db.collection('research_participants').doc(existing);
    await participantRef.set(
      {
        study_id: existing,
        research_participant,
        recruitment_source,
        recruitment_source_other,
        recruitment_pathway,
        recorded_at: recordedAt,
      },
      { merge: true },
    );
    return { studyId: existing, created: false };
  }

  const studyId = newStudyId();
  const batch = db.batch();
  batch.set(
    userRef,
    {
      studyId,
      isResearchParticipant: true,
      updatedAt: recordedAt,
    },
    { merge: true },
  );
  batch.set(
    db.collection('research_participants').doc(studyId),
    {
      study_id: studyId,
      research_participant,
      recruitment_source,
      recruitment_source_other,
      recruitment_pathway,
      recorded_at: recordedAt,
    },
    { merge: false },
  );
  await batch.commit();
  return { studyId, created: true };
});

export const submitBaselineResearchData = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const data = (request.data ?? {}) as Record<string, unknown>;

  if (containsPiiPayload(data)) {
    throw new functions.https.HttpsError('invalid-argument', 'Disallowed fields in payload');
  }

  const userRef = db.collection('users').doc(uid);
  const userSnap = await userRef.get();
  const studyId = userSnap.get('studyId') as string | undefined;
  if (!studyId || typeof studyId !== 'string') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'No study_id; complete createResearchParticipant first',
    );
  }

  const errors = validateResearchBaselinePayload(data);
  if (errors.length) {
    throw new functions.https.HttpsError('invalid-argument', errors.join('; '));
  }

  const pp = asInt(data.pp_status, 1, 2)!;
  const ageYears = asInt(data.age_years, 13, 100)!;
  const pathway = asInt(data.recruitment_pathway, 1, 2)!;
  const insuranceType = asInt(data.insurance_type, 1, 6)!;
  const nav = asInt(data.support_person_nav, 1, 6)!;
  const advocacy = asInt(data.baseline_advocacy_conf, LIKERT_MIN, LIKERT_MAX)!;

  const gest_week =
    pp === CODE_PP_STATUS.pregnant ? asInt(data.gest_week, 4, 42)! : null;
  const postpartum_month =
    pp === CODE_PP_STATUS.postpartum ? asInt(data.postpartum_month, 0, 48)! : null;

  const insurance_other =
    insuranceType === INSURANCE_TYPE_CODES.other
      ? String(data.insurance_other).trim().slice(0, 500)
      : null;

  const age_group = deriveAgeGroupCode(ageYears);
  const recordedAt = admin.firestore.FieldValue.serverTimestamp();

  const baseline = {
    study_id: studyId,
    recruitment_pathway: pathway,
    age_years: ageYears,
    age_group,
    pp_status: pp,
    gest_week,
    postpartum_month,
    insurance_type: insuranceType,
    insurance_other,
    support_person_nav: nav,
    baseline_advocacy_conf: advocacy,
    baseline_ts: recordedAt,
    recorded_at: recordedAt,
  };

  await db.collection('research_baseline').doc(studyId).set(baseline, { merge: true });

  await db.collection('audit_logs').add({
    action: 'research_baseline_submitted',
    study_id: studyId,
    performedBy: uid,
    timestamp: recordedAt,
  });

  return { ok: true, studyId };
});
