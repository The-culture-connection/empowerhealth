/**
 * Phase 7 — Firestore triggers: increment `research_summary_*` on each research row create (no double count).
 */
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import {
  applyResearchSummaryDelta,
  recruitmentPathwayForStudy,
} from './researchSummaryCore';

async function pathwayForStudy(studyId: string): Promise<1 | 2 | null> {
  return recruitmentPathwayForStudy(studyId);
}

export const onResearchMicroMeasureCreated = onDocumentCreated(
  { document: 'research_micro_measures/{id}', region: 'us-central1' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as Record<string, unknown>;
    const studyId = String(data.study_id || '').trim();
    if (!studyId) return;
    try {
      const pathway = await pathwayForStudy(studyId);
      const recordedAt = data.recorded_at as admin.firestore.Timestamp | undefined;
      await applyResearchSummaryDelta({
        studyId,
        recordedAt,
        pathway,
        kind: 'micro_measure',
        data,
      });
    } catch (e) {
      console.error('[onResearchMicroMeasureCreated]', event.id, e);
    }
  },
);

export const onResearchNeedsChecklistCreated = onDocumentCreated(
  { document: 'research_needs_checklists/{id}', region: 'us-central1' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as Record<string, unknown>;
    const studyId = String(data.study_id || '').trim();
    if (!studyId) return;
    try {
      const pathway = await pathwayForStudy(studyId);
      const recordedAt = data.recorded_at as admin.firestore.Timestamp | undefined;
      await applyResearchSummaryDelta({
        studyId,
        recordedAt,
        pathway,
        kind: 'needs_checklist',
        data,
      });
    } catch (e) {
      console.error('[onResearchNeedsChecklistCreated]', event.id, e);
    }
  },
);

export const onResearchOutcomeCreated = onDocumentCreated(
  { document: 'research_navigation_outcomes/{id}', region: 'us-central1' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as Record<string, unknown>;
    const studyId = String(data.study_id || '').trim();
    if (!studyId) return;
    try {
      const pathway = await pathwayForStudy(studyId);
      const recordedAt = data.recorded_at as admin.firestore.Timestamp | undefined;
      await applyResearchSummaryDelta({
        studyId,
        recordedAt,
        pathway,
        kind: 'navigation_outcome',
        data,
      });
    } catch (e) {
      console.error('[onResearchOutcomeCreated]', event.id, e);
    }
  },
);

export const onResearchActivityCreated = onDocumentCreated(
  { document: 'research_app_activity/{id}', region: 'us-central1' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as Record<string, unknown>;
    const studyId = String(data.study_id || '').trim();
    if (!studyId) return;
    try {
      const pathway = await pathwayForStudy(studyId);
      const recordedAt = data.activity_ts as admin.firestore.Timestamp | undefined;
      const recordedAtFallback = data.recorded_at as admin.firestore.Timestamp | undefined;
      await applyResearchSummaryDelta({
        studyId,
        recordedAt: recordedAt ?? recordedAtFallback,
        pathway,
        kind: 'app_activity',
        data,
      });
    } catch (e) {
      console.error('[onResearchActivityCreated]', event.id, e);
    }
  },
);

/** Milestone rows power `milestone_response_rate` in the summary layer (callable-only creates). */
export const onResearchMilestonePromptCreated = onDocumentCreated(
  { document: 'research_milestone_prompts/{id}', region: 'us-central1' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as Record<string, unknown>;
    const studyId = String(data.study_id || '').trim();
    if (!studyId) return;
    try {
      const pathway = await pathwayForStudy(studyId);
      const recordedAt = data.recorded_at as admin.firestore.Timestamp | undefined;
      await applyResearchSummaryDelta({
        studyId,
        recordedAt,
        pathway,
        kind: 'milestone_prompt',
        data,
      });
    } catch (e) {
      console.error('[onResearchMilestonePromptCreated]', event.id, e);
    }
  },
);

/** One row per enrolled study in `research_participants` (doc id = `study_id`). */
export const onResearchParticipantCreated = onDocumentCreated(
  { document: 'research_participants/{studyId}', region: 'us-central1' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as Record<string, unknown>;
    const studyId = String(event.params.studyId || data.study_id || '').trim();
    if (!studyId) return;
    try {
      const pw = Number(data.recruitment_pathway);
      const pathway = pw === 1 || pw === 2 ? (pw as 1 | 2) : await pathwayForStudy(studyId);
      const recordedAt = data.recorded_at as admin.firestore.Timestamp | undefined;
      await applyResearchSummaryDelta({
        studyId,
        recordedAt,
        pathway,
        kind: 'participant',
        data,
      });
    } catch (e) {
      console.error('[onResearchParticipantCreated]', event.id, e);
    }
  },
);
