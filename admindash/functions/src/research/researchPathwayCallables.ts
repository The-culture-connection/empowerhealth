/**
 * Callable APIs for listing and managing recruitment pathways.
 */
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  countParticipantsWithPathway,
  getRecruitmentPathways,
  normalizePathwayList,
  requireResearchAdmin,
  validateNewPathwayInput,
  RESEARCH_CONFIG_PATHWAYS_DOC,
} from './researchPathways';

const db = admin.firestore();

export const listRecruitmentPathways = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const pathways = await getRecruitmentPathways();
  return { pathways };
});

export const addRecruitmentPathway = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  try {
    await requireResearchAdmin(uid);
  } catch {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can manage recruitment pathways');
  }

  const data = (request.data ?? {}) as Record<string, unknown>;
  const existing = await getRecruitmentPathways();
  const err = validateNewPathwayInput(data.code, data.label, existing);
  if (err) {
    throw new functions.https.HttpsError('invalid-argument', err);
  }

  const code = typeof data.code === 'number' ? Math.floor(data.code) : parseInt(String(data.code), 10);
  const label = String(data.label).trim();
  const pathways = [...existing, { code, label }].sort((a, b) => a.code - b.code);

  await db.doc(RESEARCH_CONFIG_PATHWAYS_DOC).set(
    {
      pathways,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: uid,
    },
    { merge: true },
  );

  await db.collection('audit_logs').add({
    action: 'research_pathway_added',
    code,
    label,
    performedBy: uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true, pathways };
});

export const deleteRecruitmentPathway = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  try {
    await requireResearchAdmin(uid);
  } catch {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can manage recruitment pathways');
  }

  const codeRaw = (request.data as { code?: unknown })?.code;
  const code = typeof codeRaw === 'number' ? Math.floor(codeRaw) : parseInt(String(codeRaw ?? ''), 10);
  if (!Number.isFinite(code)) {
    throw new functions.https.HttpsError('invalid-argument', 'code is required');
  }

  const existing = await getRecruitmentPathways();
  if (!existing.some((p) => p.code === code)) {
    throw new functions.https.HttpsError('not-found', 'pathway_not_found');
  }
  if (existing.length <= 1) {
    throw new functions.https.HttpsError('failed-precondition', 'at_least_one_pathway_required');
  }

  const inUse = await countParticipantsWithPathway(code);
  if (inUse > 0) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'pathway_in_use_by_participants',
    );
  }

  const pathways = existing.filter((p) => p.code !== code);
  await db.doc(RESEARCH_CONFIG_PATHWAYS_DOC).set(
    {
      pathways,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: uid,
    },
    { merge: true },
  );

  await db.collection('audit_logs').add({
    action: 'research_pathway_deleted',
    code,
    performedBy: uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true, pathways };
});

/** Admin-only: replace full pathway list (used after bulk edits). */
export async function saveRecruitmentPathways(pathways: unknown, uid: string): Promise<void> {
  const normalized = normalizePathwayList(pathways);
  if (!normalized.length) {
    throw new Error('pathways_empty');
  }
  await db.doc(RESEARCH_CONFIG_PATHWAYS_DOC).set(
    {
      pathways: normalized,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: uid,
    },
    { merge: true },
  );
}
