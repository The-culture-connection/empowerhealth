/**
 * Phase 7 — Rebuild `research_summary_by_day` (and optionally `research_summary_global`) from raw research rows.
 */
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  COLL_BY_DAY,
  COLL_GLOBAL,
  iterateDayKeys,
  navigationOutcomeSlotCounts,
  NEED_KEYS,
  RESEARCH_SUMMARY_LAYER_VERSION,
} from './researchSummaryCore';
import { canExportResearch } from './researchExport';

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const SCAN_CAP_PER_DAY = 8000;

function parseDateRange(raw: unknown): { start: Date; end: Date } | undefined {
  if (!raw || typeof raw !== 'object') return undefined;
  const o = raw as Record<string, unknown>;
  const start = o.start != null ? new Date(String(o.start)) : undefined;
  const end = o.end != null ? new Date(String(o.end)) : undefined;
  if (!start || Number.isNaN(start.getTime()) || !end || Number.isNaN(end.getTime())) return undefined;
  return { start, end };
}

function utcBoundsForDayKey(dayKey: string): { start: admin.firestore.Timestamp; end: admin.firestore.Timestamp } {
  const parts = dayKey.split('_').map((x) => parseInt(x, 10));
  const y = parts[0];
  const mo = parts[1];
  const da = parts[2];
  const s = new Date(Date.UTC(y, mo - 1, da, 0, 0, 0, 0));
  const e = new Date(Date.UTC(y, mo - 1, da, 23, 59, 59, 999));
  return {
    start: admin.firestore.Timestamp.fromDate(s),
    end: admin.firestore.Timestamp.fromDate(e),
  };
}

async function buildDaySummaryDoc(dayKey: string): Promise<Record<string, unknown>> {
  const { start, end } = utcBoundsForDayKey(dayKey);
  let micro_measure_count = 0;
  let micro_understand_sum = 0;
  let micro_next_step_sum = 0;
  let micro_confidence_sum = 0;
  let needs_checklist_count = 0;
  const needs_frequency: Record<string, number> = {};
  let navigation_outcome_count = 0;
  let navigation_success_numerator = 0;
  let navigation_success_denominator = 0;
  let milestone_prompt_count = 0;
  let app_activity_count = 0;
  let module_completed_count = 0;
  let provider_review_count = 0;
  let avs_upload_count = 0;
  let participant_count = 0;

  const mSnap = await db
    .collection('research_micro_measures')
    .where('recorded_at', '>=', start)
    .where('recorded_at', '<=', end)
    .limit(SCAN_CAP_PER_DAY)
    .get();
  mSnap.forEach((d) => {
    const x = d.data();
    const u = Number(x.micro_understand);
    const n = Number(x.micro_next_step);
    const c = Number(x.micro_confidence);
    if (!Number.isFinite(u) || !Number.isFinite(n) || !Number.isFinite(c)) return;
    micro_measure_count += 1;
    micro_understand_sum += u;
    micro_next_step_sum += n;
    micro_confidence_sum += c;
  });

  const nSnap = await db
    .collection('research_needs_checklists')
    .where('recorded_at', '>=', start)
    .where('recorded_at', '<=', end)
    .limit(SCAN_CAP_PER_DAY)
    .get();
  nSnap.forEach((d) => {
    needs_checklist_count += 1;
    const x = d.data();
    for (const k of NEED_KEYS) {
      if (x[k] === 1) {
        needs_frequency[k] = (needs_frequency[k] || 0) + 1;
      }
    }
  });

  const oSnap = await db
    .collection('research_navigation_outcomes')
    .where('recorded_at', '>=', start)
    .where('recorded_at', '<=', end)
    .limit(SCAN_CAP_PER_DAY)
    .get();
  oSnap.forEach((d) => {
    navigation_outcome_count += 1;
    const slots = navigationOutcomeSlotCounts(d.data() as Record<string, unknown>);
    navigation_success_numerator += slots.numerator;
    navigation_success_denominator += slots.denominator;
  });

  const msSnap = await db
    .collection('research_milestone_prompts')
    .where('recorded_at', '>=', start)
    .where('recorded_at', '<=', end)
    .limit(SCAN_CAP_PER_DAY)
    .get();
  milestone_prompt_count = msSnap.size;

  const aSnap = await db
    .collection('research_app_activity')
    .where('recorded_at', '>=', start)
    .where('recorded_at', '<=', end)
    .limit(SCAN_CAP_PER_DAY)
    .get();
  aSnap.forEach((d) => {
    const x = d.data();
    app_activity_count += 1;
    const t = String(x.activity_type || '');
    if (t === 'module_completed') module_completed_count += 1;
    else if (t === 'provider_review') provider_review_count += 1;
    else if (t === 'avs_upload') avs_upload_count += 1;
  });

  const pSnap = await db
    .collection('research_participants')
    .where('recorded_at', '>=', start)
    .where('recorded_at', '<=', end)
    .limit(SCAN_CAP_PER_DAY)
    .get();
  participant_count = pSnap.size;

  return {
    day_key: dayKey,
    summary_layer_version: RESEARCH_SUMMARY_LAYER_VERSION,
    updated_at: FieldValue.serverTimestamp(),
    recomputed_at: FieldValue.serverTimestamp(),
    micro_measure_count,
    micro_understand_sum,
    micro_next_step_sum,
    micro_confidence_sum,
    needs_checklist_count,
    needs_frequency,
    navigation_outcome_count,
    navigation_success_numerator,
    navigation_success_denominator,
    milestone_prompt_count,
    app_activity_count,
    module_completed_count,
    provider_review_count,
    avs_upload_count,
    participant_count,
  };
}

