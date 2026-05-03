/**
 * Research dataset export + dashboard summary (callable).
 */
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  RESEARCH_INSTRUMENTS,
  RESEARCH_SPEC_VERSION,
  rowToCsvLine,
  type ResearchInstrumentId,
} from './researchFieldSpec';
import {
  aggregateResearchSummaryFromDays,
  averagesFromSummaryData,
  milestoneResponseRate,
  moduleCompletionRate,
  navigationSuccessRate,
} from './researchSummaryCore';

const db = admin.firestore();

function parseDateRange(raw: unknown): { start: Date; end: Date } | undefined {
  if (!raw || typeof raw !== 'object') return undefined;
  const o = raw as Record<string, unknown>;
  const start = o.start != null ? new Date(String(o.start)) : undefined;
  const end = o.end != null ? new Date(String(o.end)) : undefined;
  if (!start || Number.isNaN(start.getTime()) || !end || Number.isNaN(end.getTime())) return undefined;
  return { start, end };
}

export async function canExportResearch(uid: string): Promise<boolean> {
  const adminDoc = await db.collection('ADMIN').doc(uid).get();
  if (adminDoc.exists) return true;
  const rp = await db.collection('RESEARCH_PARTNERS').doc(uid).get();
  return rp.exists;
}

function tsRange(dateRange: { start: Date; end: Date }) {
  const start = admin.firestore.Timestamp.fromDate(dateRange.start);
  const end = admin.firestore.Timestamp.fromDate(dateRange.end);
  return { start, end };
}

function serializeCell(v: unknown): unknown {
  if (v == null) return v;
  if (typeof v === 'object' && v !== null && 'toDate' in (v as object)) {
    try {
      return (v as admin.firestore.Timestamp).toDate().toISOString();
    } catch {
      return null;
    }
  }
  return v;
}

function pickExportRow(
  columns: readonly string[],
  raw: FirebaseFirestore.DocumentData,
): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const c of columns) {
    out[c] = serializeCell(raw[c]);
  }
  return out;
}

function buildCsv(columns: readonly string[], rows: Record<string, unknown>[]): string {
  const header = columns.join(',');
  const lines = rows.map((r) => rowToCsvLine(columns, r));
  return [header, ...lines].join('\n');
}

const EXPORT_ROW_LIMIT = 10000;

async function queryInstrumentRows(
  collection: string,
  columns: readonly string[],
  start: admin.firestore.Timestamp,
  end: admin.firestore.Timestamp,
  filters: { studyId?: string; recruitmentPathway?: number },
): Promise<Record<string, unknown>[]> {
  let q: admin.firestore.Query = db.collection(collection);
  if (filters.studyId) {
    q = q.where('study_id', '==', filters.studyId);
  }
  if (filters.recruitmentPathway != null) {
    if (collection === 'research_participants' || collection === 'research_baseline') {
      q = q.where('recruitment_pathway', '==', filters.recruitmentPathway);
    }
  }
  q = q
    .where('recorded_at', '>=', start)
    .where('recorded_at', '<=', end)
    .orderBy('recorded_at', 'asc')
    .limit(EXPORT_ROW_LIMIT);

  const snap = await q.get();
  return snap.docs.map((d) => pickExportRow(columns, d.data()));
}

