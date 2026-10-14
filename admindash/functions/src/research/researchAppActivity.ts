/**
 * Phase 6 — Structured research app activity (`research_app_activity`): callable-only writes.
 */
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  APP_ACTIVITY_EXPORT_COLUMNS,
  AVS_UPLOAD_TYPE_SLUGS,
  MAX_HEALTH_MADE_SIMPLE_ACCESS_LEN,
  MAX_MODULE_ID_LEN,
  PROVIDER_REVIEW_ACTIVITY_CODES,
} from './researchFieldSpec';

const AVS_SLUG_SET = new Set<string>(AVS_UPLOAD_TYPE_SLUGS as readonly string[]);
const PROVIDER_ACTIVITY_SET = new Set<number>(PROVIDER_REVIEW_ACTIVITY_CODES as readonly number[]);

const db = admin.firestore();
const COLL = 'research_app_activity';

function asNonEmptyStudyId(v: unknown): string | undefined {
  if (typeof v !== 'string') return undefined;
  const t = v.trim();
  if (t.length < 2 || t.length > 128) return undefined;
  return t;
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

function asModuleId(v: unknown): string | undefined {
  if (typeof v !== 'string') return undefined;
  const t = v.trim();
  if (!t.length || t.length > MAX_MODULE_ID_LEN) return undefined;
  return t;
}

function asModuleCompletion(v: unknown): number | undefined {
  if (v === 0 || v === '0') return 0;
  if (v === 1 || v === '1') return 1;
  if (typeof v === 'number' && Number.isFinite(v)) {
    const f = Math.floor(v);
    if (f === 0 || f === 1) return f;
  }
  return undefined;
}

function asProviderReviewActivity(v: unknown): number | undefined {
  if (typeof v === 'number' && Number.isFinite(v)) {
    const f = Math.floor(v);
    if (PROVIDER_ACTIVITY_SET.has(f)) return f;
  }
  if (typeof v === 'string') {
    const n = parseInt(v.trim(), 10);
    if (!Number.isNaN(n) && PROVIDER_ACTIVITY_SET.has(n)) return n;
  }
  return undefined;
}

function asAvsUploadType(v: unknown): string | undefined {
  if (typeof v !== 'string') return undefined;
  const t = v.trim().toLowerCase();
  if (!t.length || t.length > 32) return undefined;
  if (AVS_SLUG_SET.has(t)) return t;
  return undefined;
}

function asHealthMadeSimpleAccess(v: unknown): string | undefined {
  if (typeof v !== 'string') return undefined;
  const t = v.trim().toLowerCase().replace(/[^a-z0-9:_\-]/g, '_').replace(/_+/g, '_');
  if (!t.length) return undefined;
  if (t.length > MAX_HEALTH_MADE_SIMPLE_ACCESS_LEN) return t.slice(0, MAX_HEALTH_MADE_SIMPLE_ACCESS_LEN);
  return t;
}

async function writeActivityRow(
  uid: string,
  studyId: string,
  row: Record<string, unknown>,
): Promise<{ event_id: string }> {
  await assertParticipantStudy(uid, studyId);
  const recordedAt = admin.firestore.FieldValue.serverTimestamp();
  const activityTs = recordedAt;
  const doc: Record<string, unknown> = {
    study_id: studyId,
    activity_ts: activityTs,
    recorded_at: recordedAt,
  };
  for (const k of APP_ACTIVITY_EXPORT_COLUMNS) {
    if (k === 'study_id' || k === 'activity_ts' || k === 'recorded_at') continue;
    if (row[k] !== undefined) doc[k] = row[k];
  }
  const ref = await db.collection(COLL).add(doc);
  return { event_id: ref.id };
}

export const recordModuleCompletion = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const o = (request.data ?? {}) as Record<string, unknown>;
  const studyId = asNonEmptyStudyId(o.study_id);
  const moduleId = asModuleId(o.module_id);
  const moduleCompletion = asModuleCompletion(o.module_completion ?? 1);
  if (!studyId) throw new functions.https.HttpsError('invalid-argument', 'study_id is required');
  if (!moduleId) throw new functions.https.HttpsError('invalid-argument', 'module_id is required');
  if (moduleCompletion === undefined) {
    throw new functions.https.HttpsError('invalid-argument', 'module_completion must be 0 or 1');
  }
  return writeActivityRow(uid, studyId, {
    activity_type: 'module_completed',
    module_id: moduleId,
    module_completion: moduleCompletion,
    provider_review_activity: null,
    avs_upload_type: null,
    health_made_simple_access: null,
  });
});

export const recordProviderReviewActivity = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const o = (request.data ?? {}) as Record<string, unknown>;
  const studyId = asNonEmptyStudyId(o.study_id);
  const code = asProviderReviewActivity(o.provider_review_activity);
  if (!studyId) throw new functions.https.HttpsError('invalid-argument', 'study_id is required');
  if (code === undefined) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `provider_review_activity must be one of: ${PROVIDER_REVIEW_ACTIVITY_CODES.join(', ')}`,
    );
  }
  const moduleId = o.module_id != null && o.module_id !== '' ? asModuleId(o.module_id) : null;
  if (o.module_id != null && o.module_id !== '' && !moduleId) {
    throw new functions.https.HttpsError('invalid-argument', 'module_id is invalid when provided');
  }
  return writeActivityRow(uid, studyId, {
    activity_type: 'provider_review',
    module_id: moduleId ?? null,
    module_completion: null,
    provider_review_activity: code,
    avs_upload_type: null,
    health_made_simple_access: null,
  });
});

export const recordAvsUploadActivity = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const o = (request.data ?? {}) as Record<string, unknown>;
  const studyId = asNonEmptyStudyId(o.study_id);
  const avs = asAvsUploadType(o.avs_upload_type ?? 'unknown');
  if (!studyId) throw new functions.https.HttpsError('invalid-argument', 'study_id is required');
  if (!avs) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `avs_upload_type must be one of: ${AVS_UPLOAD_TYPE_SLUGS.join(', ')}`,
    );
  }
  return writeActivityRow(uid, studyId, {
    activity_type: 'avs_upload',
    module_id: null,
    module_completion: null,
    provider_review_activity: null,
    avs_upload_type: avs,
    health_made_simple_access: null,
  });
});

export const recordHealthMadeSimpleAccess = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const o = (request.data ?? {}) as Record<string, unknown>;
  const studyId = asNonEmptyStudyId(o.study_id);
  const access = asHealthMadeSimpleAccess(o.health_made_simple_access);
  if (!studyId) throw new functions.https.HttpsError('invalid-argument', 'study_id is required');
  if (!access) {
    throw new functions.https.HttpsError('invalid-argument', 'health_made_simple_access is required (slug)');
  }
  return writeActivityRow(uid, studyId, {
    activity_type: 'health_made_simple_access',
    module_id: null,
    module_completion: null,
    provider_review_activity: null,
    avs_upload_type: null,
    health_made_simple_access: access,
  });
});
