/**
 * Report Generation
 * Calls Cloud Functions to generate reports with insights
 */

import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

export type ReportType = 
  | 'health_understanding_impact'
  | 'self_advocacy_confidence'
  | 'care_navigation_success'
  | 'care_preparation'
  | 'engagement_pathway'
  | 'community_support';

export interface ReportParams {
  reportType: ReportType;
  anonymized: boolean;
  dateRange: {
    start: Date;
    end: Date;
  };
  cohortType?: string;
}

export interface ReportResult {
  rows: any[];
  kpis: Record<string, number | string>;
  charts: {
    series: any[];
    labels?: string[];
  };
  insights: string[];
}

/**
 * Generate a report via Cloud Function
 */
export async function generateReport(params: ReportParams): Promise<ReportResult> {
  const generateReportFn = httpsCallable(functions, 'generateReport');
  const result = await generateReportFn({
    ...params,
    dateRange: {
      start: params.dateRange.start.toISOString(),
      end: params.dateRange.end.toISOString(),
    },
  });
  return result.data as ReportResult;
}

/**
 * Export report as CSV
 */
export function exportReportAsCSV(rows: any[], filename: string): void {
  if (rows.length === 0) return;

  const headers = Object.keys(rows[0]);
  const csvContent = [
    headers.join(','),
    ...rows.map(row => 
      headers.map(header => {
        const value = row[header];
        // Escape commas and quotes
        if (typeof value === 'string' && (value.includes(',') || value.includes('"'))) {
          return `"${value.replace(/"/g, '""')}"`;
        }
        return value ?? '';
      }).join(',')
    ),
  ].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

/**
 * Export report as JSON
 */
export function exportReportAsJSON(data: any, filename: string): void {
  const jsonContent = JSON.stringify(data, null, 2);
  const blob = new Blob([jsonContent], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
