/**
 * Read pre-aggregated analytics docs (written by onAnalyticsEventCreated).
 */

import { collection, getDocs } from 'firebase/firestore';
import { firestore } from '../firebase/firebase';

export interface DailySummaryRow {
  dateKey: string;
  totalEvents?: number;
  countsByFeature?: Record<string, number>;
}

export interface FeatureSummaryRow {
  id: string;
  feature?: string;
  totalEvents?: number;
  lastEventName?: string;
}

/** Last N calendar days of `analytics_summary_daily` (oldest → newest for charts). Sorts in memory to avoid index requirements. */
export async function fetchDailySummariesForChart(days: number): Promise<DailySummaryRow[]> {
  const snap = await getDocs(collection(firestore, 'analytics_summary_daily'));
  const rows: DailySummaryRow[] = snap.docs.map((d) => {
    const data = d.data();
    return {
      dateKey: typeof data.dateKey === 'string' ? data.dateKey : d.id,
      totalEvents: typeof data.totalEvents === 'number' ? data.totalEvents : undefined,
      countsByFeature:
        data.countsByFeature && typeof data.countsByFeature === 'object'
          ? (data.countsByFeature as Record<string, number>)
          : undefined,
    };
  });
  const valid = rows.filter((r) => /^\d{4}-\d{2}-\d{2}$/.test(r.dateKey));
  valid.sort((a, b) => a.dateKey.localeCompare(b.dateKey));
  const n = Math.max(1, days);
  return valid.slice(-n);
}

/** Top features by totalEvents for bar / table supplements. */
export async function fetchTopFeatureSummaries(maxRows: number): Promise<FeatureSummaryRow[]> {
  const snap = await getDocs(collection(firestore, 'analytics_feature_summary'));
  const rows: FeatureSummaryRow[] = snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      feature: typeof data.feature === 'string' ? data.feature : d.id,
      totalEvents: typeof data.totalEvents === 'number' ? data.totalEvents : 0,
      lastEventName: typeof data.lastEventName === 'string' ? data.lastEventName : undefined,
    };
  });
  return rows
    .sort((a, b) => (b.totalEvents || 0) - (a.totalEvents || 0))
    .slice(0, Math.max(1, maxRows));
}
