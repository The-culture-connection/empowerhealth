/**
 * Phase 5 — Milestone / longitudinal check-ins: validated writes to `research_milestone_prompts`.
 */
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { CODE_PP_STATUS, MILESTONE_TYPE_ALLOWED, MILESTONE_TYPE_CODES } from './researchFieldSpec';

const db = admin.firestore();
const COLL = 'research_milestone_prompts';
const BASELINE_COLL = 'research_baseline';

function asNonEmptyStudyId(v: unknown): string | undefined {
  if (typeof v !== 'string') return undefined;
  const t = v.trim();
  if (t.length < 2 || t.length > 128) return undefined;
  return t;
}

function asYesNo(v: unknown): number | undefined {
  if (v === 0 || v === '0') return 0;
  if (v === 1 || v === '1') return 1;
  if (typeof v === 'number' && Number.isFinite(v)) {
    const f = Math.floor(v);
    if (f === 0 || f === 1) return f;
  }
  if (typeof v === 'string') {
    const n = parseInt(v.trim(), 10);
    if (!Number.isNaN(n) && (n === 0 || n === 1)) return n;
  }
  return undefined;
}

function asMilestoneType(v: unknown): number | undefined {
  if (typeof v === 'number' && Number.isFinite(v)) {
    const f = Math.floor(v);
    if (MILESTONE_TYPE_ALLOWED.has(f)) return f;
  }
  if (typeof v === 'string') {
    const n = parseInt(v.trim(), 10);
    if (!Number.isNaN(n) && MILESTONE_TYPE_ALLOWED.has(n)) return n;
  }
  return undefined;
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

/** Derive milestone_type from baseline vitals (null = no scheduled window). */
export function resolveMilestoneTypeFromBaseline(
  baseline: FirebaseFirestore.DocumentData | undefined,
): number | null {
  if (!baseline) return null;
  const pp = baseline.pp_status;
  if (pp === CODE_PP_STATUS.pregnant) {
    const g = baseline.gest_week;
    if (typeof g === 'number' && Number.isFinite(g)) {
      if (g >= 34) return MILESTONE_TYPE_CODES.late_pregnancy_34_plus;
      if (g >= 28) return MILESTONE_TYPE_CODES.third_trimester_28_33;
    }
    return null;
  }
  if (pp === CODE_PP_STATUS.postpartum) {
    const m = baseline.postpartum_month;
    if (typeof m !== 'number' || !Number.isFinite(m)) return null;
    if (m <= 3) return MILESTONE_TYPE_CODES.postpartum_months_0_3;
    if (m <= 6) return MILESTONE_TYPE_CODES.postpartum_months_4_6;
    return MILESTONE_TYPE_CODES.postpartum_months_7_plus;
  }
  return null;
}

export type MilestoneCheckInPayload = {
  study_id: string;
  milestone_type: number;
  milestone_health_question: number;
  milestone_clear_next_step: number;
  milestone_app_helped_next_step: number;
};

export type ValidateMilestoneCheckInResult =
  | { ok: true; payload: MilestoneCheckInPayload }
  | { ok: false; errors: string[] };

export function validateMilestoneCheckInPayload(data: unknown): ValidateMilestoneCheckInResult {
  const errors: string[] = [];
  if (data == null || typeof data !== 'object') {
    return { ok: false, errors: ['Expected an object payload'] };
  }
  const o = data as Record<string, unknown>;

  const studyId = asNonEmptyStudyId(o.study_id);
  if (!studyId) errors.push('study_id is required');

  const mt = asMilestoneType(o.milestone_type);
  if (mt === undefined) errors.push(`milestone_type must be one of: ${[...MILESTONE_TYPE_ALLOWED].sort((a, b) => a - b).join(', ')}`);

  const h = asYesNo(o.milestone_health_question);
  const c = asYesNo(o.milestone_clear_next_step);
  const a = asYesNo(o.milestone_app_helped_next_step);
  if (h === undefined) errors.push('milestone_health_question must be 0 or 1');
  if (c === undefined) errors.push('milestone_clear_next_step must be 0 or 1');
  if (a === undefined) errors.push('milestone_app_helped_next_step must be 0 or 1');

  if (errors.length || !studyId || mt === undefined || h === undefined || c === undefined || a === undefined) {
    return { ok: false, errors };
  }

  return {
    ok: true,
    payload: {
      study_id: studyId,
      milestone_type: mt,
      milestone_health_question: h,
      milestone_clear_next_step: c,
      milestone_app_helped_next_step: a,
    },
  };
}

export type MilestoneJourneyStep = {
  milestone_type: number;
  title: string;
  subtitle: string;
  completed: boolean;
  is_current: boolean;
};

function buildJourneySteps(
  baseline: admin.firestore.DocumentData | undefined,
  completed: Set<number>,
  eligible: number | null,
): MilestoneJourneyStep[] {
  if (!baseline) return [];
  const pp = baseline.pp_status;
  const templates: { milestone_type: number; title: string; subtitle: string }[] = [];
  if (pp === CODE_PP_STATUS.pregnant) {
    templates.push(
      {
        milestone_type: MILESTONE_TYPE_CODES.third_trimester_28_33,
        title: 'Third trimester check-in',
        subtitle: 'Research milestone · gestational weeks 28–33',
      },
      {
        milestone_type: MILESTONE_TYPE_CODES.late_pregnancy_34_plus,
        title: 'Late pregnancy check-in',
        subtitle: 'Research milestone · gestational week 34 and after',
      },
    );
  } else if (pp === CODE_PP_STATUS.postpartum) {
    templates.push(
      {
        milestone_type: MILESTONE_TYPE_CODES.postpartum_months_0_3,
        title: 'Early postpartum',
        subtitle: 'Research milestone · months 0–3 after birth',
      },
      {
        milestone_type: MILESTONE_TYPE_CODES.postpartum_months_4_6,
        title: 'Mid postpartum',
        subtitle: 'Research milestone · months 4–6',
      },
      {
        milestone_type: MILESTONE_TYPE_CODES.postpartum_months_7_plus,
        title: 'Later postpartum',
        subtitle: 'Research milestone · month 7 and beyond',
      },
    );
  } else {
    return [];
  }
  return templates.map((t) => ({
    ...t,
    completed: completed.has(t.milestone_type),
    is_current: eligible != null && eligible === t.milestone_type,
  }));
}

/**
 * Participant-facing tracker: which milestone windows apply, what is done, and whether to show the “new” bell dot.
 */
export const getMilestoneTrackerSummary = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const userSnap = await db.collection('users').doc(uid).get();
  const user = userSnap.data();
  const profileStudy = user?.studyId as string | undefined;
  const isParticipant = user?.isResearchParticipant === true;
  if (!isParticipant || !profileStudy) {
    return { ok: false, not_enrolled: true as const };
  }

  const studyId =
    asNonEmptyStudyId((request.data as Record<string, unknown> | undefined)?.study_id) ?? profileStudy;
  if (studyId !== profileStudy) {
    throw new functions.https.HttpsError('permission-denied', 'study_id does not match enrolled research profile');
  }

  const baseSnap = await db.collection(BASELINE_COLL).doc(studyId).get();
  const baseline = baseSnap.exists ? baseSnap.data() : undefined;

  const submissionsSnap = await db.collection(COLL).where('study_id', '==', studyId).limit(100).get();
  const completed = new Set<number>();
  for (const d of submissionsSnap.docs) {
    const t = asMilestoneType(d.get('milestone_type'));
    if (t != null) completed.add(t);
  }

  const eligible = resolveMilestoneTypeFromBaseline(baseline);
  const journey_steps = buildJourneySteps(baseline, completed, eligible);
  const badge_dot = eligible != null && !completed.has(eligible);

  return {
    ok: true as const,
    study_id: studyId,
    eligible_milestone_type: eligible,
    badge_dot,
    journey_steps,
    schedule_reason: eligible != null ? 'baseline_window' : baseSnap.exists ? 'outside_longitudinal_windows' : 'no_baseline',
  };
});

