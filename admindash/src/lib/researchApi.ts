/**
 * Callable wrappers for research export + dashboard summary.
 */
import type { ResearchInstrumentId } from '@research/researchFieldSpec';
import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

export type ResearchExportFormat = 'csv' | 'json';

export type { ResearchInstrumentId };

export interface ResearchDateRange {
  start: Date;
  end: Date;
}

export async function exportResearchDataset(params: {
  format: ResearchExportFormat;
  dateRange: ResearchDateRange;
  studyId?: string;
  recruitmentPathway?: 1 | 2;
  /** When set, only these instruments are queried (see `exportResearchDataset` Cloud Function). */
  instruments?: ResearchInstrumentId[];
}): Promise<{
  specVersion: string;
  format: ResearchExportFormat;
  files?: Record<string, string>;
  data?: Record<string, Record<string, unknown>[]>;
}> {
  const fn = httpsCallable(functions, 'exportResearchDataset');
  const result = await fn({
    format: params.format,
    dateRange: {
      start: params.dateRange.start.toISOString(),
      end: params.dateRange.end.toISOString(),
    },
    studyId: params.studyId || undefined,
    recruitmentPathway: params.recruitmentPathway,
    instruments: params.instruments?.length ? params.instruments : undefined,
  });
  return result.data as {
    specVersion: string;
    format: ResearchExportFormat;
    files?: Record<string, string>;
    data?: Record<string, Record<string, unknown>[]>;
  };
}

export type ResearchSummarySource = 'layer' | 'live';

export type PathwaySummarySlice = {
  participant_count: number;
  micro_measure_count: number;
  average_micro_understand: number | null;
  average_micro_next_step: number | null;
  average_micro_confidence: number | null;
  navigation_success_rate: number | null;
  module_completion_rate: number | null;
  milestone_response_rate: number | null;
  provider_review_count: number;
  avs_upload_count: number;
  needs_frequency_by_category: Record<string, number>;
} | null;

export type ResearchDashboardSummary = {
  specVersion: string;
  dateRange: { start: string; end: string };
  summarySource?: ResearchSummarySource;
  summaryDaysWithData?: number;
  participantCount: number;
  baselineCount?: number;
  microMeasureCount: number;
  needsChecklistCount: number;
  navigationOutcomeCount: number;
  milestonePromptCount: number;
  appActivityCount: number;
  microAverages: {
    micro_understand: number | null;
    micro_next_step: number | null;
    micro_confidence: number | null;
    sampleSize: number;
  };
  navigationSuccessRate?: number | null;
  moduleCompletionRate?: number | null;
  milestoneResponseRate?: number | null;
  needsFrequencyByCategory?: Record<string, number>;
  providerReviewCount?: number;
  avsUploadCount?: number;
  cohortComparison?: {
    navigator_supported: PathwaySummarySlice;
    self_directed: PathwaySummarySlice;
  };
};

export async function getResearchDashboardSummary(params: {
  dateRange: ResearchDateRange;
}): Promise<ResearchDashboardSummary> {
  const fn = httpsCallable(functions, 'getResearchDashboardSummary');
  const result = await fn({
    dateRange: {
      start: params.dateRange.start.toISOString(),
      end: params.dateRange.end.toISOString(),
    },
  });
  return result.data as ResearchDashboardSummary;
}

export async function recomputeResearchSummaries(params: {
  dateRange: ResearchDateRange;
  rebuildGlobal?: boolean;
}): Promise<{ daysProcessed: number; daysWithActivity: number; warnings: string[] }> {
  const fn = httpsCallable(functions, 'recomputeResearchSummaries');
  const result = await fn({
    dateRange: {
      start: params.dateRange.start.toISOString(),
      end: params.dateRange.end.toISOString(),
    },
    rebuildGlobal: params.rebuildGlobal !== false,
  });
  return result.data as { daysProcessed: number; daysWithActivity: number; warnings: string[] };
}

export function downloadTextFile(filename: string, content: string, mime: string) {
  const blob = new Blob([content], { type: mime });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  a.click();
  URL.revokeObjectURL(a.href);
}
