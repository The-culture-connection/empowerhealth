/**
 * Research reports: client-side Firestore aggregation + exports.
 * (Replaces callable-only generateReport for richer, survey-integrated outputs.)
 */

import { auth, firestore } from "../../firebase/firebase";
import { getReportDataset } from "../firestore/reportsRepo";
import type { ReportDataset, ReportParams, ReportPayload, ReportResult } from "./types";
import {
  buildCareNavigationReport,
  buildCarePreparationReport,
  buildCommunitySupportReport,
  buildEngagementPathwayReport,
  buildHealthUnderstandingReport,
  buildSelfAdvocacyReport,
  payloadToResult,
} from "./reportBuilders";

export type {
  ReportParams,
  ReportResult,
  ReportType,
  ReportChartSpec,
  ReportTableSpec,
  ReportKpi,
  EventImplementationStatus,
} from "./types";

function stripIdsForExport(rows: Record<string, string | number | null>[]) {
  return rows.map((r) => {
    const copy = { ...r };
    delete copy.uid;
    delete copy.userId;
    return copy;
  });
}

function buildPayload(dataset: ReportDataset, params: ReportParams): ReportPayload {
  switch (params.reportType) {
    case "health_understanding_impact":
      return buildHealthUnderstandingReport(dataset, params);
    case "self_advocacy_confidence":
      return buildSelfAdvocacyReport(dataset, params);
    case "care_navigation_success":
      return buildCareNavigationReport(dataset, params);
    case "engagement_pathway":
      return buildEngagementPathwayReport(dataset, params);
    case "care_preparation":
      return buildCarePreparationReport(dataset, params);
    case "community_support":
      return buildCommunitySupportReport(dataset, params);
    default: {
      const _: never = params.reportType;
      throw new Error(`Unknown report: ${_}`);
    }
  }
}

/**
 * Load events + ModuleFeedback + CareSurvey + birth-plan qualitative, compute report on-device.
 */
export async function generateReport(params: ReportParams): Promise<ReportResult> {
  const user = auth.currentUser;
  if (!user) {
    throw new Error("You must be signed in to generate reports.");
  }
  await user.getIdToken(true);

  const dataset = await getReportDataset(firestore, params.dateRange.start, params.dateRange.end);
  const payload = buildPayload(dataset, params);

  if (params.anonymized) {
    payload.rows = stripIdsForExport(payload.rows);
  }

  return payloadToResult(payload);
}

/** CSV: uses flattened `rows` when non-empty, otherwise KPI list. */
export function exportReportAsCSV(rows: Record<string, string | number | null>[], filename: string): void {
  const source =
    rows.length > 0
      ? rows
      : [];
  if (source.length === 0) return;

  const headers = Object.keys(source[0]);
  const csvContent = [
    headers.join(","),
    ...source.map((row) =>
      headers
        .map((header) => {
          const value = row[header];
          if (value == null) return "";
          if (typeof value === "string" && (value.includes(",") || value.includes('"'))) {
            return `"${value.replace(/"/g, '""')}"`;
          }
          return String(value);
        })
        .join(","),
    ),
  ].join("\n");

  const blob = new Blob([csvContent], { type: "text/csv" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

/** Export full result including charts metadata + coverage flags. */
export function exportReportAsJSON(data: unknown, filename: string): void {
  const jsonContent = JSON.stringify(data, null, 2);
  const blob = new Blob([jsonContent], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

/** When rows empty, export KPIs + key evidence fields as a single-row CSV for research staff. */
export function exportReportKpisAsCSV(result: ReportResult, filename: string): void {
  const row: Record<string, string | number> = {};
  for (const k of result.kpisList) {
    row[k.label] = k.value;
  }
  const ev = result.evidence;
  row["Evidence: summary"] = ev.summaryParagraph;
  row["Evidence: total users"] = ev.totalUsers;
  row["Evidence: date range"] = ev.dateRangeLabel;
  row["Evidence: main trend"] = ev.mainTrend;
  row["Evidence: takeaways"] = ev.takeaways.join(" | ");
  row["Evidence: outcome signals"] = ev.outcomeSignals.lines.join(" | ");
  row["Evidence: conclusions"] = ev.conclusions.join(" | ");
  row["Evidence: coverage note"] = ev.coverageNote;
  row["Evidence: events included (JSON)"] = JSON.stringify(ev.eventsIncluded);
  exportReportAsCSV([row], filename);
}
