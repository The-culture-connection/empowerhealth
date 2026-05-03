/**
 * Phase 4 — Navigation outcomes: one `research_navigation_outcomes` row per completed
 * care access flow, linked to `research_needs_checklists` via `needs_event_id`.
 */
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const NEEDS_COLL = 'research_needs_checklists';
const OUT_COLL = 'research_navigation_outcomes';

const FLAG_OUTCOME: { flag: string; outcome: string }[] = [
  { flag: 'need_prenatal_postpartum', outcome: 'need_prenatal_postpartum_outcome' },
  { flag: 'need_delivery_prep', outcome: 'need_delivery_prep_outcome' },
  { flag: 'need_med_followup', outcome: 'need_med_followup_outcome' },
  { flag: 'need_mental_health', outcome: 'need_mental_health_outcome' },
  { flag: 'need_lactation', outcome: 'need_lactation_outcome' },
  { flag: 'need_infant_care', outcome: 'need_infant_care_outcome' },
  { flag: 'need_benefits', outcome: 'need_benefits_outcome' },
  { flag: 'need_transport', outcome: 'need_transport_outcome' },
  { flag: 'need_other', outcome: 'need_other_outcome' },
];

function asNonEmptyStudyId(v: unknown): string | undefined {
  if (typeof v !== 'string') return undefined;
  const t = v.trim();
  if (t.length < 2 || t.length > 128) return undefined;
  return t;
}

function asEventId(v: unknown): string | undefined {
  if (typeof v !== 'string') return undefined;
  const t = v.trim();
  if (!t.length || t.length > 128) return undefined;
  return t;
}

/** Outcome code: 0 = not applicable (need not selected on linked checklist); 1–6 = access response codes. */
function asOutcomeCode(v: unknown): number | undefined {
  if (v === 0 || v === '0') return 0;
  if (typeof v === 'number' && Number.isFinite(v)) {
    const f = Math.floor(v);
    if (f >= 0 && f <= 6) return f;
  }
  if (typeof v === 'string') {
    const t = v.trim();
    const n = parseInt(t, 10);
    if (!Number.isNaN(n) && n >= 0 && n <= 6) return n;
  }
  return undefined;
}

export type NavigationOutcomePayload = {
  study_id: string;
  needs_event_id: string;
  need_prenatal_postpartum_outcome: number;
  need_delivery_prep_outcome: number;
  need_med_followup_outcome: number;
  need_mental_health_outcome: number;
  need_lactation_outcome: number;
  need_infant_care_outcome: number;
  need_benefits_outcome: number;
  need_transport_outcome: number;
  need_other_outcome: number;
};

export type ValidateNavigationOutcomeResult =
  | { ok: true; payload: NavigationOutcomePayload; needsData: admin.firestore.DocumentData }
  | { ok: false; errors: string[] };

export function validateNavigationOutcomeAgainstNeeds(
  data: unknown,
  needsData: admin.firestore.DocumentData,
): ValidateNavigationOutcomeResult {
  const errors: string[] = [];
  if (data == null || typeof data !== 'object') {
    return { ok: false, errors: ['Expected an object payload'] };
  }
  const o = data as Record<string, unknown>;

  const studyId = asNonEmptyStudyId(o.study_id);
  if (!studyId) errors.push('study_id is required');

  const needsEventId = asEventId(o.needs_event_id);
  if (!needsEventId) errors.push('needs_event_id is required');

  if (studyId && needsData.study_id !== studyId) {
    errors.push('needs checklist study_id does not match payload study_id');
  }

  const outNums: Record<string, number> = {};

  for (const { flag, outcome } of FLAG_OUTCOME) {
    const flagVal = asOutcomeCode(needsData[flag]);
    const outVal = asOutcomeCode(o[outcome]);
    if (flagVal !== 0 && flagVal !== 1) {
      errors.push(`Linked needs checklist has invalid ${flag}`);
      continue;
    }
    if (outVal === undefined) {
      errors.push(`${outcome} must be an integer 0–6`);
      continue;
    }
    if (flagVal === 1 && (outVal < 1 || outVal > 6)) {
      errors.push(`${outcome} must be 1–6 when the need was selected on the checklist`);
      continue;
    }
    if (flagVal === 0 && outVal !== 0) {
      errors.push(`${outcome} must be 0 when the need was not selected on the checklist`);
      continue;
    }
    outNums[outcome] = outVal;
  }

  if (errors.length || !studyId || !needsEventId) return { ok: false, errors };

  const payload: NavigationOutcomePayload = {
    study_id: studyId,
    needs_event_id: needsEventId,
    need_prenatal_postpartum_outcome: outNums.need_prenatal_postpartum_outcome!,
    need_delivery_prep_outcome: outNums.need_delivery_prep_outcome!,
    need_med_followup_outcome: outNums.need_med_followup_outcome!,
    need_mental_health_outcome: outNums.need_mental_health_outcome!,
    need_lactation_outcome: outNums.need_lactation_outcome!,
    need_infant_care_outcome: outNums.need_infant_care_outcome!,
    need_benefits_outcome: outNums.need_benefits_outcome!,
    need_transport_outcome: outNums.need_transport_outcome!,
    need_other_outcome: outNums.need_other_outcome!,
  };

  return { ok: true, payload, needsData };
}