export const scheduleMilestonePrompt = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const studyId = asNonEmptyStudyId((request.data as Record<string, unknown> | undefined)?.study_id);
  if (!studyId) {
    throw new functions.https.HttpsError('invalid-argument', 'study_id is required');
  }
  await assertParticipantStudy(uid, studyId);

  const baseSnap = await db.collection(BASELINE_COLL).doc(studyId).get();
  const baseline = baseSnap.exists ? baseSnap.data() : undefined;
  const milestone_type = resolveMilestoneTypeFromBaseline(baseline);
  const should_prompt = milestone_type != null;

  return {
    should_prompt,
    milestone_type,
    reason: should_prompt ? 'baseline_window' : baseSnap.exists ? 'outside_longitudinal_windows' : 'no_baseline',
  };
});

export const validateMilestoneCheckIn = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const studyId = asNonEmptyStudyId((request.data as Record<string, unknown> | undefined)?.study_id);
  if (!studyId) {
    return { valid: false, errors: ['study_id is required'] };
  }
  const res = validateMilestoneCheckInPayload(request.data ?? {});
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

export const submitMilestoneCheckIn = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = request.auth.uid;
  const validated = validateMilestoneCheckInPayload(request.data ?? {});
  if (!validated.ok) {
    throw new functions.https.HttpsError('invalid-argument', validated.errors.join('; '));
  }
  await assertParticipantStudy(uid, validated.payload.study_id);

  const recordedAt = admin.firestore.FieldValue.serverTimestamp();
  const milestoneTs = recordedAt;

  const docBody: Record<string, unknown> = {
    study_id: validated.payload.study_id,
    milestone_health_question: validated.payload.milestone_health_question,
    milestone_clear_next_step: validated.payload.milestone_clear_next_step,
    milestone_app_helped_next_step: validated.payload.milestone_app_helped_next_step,
    milestone_type: validated.payload.milestone_type,
    milestone_ts: milestoneTs,
    recorded_at: recordedAt,
  };

  const ref = await db.collection(COLL).add(docBody);
  return { ok: true, event_id: ref.id };
});