async function paginateEntireCollection(
  collection: string,
  onBatch: (snap: admin.firestore.QuerySnapshot) => void,
): Promise<number> {
  const page = 400;
  let last: admin.firestore.QueryDocumentSnapshot | undefined;
  let total = 0;
  for (;;) {
    let q = db.collection(collection).orderBy(admin.firestore.FieldPath.documentId()).limit(page);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    if (snap.empty) break;
    total += snap.size;
    onBatch(snap);
    last = snap.docs[snap.docs.length - 1];
    if (snap.size < page) break;
  }
  return total;
}

async function rebuildGlobalApproximate(warnings: string[]): Promise<void> {
  const [participantSnap, needsSnap, navSnap, mileSnap, actSnap] = await Promise.all([
    db.collection('research_participants').count().get(),
    db.collection('research_needs_checklists').count().get(),
    db.collection('research_navigation_outcomes').count().get(),
    db.collection('research_milestone_prompts').count().get(),
    db.collection('research_app_activity').count().get(),
  ]);

  let micro_understand_sum = 0;
  let micro_next_step_sum = 0;
  let micro_confidence_sum = 0;
  let micro_measure_count = 0;
  let navNum = 0;
  let navDen = 0;
  const needs_frequency: Record<string, number> = {};
  let module_completed_count = 0;
  let provider_review_count = 0;
  let avs_upload_count = 0;

  const microRows = await paginateEntireCollection('research_micro_measures', (snap) => {
    snap.forEach((d) => {
      const x = d.data();
      const u = Number(x.micro_understand);
      const n = Number(x.micro_next_step);
      const c = Number(x.micro_confidence);
      if (!Number.isFinite(u) || !Number.isFinite(n) || !Number.isFinite(c)) return;
      micro_measure_count += 1;
      micro_understand_sum += u;
      micro_next_step_sum += n;
      micro_confidence_sum += c;
    });
  });
  if (microRows > 250_000) {
    warnings.push('micro_measure_collection_very_large_global_recompute_may_be_slow');
  }

  await paginateEntireCollection('research_navigation_outcomes', (snap) => {
    snap.forEach((d) => {
      const slots = navigationOutcomeSlotCounts(d.data() as Record<string, unknown>);
      navNum += slots.numerator;
      navDen += slots.denominator;
    });
  });

  await paginateEntireCollection('research_needs_checklists', (snap) => {
    snap.forEach((d) => {
      const x = d.data();
      for (const k of NEED_KEYS) {
        if (x[k] === 1) {
          needs_frequency[k] = (needs_frequency[k] || 0) + 1;
        }
      }
    });
  });

  await paginateEntireCollection('research_app_activity', (snap) => {
    snap.forEach((d) => {
      const x = d.data();
      const t = String(x.activity_type || '');
      if (t === 'module_completed') module_completed_count += 1;
      else if (t === 'provider_review') provider_review_count += 1;
      else if (t === 'avs_upload') avs_upload_count += 1;
    });
  });

  const ref = db.collection(COLL_GLOBAL).doc('global');
  await ref.set(
    {
      summary_layer_version: RESEARCH_SUMMARY_LAYER_VERSION,
      updated_at: FieldValue.serverTimestamp(),
      recomputed_at: FieldValue.serverTimestamp(),
      participant_count: participantSnap.data().count,
      micro_measure_count,
      micro_understand_sum,
      micro_next_step_sum,
      micro_confidence_sum,
      needs_checklist_count: needsSnap.data().count,
      needs_frequency,
      navigation_outcome_count: navSnap.data().count,
      navigation_success_numerator: navNum,
      navigation_success_denominator: navDen,
      milestone_prompt_count: mileSnap.data().count,
      app_activity_count: actSnap.data().count,
      module_completed_count,
      provider_review_count,
      avs_upload_count,
    },
    { merge: false },
  );
}

export async function runResearchSummaryRecomputeForUid(
  uid: string,
  raw: unknown,
): Promise<{ daysProcessed: number; daysWithActivity: number; warnings: string[] }> {
  if (!(await canExportResearch(uid))) {
    throw new functions.https.HttpsError('permission-denied', 'Research summary recompute requires admin or research partner');
  }

  const payload = raw && typeof raw === 'object' ? (raw as Record<string, unknown>) : {};
  const dr = parseDateRange(payload.dateRange ?? raw);
  if (!dr) {
    throw new functions.https.HttpsError('invalid-argument', 'dateRange with start and end is required');
  }

  const warnings: string[] = [];
  const startTs = admin.firestore.Timestamp.fromDate(dr.start);
  const endTs = admin.firestore.Timestamp.fromDate(dr.end);
  const keys = iterateDayKeys(startTs, endTs);

  let daysWithActivity = 0;
  for (const dayKey of keys) {
    const doc = await buildDaySummaryDoc(dayKey);
    const hasAny =
      (doc.micro_measure_count as number) > 0 ||
      (doc.needs_checklist_count as number) > 0 ||
      (doc.navigation_outcome_count as number) > 0 ||
      (doc.milestone_prompt_count as number) > 0 ||
      (doc.app_activity_count as number) > 0 ||
      (doc.participant_count as number) > 0;
    await db.collection(COLL_BY_DAY).doc(dayKey).set(doc, { merge: false });
    if (hasAny) daysWithActivity += 1;
  }

  if (payload.rebuildGlobal !== false) {
    await rebuildGlobalApproximate(warnings);
  }

  return { daysProcessed: keys.length, daysWithActivity, warnings };
}

export const recomputeResearchSummaries = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
    if (!request.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    return runResearchSummaryRecomputeForUid(request.auth.uid, request.data);
  },
);
