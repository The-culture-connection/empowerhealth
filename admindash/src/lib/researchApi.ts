/**
 * Callable wrappers for research export + dashboard summary.
 */
import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

export type ResearchExportFormat = 'csv' | 'json';

export interface ResearchDateRange {
  start: Date;
  end: Date;
}

export async function exportResearchDataset(params: {
  format: ResearchExportFormat;
  dateRange: ResearchDateRange;
  studyId?: string;
  recruitmentPathway?: 1 | 2;
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
  });
  return result.data as {
    specVersion: string;
    format: ResearchExportFormat;
    files?: Record<string, string>;
    data?: Record<string, Record<string, unknown>[]>;
  };
}

export async function getResearchDashboardSummary(params: {
  dateRange: ResearchDateRange;
}): Promise<{
  specVersion: string;
  dateRange: { start: string; end: string };
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
}> {
  const fn = httpsCallable(functions, 'getResearchDashboardSummary');
  const result = await fn({
    dateRange: {
      start: params.dateRange.start.toISOString(),
      end: params.dateRange.end.toISOString(),
    },
  });
  return result.data as {
    specVersion: string;
    dateRange: { start: string; end: string };
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
  };
}

export function downloadTextFile(filename: string, content: string, mime: string) {
  const blob = new Blob([content], { type: mime });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  a.click();
  URL.revokeObjectURL(a.href);
}