export const exportResearchDataset = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
    if (!request.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const uid = request.auth.uid;
    if (!(await canExportResearch(uid))) {
      throw new functions.https.HttpsError('permission-denied', 'Research export requires admin or research partner');
    }

    const dateRange = parseDateRange(request.data?.dateRange);
    if (!dateRange) {
      throw new functions.https.HttpsError('invalid-argument', 'dateRange with start and end is required');
    }

    const format = request.data?.format === 'json' ? 'json' : 'csv';
    const studyId = typeof request.data?.studyId === 'string' ? request.data.studyId : undefined;
    const recruitmentPathway =
      typeof request.data?.recruitmentPathway === 'number' ? request.data.recruitmentPathway : undefined;

    const instrumentFilter = request.data?.instruments as ResearchInstrumentId[] | undefined;
    const instruments = RESEARCH_INSTRUMENTS.filter(
      (i) => !instrumentFilter?.length || instrumentFilter.includes(i.id),
    );

    const { start, end } = tsRange(dateRange);
    const filters = { studyId, recruitmentPathway };

    if (format === 'json') {
      const data: Record<string, Record<string, unknown>[]> = {};
      for (const inst of instruments) {
        data[inst.id] = await queryInstrumentRows(inst.collection, inst.columns, start, end, filters);
      }
      if (data.baseline) {
        data.baseline_export = data.baseline;
      }
      if (data.micro_measures) {
        data.micro_measures_export = data.micro_measures;
      }
      if (data.needs_checklist) {
        data.needs_checklist_export = data.needs_checklist;
      }
      if (data.navigation_outcomes) {
        data.navigation_outcomes_export = data.navigation_outcomes;
      }
      if (data.milestone_prompts) {
        data.milestones_export = data.milestone_prompts;
      }
      if (data.app_activity) {
        data.activity_export = data.app_activity;
      }
      await db.collection('audit_logs').add({
        action: 'research_export',
        format: 'json',
        performedBy: uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        specVersion: RESEARCH_SPEC_VERSION,
      });
      return { specVersion: RESEARCH_SPEC_VERSION, format: 'json', data };
    }

    const files: Record<string, string> = {};
    for (const inst of instruments) {
      const rows = await queryInstrumentRows(inst.collection, inst.columns, start, end, filters);
      files[inst.id] = buildCsv(inst.columns, rows);
    }
    if (files.baseline) {
      files.baseline_export = files.baseline;
    }
    if (files.micro_measures) {
      files.micro_measures_export = files.micro_measures;
    }
    if (files.needs_checklist) {
      files.needs_checklist_export = files.needs_checklist;
    }
    if (files.navigation_outcomes) {
      files.navigation_outcomes_export = files.navigation_outcomes;
    }
    if (files.milestone_prompts) {
      files.milestones_export = files.milestone_prompts;
    }
    if (files.app_activity) {
      files.activity_export = files.app_activity;
    }
    await db.collection('audit_logs').add({
      action: 'research_export',
      format: 'csv',
      performedBy: uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      specVersion: RESEARCH_SPEC_VERSION,
    });
    return { specVersion: RESEARCH_SPEC_VERSION, format: 'csv', files };
  },
);

