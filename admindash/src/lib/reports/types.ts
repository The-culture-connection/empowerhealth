/**
 * Shared types for research reports (client-side aggregation).
 */

export type ReportType =
  | "health_understanding_impact"
  | "self_advocacy_confidence"
  | "care_navigation_success"
  | "care_preparation"
  | "engagement_pathway"
  | "community_support";

export type EventImplementationStatus = "tracked" | "partial" | "needs-implementation";

export interface CoverageFlag {
  eventOrSource: string;
  status: EventImplementationStatus;
  note: string;
  /** True when zero matching rows were found in-range (data may still be valid elsewhere). */
  limitedInRange?: boolean;
}

export interface ReportParams {
  reportType: ReportType;
  anonymized: boolean;
  dateRange: { start: Date; end: Date };
  cohortType?: string;
}

export interface NormalizedEvent {
  id: string;
  eventName: string;
  feature: string;
  timestamp: Date | null;
  uid?: string;
  anonUserId?: string;
  metadata: Record<string, unknown>;
  durationMs: number | null;
}

export interface NormalizedModuleFeedback {
  id: string;
  userId: string | null;
  moduleId: string | null;
  moduleTitle: string | null;
  understandingScore: number | null;
  helpfulnessScore: number | null;
  confidenceScore: number | null;
  freeTextFeedback: string | null;
  timestamp: Date | null;
}

export interface NormalizedCareSurvey {
  id: string;
  userId: string | null;
  selectedNeeds: string[];
  accessResponses: Record<string, string>;
  confidenceComposite: number | null;
  /** Distribution of raw access values per need id */
  rawOutcomes: Record<string, string>;
  timestamp: Date | null;
}

export interface NormalizedCareNavigationOutcome {
  id: string;
  userId: string | null;
  needType: string | null;
  outcome: string | null;
  timestamp: Date | null;
}

export interface ReportDataset {
  events: NormalizedEvent[];
  moduleFeedback: NormalizedModuleFeedback[];
  careSurveys: NormalizedCareSurvey[];
  careNavigationOutcomes: NormalizedCareNavigationOutcome[];
  /** Deprecated: kept empty; coverage lives on evidence.coverageNote per report. */
  coverageFlags: CoverageFlag[];
}

/** Row for “Relevant events included” table (Analytics Info–aligned). */
export interface EventEvidenceRow {
  eventName: string;
  whatItMeasures: string;
  status: EventImplementationStatus;
}

export interface OutcomeSignalsBlock {
  lines: string[];
  moduleFeedback?: { n: number; avgUnderstanding: number | null };
  careSurvey?: { n: number; avgComposite: number | null };
  pulseAverages?: {
    understandMeaning: number | null;
    knowNextStep: number | null;
    confidence: number | null;
    nEvents: number;
  };
  careNavigationOutcomes?: { n: number; positiveShare: string };
}

/** Evidence-first report body (sections A–F). */
export interface EvidenceReport {
  /** A) Report summary */
  summaryParagraph: string;
  totalUsers: number;
  dateRangeLabel: string;
  mainTrend: string;
  takeaways: string[];
  /** B) */
  eventsIncluded: EventEvidenceRow[];
  /** C) */
  metricsKpis: ReportKpi[];
  /** D) */
  outcomeSignals: OutcomeSignalsBlock;
  /** E) */
  conclusions: string[];
  /** F) */
  coverageNote: string;
}

export interface ReportChartSpec {
  id: string;
  title: string;
  kind: "line" | "bar";
  labels: string[];
  series: { name: string; data: number[] }[];
}

export interface ReportTableSpec {
  title: string;
  columns: string[];
  rows: (string | number)[][];
}

export interface ReportKpi {
  key: string;
  label: string;
  value: string | number;
}

export interface ReportSummary {
  title: string;
  dateRangeLabel: string;
  generatedAt: string;
  cohortFilter?: string;
}

export interface ReportPayload {
  summary: ReportSummary;
  evidence: EvidenceReport;
  kpis: ReportKpi[];
  charts: ReportChartSpec[];
  tables: ReportTableSpec[];
  /** @deprecated Prefer evidence.conclusions */
  insights: string[];
  coverageFlags: CoverageFlag[];
  /** Flat rows for CSV (anonymized when requested). */
  rows: Record<string, string | number | null>[];
}

/** Shape consumed by Reports.tsx (backward compatible fields). */
export interface ReportResult {
  summary: ReportSummary;
  evidence: EvidenceReport;
  kpis: Record<string, string | number>;
  kpisList: ReportKpi[];
  charts: ReportChartSpec[];
  tables: ReportTableSpec[];
  insights: string[];
  coverageFlags: CoverageFlag[];
  rows: Record<string, string | number | null>[];
}
