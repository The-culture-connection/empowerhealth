/**
 * Phase 3 — Needs checklist: validated writes to `research_needs_checklists` (admin SDK only).
 */
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const COLL = 'research_needs_checklists';

const NEED_BINARY_KEYS = [
  'need_prenatal_postpartum',
  'need_delivery_prep',
  'need_med_followup',
  'need_mental_health',
  'need_lactation',
  'need_infant_care',
  'need_benefits',
  'need_transport',
  'need_other',
] as const;

const OTHER_TEXT_MAX = 2000;

function asBinary(v: unknown): 0 | 1 | undefined {
  if (v === 0 || v === '0') return 0;
  if (v === 1 || v === '1') return 1;
  if (typeof v === 'number' && Number.isFinite(v)) {
    const f = Math.floor(v);
    if (f === 0) return 0;
    if (f === 1) return 1;
  }
  if (typeof v === 'string') {
    const t = v.trim();
    if (t === '0') return 0;
    if (t === '1') return 1;
  }
  return undefined;
}

function asNonEmptyStudyId(v: unknown): string | undefined {
  if (typeof v !== 'string') return undefined;
  const t = v.trim();
  if (t.length < 2 || t.length > 64) return undefined;
  return t;
}

export type NeedsChecklistPayload = {
  study_id: string;
  need_prenatal_postpartum: 0 | 1;
  need_delivery_prep: 0 | 1;
  need_med_followup: 0 | 1;
  need_mental_health: 0 | 1;
  need_lactation: 0 | 1;
  need_infant_care: 0 | 1;
  need_benefits: 0 | 1;
  need_transport: 0 | 1;
  need_other: 0 | 1;
  need_other_text?: string;
};

export type ValidateNeedsChecklistResult =
  | { ok: true; payload: NeedsChecklistPayload }
  | { ok: false; errors: string[] };

/**
 * Validates payload: all nine need_* fields must be exactly 0 or 1.
 * If `need_other` is 1, `need_other_text` is required (trimmed, max OTHER_TEXT_MAX).
 * If `need_other` is 0, `need_other_text` must be absent or whitespace-only.
 */
export function validateNeedsChecklistPayload(data: unknown): ValidateNeedsChecklistResult {
  const errors: string[] = [];
  if (data == null || typeof data !== 'object') {
    return { ok: false, errors: ['Expected an object payload'] };
  }
  const o = data as Record<string, unknown>;

  const studyId = asNonEmptyStudyId(o.study_id);
  if (!studyId) errors.push('study_id is required (non-empty string, max 64 chars)');

  const bin: Partial<Record<(typeof NEED_BINARY_KEYS)[number], 0 | 1>> = {};
  for (const key of NEED_BINARY_KEYS) {
    const b = asBinary(o[key]);
    if (b === undefined) {
      errors.push(`${key} must be exactly 0 or 1`);
    } else {
      bin[key] = b;
    }
  }

  const rawOtherText = o.need_other_text;
  const needOther = bin.need_other;

  if (needOther === 1) {
    if (typeof rawOtherText !== 'string' || !rawOtherText.trim()) {
      errors.push('need_other_text is required when need_other is 1');
    } else if (rawOtherText.trim().length > OTHER_TEXT_MAX) {
      errors.push(`need_other_text must be at most ${OTHER_TEXT_MAX} characters`);
    }
  } else if (needOther === 0) {
    if (typeof rawOtherText === 'string' && rawOtherText.trim().length > 0) {
      errors.push('need_other_text must be empty or omitted when need_other is 0');
    }
  }

  if (errors.length || studyId == null) {
    return { ok: false, errors };
  }

  const payload: NeedsChecklistPayload = {
    study_id: studyId,
    need_prenatal_postpartum: bin.need_prenatal_postpartum!,
    need_delivery_prep: bin.need_delivery_prep!,
    need_med_followup: bin.need_med_followup!,
    need_mental_health: bin.need_mental_health!,
    need_lactation: bin.need_lactation!,
    need_infant_care: bin.need_infant_care!,
    need_benefits: bin.need_benefits!,
    need_transport: bin.need_transport!,
    need_other: bin.need_other!,
  };
  if (payload.need_other === 1 && typeof rawOtherText === 'string') {
    payload.need_other_text = rawOtherText.trim();
  }

  return { ok: true, payload };
}

export const validateNeedsChecklist = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const res = validateNeedsChecklistPayload(request.data ?? {});
  if (!res.ok) {
    return { valid: false, errors: res.errors };
  }
  const userSnap = await db.collection('users').doc(request.auth.uid).get();
  const profileStudy = userSnap.data()?.studyId as string | undefined;
  if (!profileStudy || profileStudy !== res.payload.study_id) {
    return { valid: false, errors: ['study_id does not match enrolled research profile'] };
  }
  return { valid: true, normalized: res.payload };
});

export const submitNeedsChecklist = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const validated = validateNeedsChecklistPayload(request.data ?? {});
  if (!validated.ok) {
    throw new functions.https.HttpsError('invalid-argument', validated.errors.join('; '));
  }

  const userSnap = await db.collection('users').doc(uid).get();
  const user = userSnap.data();
  const profileStudy = user?.studyId as string | undefined;
  const isParticipant = user?.isResearchParticipant === true;
  if (!isParticipant || !profileStudy) {
    throw new functions.https.HttpsError('failed-precondition', 'User is not an active research participant');
  }
  if (profileStudy !== validated.payload.study_id) {
    throw new functions.https.HttpsError('permission-denied', 'study_id does not match enrolled research profile');
  }

  const recordedAt = admin.firestore.FieldValue.serverTimestamp();
  const needsTs = recordedAt;

  const docBody: Record<string, unknown> = {
    study_id: validated.payload.study_id,
    need_prenatal_postpartum: validated.payload.need_prenatal_postpartum,
    need_delivery_prep: validated.payload.need_delivery_prep,
    need_med_followup: validated.payload.need_med_followup,
    need_mental_health: validated.payload.need_mental_health,
    need_lactation: validated.payload.need_lactation,
    need_infant_care: validated.payload.need_infant_care,
    need_benefits: validated.payload.need_benefits,
    need_transport: validated.payload.need_transport,
    need_other: validated.payload.need_other,
    needs_ts: needsTs,
    recorded_at: recordedAt,
  };
  if (validated.payload.need_other_text != null) {
    docBody.need_other_text = validated.payload.need_other_text;
  }

  const ref = await db.collection(COLL).add(docBody);
  return { ok: true, event_id: ref.id };
});
