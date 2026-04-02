/**
 * Analytics Event Logging
 * Client-side analytics helper that calls Cloud Functions for anonymization
 */

import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

export interface AnalyticsEvent {
  eventName: string;
  feature: string;
  metadata?: Record<string, any>;
  durationMs?: number;
  sessionId?: string;
}

/**
 * Log an analytics event
 * This calls a Cloud Function that handles anonymization server-side
 */
export async function logEvent(event: AnalyticsEvent): Promise<void> {
  try {
    const logAnalyticsEventFn = httpsCallable(functions, 'logAnalyticsEvent');
    await logAnalyticsEventFn(event);
  } catch (error) {
    console.error('Failed to log analytics event:', error);
    // Don't throw - analytics failures shouldn't break the app
  }
}

/**
 * Track feature view start
 */
export function trackFeatureViewStart(feature: string, sessionId?: string): () => void {
  const startTime = Date.now();
  
  return () => {
    const durationMs = Date.now() - startTime;
    logEvent({
      eventName: 'feature_view_end',
      feature,
      durationMs,
      sessionId,
    });
  };
}

export interface AnalyticsDashboardRollup {
  activeUsers: number;
  totalEvents: number;
  featureUsage: Record<string, number>;
  avgDurations: Record<string, number>;
  avgDurationMs: number;
  eventCounts?: Record<string, number>;
  holisticReport?: {
    executiveSummary?: {
      confidenceImprovedPct: number;
      understandingImprovedPct: number;
      actionTakenPct: number;
      highestPerformingFeatures: string[];
    };
    cohortBreakdown?: {
      trimester: Record<string, number>;
      cohortType: Record<string, number>;
      engagementLevel: Record<string, number>;
      newVsReturning: Record<string, number>;
    };
    journeyFunnel?: Record<string, number>;
    featurePerformance?: Array<{
      feature: string;
      usageRate: number;
      outcomeImpact: number;
      notes: string;
    }>;
    engagementDepth?: { averageScore: number; formula: string };
    outcomeMetrics?: Record<string, number>;
    timeInsights?: Record<string, number>;
    behaviorCorrelations?: Record<string, number>;
    recommendations?: string[];
  };
}

/**
 * Get analytics data (calls Cloud Function). Dates are serialized as ISO strings for Gen-2 callables.
 */
export async function getAnalyticsData(params: {
  dateRange?: { start: Date; end: Date };
  feature?: string;
  anonymized?: boolean;
}): Promise<AnalyticsDashboardRollup> {
  const getAnalyticsDataFn = httpsCallable(functions, 'getAnalyticsData');
  const payload: Record<string, unknown> = {
    anonymized: params.anonymized ?? true,
  };
  if (params.feature) {
    payload.feature = params.feature;
  }
  if (params.dateRange) {
    payload.dateRange = {
      start: params.dateRange.start.toISOString(),
      end: params.dateRange.end.toISOString(),
    };
  }
  const result = await getAnalyticsDataFn(payload);
  return result.data as AnalyticsDashboardRollup;
}