async function assertParticipantStudy(uid: string, studyId: string): Promise<void> {
  const userSnap = await db.collection('users').doc(uid).get();
  const user = userSnap.data();
  const profileStudy = user?.studyId as string | undefined;
  const isParticipant = user?.isResearchParticipant === true;
  if (!isParticipant || !profileStudy) {
    throw new functions.https.HttpsError('failed-precondition', 'User is not an active research participant');
  }
  if (profileStudy !== studyId) {
    throw new functions.https.HttpsError('permission-denied', 'study_id does not match enrolled research profile');
  }
}

/**
 * Writes `navigation_outcome_event_id` on the needs checklist (admin SDK).
 * Verifies both documents exist, share `study_id`, and the outcome references this needs row.
 */
export async function performLinkOutcomeToNeedsEvent(
  uid: string,
  studyId: string,
  needsEventId: string,
  outcomeEventId: string,
): Promise<void> {
  await assertParticipantStudy(uid, studyId);

  const needsRef = db.collection(NEEDS_COLL).doc(needsEventId);
  const outRef = db.collection(OUT_COLL).doc(outcomeEventId);
  const [needsSnap, outSnap] = await Promise.all([needsRef.get(), outRef.get()]);
  if (!needsSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'needs_event_id not found');
  }
  if (!outSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'outcome_event_id not found');
  }
  const nd = needsSnap.data()!;
  const od = outSnap.data()!;
  if (nd.study_id !== studyId || od.study_id !== studyId) {
    throw new functions.https.HttpsError('permission-denied', 'study_id mismatch on linked documents');
  }
  if (od.needs_event_id !== needsEventId) {
    throw new functions.https.HttpsError('invalid-argument', 'Outcome document does not reference this needs_event_id');
  }
  if (nd.navigation_outcome_event_id) {
    if (nd.navigation_outcome_event_id === outcomeEventId) return;
    throw new functions.https.HttpsError(
      'already-exists',
      'This needs checklist is already linked to a different navigation outcome',
    );
  }
  await needsRef.update({ navigation_outcome_event_id: outcomeEventId });
}

export const linkOutcomeToNeedsEvent = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const studyId = asNonEmptyStudyId(request.data?.study_id);
  const needsEventId = asEventId(request.data?.needs_event_id);
  const outcomeEventId = asEventId(request.data?.outcome_event_id);
  if (!studyId || !needsEventId || !outcomeEventId) {
    throw new functions.https.HttpsError('invalid-argument', 'study_id, needs_event_id, and outcome_event_id are required');
  }
  await performLinkOutcomeToNeedsEvent(uid, studyId, needsEventId, outcomeEventId);
  return { ok: true };
});

export const validateNavigationOutcome = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const needsEventId = asEventId((request.data as Record<string, unknown> | undefined)?.needs_event_id);
  if (!needsEventId) {
    return { valid: false, errors: ['needs_event_id is required'] };
  }
  const needsSnap = await db.collection(NEEDS_COLL).doc(needsEventId).get();
  if (!needsSnap.exists) {
    return { valid: false, errors: ['needs_event_id not found'] };
  }
  const res = validateNavigationOutcomeAgainstNeeds(request.data ?? {}, needsSnap.data()!);
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

export const submitNavigationOutcome = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const needsEventId = asEventId((request.data as Record<string, unknown> | undefined)?.needs_event_id);
  if (!needsEventId) {
    throw new functions.https.HttpsError('invalid-argument', 'needs_event_id is required');
  }
  const needsSnap = await db.collection(NEEDS_COLL).doc(needsEventId).get();
  if (!needsSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'needs_event_id not found');
  }
  const needsData = needsSnap.data()!;
  if (needsData.navigation_outcome_event_id) {
    throw new functions.https.HttpsError('already-exists', 'This needs checklist already has a linked outcome');
  }

  const validated = validateNavigationOutcomeAgainstNeeds(request.data ?? {}, needsData);
  if (!validated.ok) {
    throw new functions.https.HttpsError('invalid-argument', validated.errors.join('; '));
  }

  await assertParticipantStudy(uid, validated.payload.study_id);

  const recordedAt = admin.firestore.FieldValue.serverTimestamp();
  const outcomeTs = recordedAt;

  const docBody: Record<string, unknown> = {
    study_id: validated.payload.study_id,
    needs_event_id: validated.payload.needs_event_id,
    need_prenatal_postpartum_outcome: validated.payload.need_prenatal_postpartum_outcome,
    need_delivery_prep_outcome: validated.payload.need_delivery_prep_outcome,
    need_med_followup_outcome: validated.payload.need_med_followup_outcome,
    need_mental_health_outcome: validated.payload.need_mental_health_outcome,
    need_lactation_outcome: validated.payload.need_lactation_outcome,
    need_infant_care_outcome: validated.payload.need_infant_care_outcome,
    need_benefits_outcome: validated.payload.need_benefits_outcome,
    need_transport_outcome: validated.payload.need_transport_outcome,
    need_other_outcome: validated.payload.need_other_outcome,
    outcome_ts: outcomeTs,
    recorded_at: recordedAt,
  };

  const ref = await db.collection(OUT_COLL).add(docBody);
  try {
    await performLinkOutcomeToNeedsEvent(uid, validated.payload.study_id, needsEventId, ref.id);
  } catch (e) {
    await ref.delete().catch(() => undefined);
    if (e instanceof functions.https.HttpsError) throw e;
    throw new functions.https.HttpsError('internal', e instanceof Error ? e.message : 'Link failed');
  }
  return { ok: true, event_id: ref.id };
});
