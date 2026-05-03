/**
 * Phase 7 — Research summary layer: shared refs + incremental deltas (one trigger fire per create).
 */
import * as admin from 'firebase-admin';

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

export const COLL_GLOBAL = 'research_summary_global';
export const COLL_BY_STUDY = 'research_summary_by_study';
export const COLL_BY_DAY = 'research_summary_by_day';
export const COLL_BY_PATHWAY = 'research_summary_by_pathway';

export const RESEARCH_SUMMARY_LAYER_VERSION = 1;

const NEED_KEYS = [
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

const OUTCOME_KEYS = [
  'need_prenatal_postpartum_outcome',
  'need_delivery_prep_outcome',
  'need_med_followup_outcome',
  'need_mental_health_outcome',
  'need_lactation_outcome',
  'need_infant_care_outcome',
  'need_benefits_outcome',
  'need_transport_outcome',
  'need_other_outcome',
] as const;

export function dayKeyFromTimestamp(ts: admin.firestore.Timestamp | undefined): string {
  const d = ts ? ts.toDate() : new Date();
  return formatUtcDayKey(d);
}

export function formatUtcDayKey(d: Date): string {
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${y}_${m}_${day}`;
}

/** Inclusive UTC day range keys between start and end (Firestore Timestamps). */
export function iterateDayKeys(start: admin.firestore.Timestamp, end: admin.firestore.Timestamp): string[] {
  const keys: string[] = [];
  let cur = new Date(start.toDate());
  cur.setUTCHours(0, 0, 0, 0);
  const endMs = end.toDate().getTime();
  while (cur.getTime() <= endMs) {
    keys.push(formatUtcDayKey(cur));
    cur.setUTCDate(cur.getUTCDate() + 1);
  }
  return keys;
}

export async function recruitmentPathwayForStudy(studyId: string): Promise<1 | 2 | null> {
  const pSnap = await db.collection('research_participants').doc(studyId).get();
  const p = Number(pSnap.data()?.recruitment_pathway);
  if (p === 1 || p === 2) return p as 1 | 2;
  const bSnap = await db.collection('research_baseline').doc(studyId).get();
  const b = Number(bSnap.data()?.recruitment_pathway);
  if (b === 1 || b === 2) return b as 1 | 2;
  return null;
}

/** Applicable = outcome codes 1–6; success = codes 4–6 (upper half of access scale). */
export function navigationOutcomeSlotCounts(data: Record<string, unknown>): { numerator: number; denominator: number } {
  let numerator = 0;
  let denominator = 0;
  for (const k of OUTCOME_KEYS) {
    const v = Number(data[k]);
    if (!Number.isFinite(v) || v < 1 || v > 6) continue;
    denominator += 1;
    if (v >= 4) numerator += 1;
  }
  return { numerator, denominator };
}

function microIncrements(u: number, n: number, c: number): Record<string, unknown> {
  return {
    micro_measure_count: FieldValue.increment(1),
    micro_understand_sum: FieldValue.increment(u),
    micro_next_step_sum: FieldValue.increment(n),
    micro_confidence_sum: FieldValue.increment(c),
  };
}

function needsIncrements(data: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {
    needs_checklist_count: FieldValue.increment(1),
  };
  for (const k of NEED_KEYS) {
    const v = data[k];
    const b = v === 1 || v === '1' ? 1 : 0;
    if (b === 1) {
      out[`needs_frequency.${k}`] = FieldValue.increment(1);
    }
  }
  return out;
}

function navigationIncrements(data: Record<string, unknown>): Record<string, unknown> {
  const { numerator, denominator } = navigationOutcomeSlotCounts(data);
  return {
    navigation_outcome_count: FieldValue.increment(1),
    navigation_success_numerator: FieldValue.increment(numerator),
    navigation_success_denominator: FieldValue.increment(denominator),
  };
}

function activityIncrements(data: Record<string, unknown>): Record<string, unknown> {
  const t = String(data.activity_type || '');
  const out: Record<string, unknown> = {
    app_activity_count: FieldValue.increment(1),
  };
  if (t === 'module_completed') {
    out.module_completed_count = FieldValue.increment(1);
  } else if (t === 'provider_review') {
    out.provider_review_count = FieldValue.increment(1);
  } else if (t === 'avs_upload') {
    out.avs_upload_count = FieldValue.increment(1);
  }
  return out;
}

function milestoneIncrements(): Record<string, unknown> {
  return {
    milestone_prompt_count: FieldValue.increment(1),
  };
}

function participantIncrements(): Record<string, unknown> {
  return {
    participant_count: FieldValue.increment(1),
  };
}

function mergeTouch(
  batch: admin.firestore.WriteBatch,
  ref: admin.firestore.DocumentReference,
  patch: Record<string, unknown>,
): void {
  batch.set(
    ref,
    {
      ...patch,
      updated_at: FieldValue.serverTimestamp(),
      summary_layer_version: RESEARCH_SUMMARY_LAYER_VERSION,
    },
    { merge: true },
  );
}

export type SummaryDeltaKind =
  | 'micro_measure'
  | 'needs_checklist'
  | 'navigation_outcome'
  | 'app_activity'
  | 'milestone_prompt'
  | 'participant';

/**
 * Applies the same increments to global, by-day, by-study, and by-pathway (when pathway known).
 * One Firestore create → one trigger → one batch (no double counting).
 */
export async function applyResearchSummaryDelta(params: {
  studyId: string;
  recordedAt: admin.firestore.Timestamp | undefined;
  pathway: 1 | 2 | null;
  kind: SummaryDeltaKind;
  /** Raw created document data (snake_case). */
  data: Record<string, unknown>;
}): Promise<void> {
  const { studyId, recordedAt, pathway, kind, data } = params;
  const dayKey = dayKeyFromTimestamp(recordedAt);

  let patch: Record<string, unknown> = {};
  if (kind === 'micro_measure') {
    const u = Number(data.micro_understand);
    const n = Number(data.micro_next_step);
    const c = Number(data.micro_confidence);
    if (!Number.isFinite(u) || !Number.isFinite(n) || !Number.isFinite(c)) {
      console.warn('[researchSummary] skip micro: invalid likert', studyId);
      return;
    }
    patch = microIncrements(u, n, c);
  } else if (kind === 'needs_checklist') {
    patch = needsIncrements(data);
  } else if (kind === 'navigation_outcome') {
    patch = navigationIncrements(data);
  } else if (kind === 'app_activity') {
    patch = activityIncrements(data);
  } else if (kind === 'milestone_prompt') {
    patch = milestoneIncrements();
  } else if (kind === 'participant') {
    patch = participantIncrements();
  }

  const batch = db.batch();
  const globalRef = db.collection(COLL_GLOBAL).doc('global');
  const dayRef = db.collection(COLL_BY_DAY).doc(dayKey);
  const studyRef = db.collection(COLL_BY_STUDY).doc(studyId);

  mergeTouch(batch, globalRef, patch);
  mergeTouch(batch, dayRef, patch);
  mergeTouch(batch, studyRef, patch);

  if (pathway === 1 || pathway === 2) {
    const pathwayRef = db.collection(COLL_BY_PATHWAY).doc(String(pathway));
    mergeTouch(batch, pathwayRef, patch);
  }

  await batch.commit();
}

export function averagesFromSummaryData(d: Record<string, unknown> | undefined): {
  average_micro_understand: number | null;
  average_micro_next_step: number | null;
  average_micro_confidence: number | null;
} {
  if (!d) {
    return { average_micro_understand: null, average_micro_next_step: null, average_micro_confidence: null };
  }
  const cnt = Number(d.micro_measure_count) || 0;
  if (cnt <= 0) {
    return { average_micro_understand: null, average_micro_next_step: null, average_micro_confidence: null };
  }
  const su = Number(d.micro_understand_sum) || 0;
  const sn = Number(d.micro_next_step_sum) || 0;
  const sc = Number(d.micro_confidence_sum) || 0;
  return {
    average_micro_understand: su / cnt,
    average_micro_next_step: sn / cnt,
    average_micro_confidence: sc / cnt,
  };
}

export function navigationSuccessRate(d: Record<string, unknown> | undefined): number | null {
  if (!d) return null;
  const den = Number(d.navigation_success_denominator) || 0;
  if (den <= 0) return null;
  const num = Number(d.navigation_success_numerator) || 0;
  return num / den;
}

export function moduleCompletionRate(d: Record<string, unknown> | undefined): number | null {
  if (!d) return null;
  const p = Number(d.participant_count) || 0;
  const m = Number(d.module_completed_count) || 0;
  if (p <= 0) return null;
  return m / p;
}

export function milestoneResponseRate(d: Record<string, unknown> | undefined): number | null {
  if (!d) return null;
  const p = Number(d.participant_count) || 0;
  const ms = Number(d.milestone_prompt_count) || 0;
  if (p <= 0) return null;
  return ms / p;
}

const SUMMABLE_COUNT_FIELDS = [
  'participant_count',
  'micro_measure_count',
  'micro_understand_sum',
  'micro_next_step_sum',
  'micro_confidence_sum',
  'needs_checklist_count',
  'navigation_outcome_count',
  'navigation_success_numerator',
  'navigation_success_denominator',
  'milestone_prompt_count',
  'app_activity_count',
  'module_completed_count',
  'provider_review_count',
  'avs_upload_count',
] as const;

function dayDocHasActivity(d: Record<string, unknown>): boolean {
  for (const f of SUMMABLE_COUNT_FIELDS) {
    if ((Number(d[f]) || 0) > 0) return true;
  }
  const nf = d.needs_frequency;
  if (nf && typeof nf === 'object') {
    for (const v of Object.values(nf as Record<string, unknown>)) {
      if ((Number(v) || 0) > 0) return true;
    }
  }
  return false;
}

/** Sums Phase 7 `research_summary_by_day` docs in an inclusive UTC range (dashboard fast path). */
export async function aggregateResearchSummaryFromDays(
  start: admin.firestore.Timestamp,
  end: admin.firestore.Timestamp,
): Promise<{ merged: Record<string, unknown>; daysWithData: number }> {
  const keys = iterateDayKeys(start, end);
  const merged: Record<string, unknown> = {};
  const needsFreq: Record<string, number> = {};
  let daysWithData = 0;

  for (const dk of keys) {
    const doc = await db.collection(COLL_BY_DAY).doc(dk).get();
    if (!doc.exists) continue;
    const d = doc.data() as Record<string, unknown>;
    if (dayDocHasActivity(d)) daysWithData += 1;

    for (const f of SUMMABLE_COUNT_FIELDS) {
      const add = Number(d[f]) || 0;
      if (!add) continue;
      merged[f] = (Number(merged[f]) || 0) + add;
    }

    const nf = d.needs_frequency;
    if (nf && typeof nf === 'object') {
      for (const [k, v] of Object.entries(nf as Record<string, unknown>)) {
        const add = Number(v) || 0;
        if (!add) continue;
        needsFreq[k] = (needsFreq[k] || 0) + add;
      }
    }
  }

  if (Object.keys(needsFreq).length) {
    merged.needs_frequency = needsFreq;
  }

  return { merged, daysWithData };
}

export { NEED_KEYS, OUTCOME_KEYS };