export const getResearchDashboardSummary = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
    if (!request.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const uid = request.auth.uid;
    if (!(await canExportResearch(uid))) {
      throw new functions.https.HttpsError('permission-denied', 'Research dashboard requires admin or research partner');
    }

    const dateRange = parseDateRange(request.data?.dateRange);
    if (!dateRange) {
      throw new functions.https.HttpsError('invalid-argument', 'dateRange with start and end is required');
    }
    const { start, end } = tsRange(dateRange);

    const baselineCountSnap = await db
      .collection('research_baseline')
      .where('recorded_at', '>=', start)
      .where('recorded_at', '<=', end)
      .count()
      .get();

    const [aggregated, pw1, pw2] = await Promise.all([
      aggregateResearchSummaryFromDays(start, end),
      db.collection('research_summary_by_pathway').doc('1').get(),
      db.collection('research_summary_by_pathway').doc('2').get(),
    ]);

    const pathwaySlice = (data?: Record<string, unknown> | undefined) => {
      if (!data) return null;
      const av = averagesFromSummaryData(data);
      return {
        participant_count: Number(data.participant_count) || 0,
        micro_measure_count: Number(data.micro_measure_count) || 0,
        average_micro_understand: av.average_micro_understand,
        average_micro_next_step: av.average_micro_next_step,
        average_micro_confidence: av.average_micro_confidence,
        navigation_success_rate: navigationSuccessRate(data),
        module_completion_rate: moduleCompletionRate(data),
        milestone_response_rate: milestoneResponseRate(data),
        provider_review_count: Number(data.provider_review_count) || 0,
        avs_upload_count: Number(data.avs_upload_count) || 0,
        needs_frequency_by_category: (data.needs_frequency as Record<string, number>) || {},
      };
    };

    const cohortComparison = {
      navigator_supported: pathwaySlice(pw1.data() as Record<string, unknown> | undefined),
      self_directed: pathwaySlice(pw2.data() as Record<string, unknown> | undefined),
    };

    const merged = aggregated.merged as Record<string, unknown>;
    if (aggregated.daysWithData > 0) {
      const av = averagesFromSummaryData(merged);
      const microN = Number(merged.micro_measure_count) || 0;
      return {
        specVersion: RESEARCH_SPEC_VERSION,
        dateRange: { start: dateRange.start.toISOString(), end: dateRange.end.toISOString() },
        summarySource: 'layer' as const,
        summaryDaysWithData: aggregated.daysWithData,
        participantCount: Number(merged.participant_count) || 0,
        baselineCount: baselineCountSnap.data().count,
        microMeasureCount: Number(merged.micro_measure_count) || 0,
        needsChecklistCount: Number(merged.needs_checklist_count) || 0,
        navigationOutcomeCount: Number(merged.navigation_outcome_count) || 0,
        milestonePromptCount: Number(merged.milestone_prompt_count) || 0,
        appActivityCount: Number(merged.app_activity_count) || 0,
        microAverages: {
          micro_understand: av.average_micro_understand,
          micro_next_step: av.average_micro_next_step,
          micro_confidence: av.average_micro_confidence,
          sampleSize: microN,
        },
        navigationSuccessRate: navigationSuccessRate(merged),
        moduleCompletionRate: moduleCompletionRate(merged),
        milestoneResponseRate: milestoneResponseRate(merged),
        needsFrequencyByCategory: (merged.needs_frequency as Record<string, number>) || {},
        providerReviewCount: Number(merged.provider_review_count) || 0,
        avsUploadCount: Number(merged.avs_upload_count) || 0,
        cohortComparison,
      };
    }

    const participantCountSnap = await db
      .collection('research_participants')
      .where('recorded_at', '>=', start)
      .where('recorded_at', '<=', end)
      .count()
      .get();

    const microCountSnap = await db
      .collection('research_micro_measures')
      .where('recorded_at', '>=', start)
      .where('recorded_at', '<=', end)
      .count()
      .get();

    const microSample = await db
      .collection('research_micro_measures')
      .where('recorded_at', '>=', start)
      .where('recorded_at', '<=', end)
      .limit(500)
      .get();

    let sumU = 0,
      sumN = 0,
      sumC = 0,
      n = 0;
    microSample.docs.forEach((d) => {
      const x = d.data();
      const u = Number(x.micro_understand);
      const ne = Number(x.micro_next_step);
      const c = Number(x.micro_confidence);
      if (Number.isFinite(u)) {
        sumU += u;
        n += 1;
      }
      if (Number.isFinite(ne)) sumN += ne;
      if (Number.isFinite(c)) sumC += c;
    });
    const cnt = microSample.size || 1;

    const needsCountSnap = await db
      .collection('research_needs_checklists')
      .where('recorded_at', '>=', start)
      .where('recorded_at', '<=', end)
      .count()
      .get();

    const navCountSnap = await db
      .collection('research_navigation_outcomes')
      .where('recorded_at', '>=', start)
      .where('recorded_at', '<=', end)
      .count()
      .get();

    const milestoneCountSnap = await db
      .collection('research_milestone_prompts')
      .where('recorded_at', '>=', start)
      .where('recorded_at', '<=', end)
      .count()
      .get();

    const activityCountSnap = await db
      .collection('research_app_activity')
      .where('recorded_at', '>=', start)
      .where('recorded_at', '<=', end)
      .count()
      .get();

    return {
      specVersion: RESEARCH_SPEC_VERSION,
      dateRange: { start: dateRange.start.toISOString(), end: dateRange.end.toISOString() },
      summarySource: 'live' as const,
      summaryDaysWithData: 0,
      participantCount: participantCountSnap.data().count,
      baselineCount: baselineCountSnap.data().count,
      microMeasureCount: microCountSnap.data().count,
      needsChecklistCount: needsCountSnap.data().count,
      navigationOutcomeCount: navCountSnap.data().count,
      milestonePromptCount: milestoneCountSnap.data().count,
      appActivityCount: activityCountSnap.data().count,
      microAverages: {
        micro_understand: n ? sumU / n : null,
        micro_next_step: n ? sumN / cnt : null,
        micro_confidence: n ? sumC / cnt : null,
        sampleSize: microSample.size,
      },
      navigationSuccessRate: null,
      moduleCompletionRate: null,
      milestoneResponseRate: null,
      needsFrequencyByCategory: {},
      providerReviewCount: 0,
      avsUploadCount: 0,
      cohortComparison,
    };
  },
);
