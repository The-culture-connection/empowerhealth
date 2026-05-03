/**
 * Phase 2 — Micro-measures: validated writes to `research_micro_measures` (admin SDK only).
 */
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const COLL = 'research_micro_measures';

const LIKERT_MIN = 1;
const LIKERT_MAX = 5;

/** Allowed `content_type` values (extend as new surfaces ship). */
export const MICRO_MEASURE_CONTENT_TYPES = new Set([
  'learning_module',
  'visit_summary_avs',
  'visit_summary_notes',
  'micro_measure',
  'user_feedback',
]);

function asLikert(n: unknown): number | undefined {
  const x = typeof n === 'number' ? n : typeof n === 'string' ? parseInt(String(n), 10) : NaN;
  if (!Number.isFinite(x)) return undefined;
  const f = Math.floor(x);
  if (f < LIKERT_MIN || f > LIKERT_MAX) return undefined;
  return f;
}

function asNonEmptyString(v: unknown, maxLen: number): string | undefined {
  if (typeof v !== 'string') return undefined;
  const t = v.trim();
  if (!t.length || t.length > maxLen) return undefined;
  return t;
}

/** Parse optional client-reported instant (ISO-8601). Returns undefined if absent; throws message if invalid. */
export function parseOptionalClientMicroTs(raw: unknown): admin.firestore.Timestamp | undefined {
  if (raw == null || raw === '') return undefined;
  if (typeof raw !== 'string') {
    throw new Error('micro_ts_client must be an ISO-8601 string when provided');
  }
  const d = new Date(raw.trim());
  if (Number.isNaN(d.getTime())) {
    throw new Error('micro_ts_client must be a valid ISO-8601 datetime');
  }
  const now = Date.now();
  const skewMs = 24 * 60 * 60 * 1000;
  if (d.getTime() > now + skewMs || d.getTime() < now - 365 * 24 * 60 * 60 * 1000) {
    throw new Error('micro_ts_client is outside the allowed time window');
  }
  return admin.firestore.Timestamp.fromDate(d);
}

export type MicroMeasurePayload = {
  study_id: string;
  micro_understand: number;
  micro_next_step: number;
  micro_confidence: number;
  content_id: string;
  content_type: string;
  micro_ts_client?: admin.firestore.Timestamp;
};

export type ValidateMicroMeasureResult =
  | { ok: true; payload: MicroMeasurePayload }
  | { ok: false; errors: string[] };

/**
 * Pure validation used by submit + `validateMicroMeasure` callable.
 * Expects snake_case keys aligned with export columns.
 */
export function validateMicroMeasurePayload(data: unknown): ValidateMicroMeasureResult {
  const errors: string[] = [];
  if (data == null || typeof data !== 'object') {
    return { ok: false, errors: ['Expected an object payload'] };
  }
  const o = data as Record<string, unknown>;

  const studyId = asNonEmptyString(o.study_id, 64);
  if (!studyId) errors.push('study_id is required (non-empty string, max 64 chars)');

  const u = asLikert(o.micro_understand);
  const n = asLikert(o.micro_next_step);
  const c = asLikert(o.micro_confidence);
  if (u == null) errors.push(`micro_understand must be an integer ${LIKERT_MIN}–${LIKERT_MAX}`);
  if (n == null) errors.push(`micro_next_step must be an integer ${LIKERT_MIN}–${LIKERT_MAX}`);
  if (c == null) errors.push(`micro_confidence must be an integer ${LIKERT_MIN}–${LIKERT_MAX}`);

  const contentId = asNonEmptyString(o.content_id, 512);
  if (!contentId) errors.push('content_id is required (non-empty string, max 512 chars)');

  const contentTypeRaw = asNonEmptyString(o.content_type, 64);
  if (!contentTypeRaw) {
    errors.push('content_type is required');
  } else if (!MICRO_MEASURE_CONTENT_TYPES.has(contentTypeRaw)) {
    errors.push(`content_type must be one of: ${[...MICRO_MEASURE_CONTENT_TYPES].join(', ')}`);
  }

  let micro_ts_client: admin.firestore.Timestamp | undefined;
  try {
    micro_ts_client = parseOptionalClientMicroTs(o.micro_ts_client);
  } catch (e) {
    errors.push(e instanceof Error ? e.message : 'Invalid micro_ts_client');
  }

  if (errors.length) return { ok: false, errors };

  return {
    ok: true,
    payload: {
      study_id: studyId!,
      micro_understand: u!,
      micro_next_step: n!,
      micro_confidence: c!,
      content_id: contentId!,
      content_type: contentTypeRaw!,
      micro_ts_client,
    },
  };
}

export const validateMicroMeasure = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const res = validateMicroMeasurePayload(request.data ?? {});
  if (!res.ok) {
    return { valid: false, errors: res.errors };
  }
  const userSnap = await db.collection('users').doc(request.auth.uid).get();
  const profileStudy = userSnap.data()?.studyId as string | undefined;
  if (!profileStudy || profileStudy !== res.payload.study_id) {
    return { valid: false, errors: ['study_id does not match enrolled research profile'] };
  }
  return { valid: true, normalized: { ...res.payload, micro_ts_client: res.payload.micro_ts_client?.toDate().toISOString() } };
});

export const submitMicroMeasure = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const validated = validateMicroMeasurePayload(request.data ?? {});
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
  const microTs = recordedAt;
  const docBody: Record<string, unknown> = {
    study_id: validated.payload.study_id,
    micro_understand: validated.payload.micro_understand,
    micro_next_step: validated.payload.micro_next_step,
    micro_confidence: validated.payload.micro_confidence,
    content_id: validated.payload.content_id,
    content_type: validated.payload.content_type,
    micro_ts: microTs,
    recorded_at: recordedAt,
  };
  if (validated.payload.micro_ts_client) {
    docBody.micro_ts_client = validated.payload.micro_ts_client;
  }

  const ref = await db.collection(COLL).add(docBody);
  return { ok: true, event_id: ref.id };
});
