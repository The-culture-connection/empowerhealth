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

/**
 * Get analytics data (calls Cloud Function)
 */
export async function getAnalyticsData(params: {
  dateRange?: { start: Date; end: Date };
  feature?: string;
  anonymized?: boolean;
}): Promise<any> {
  const getAnalyticsDataFn = httpsCallable(functions, 'getAnalyticsData');
  const result = await getAnalyticsDataFn(params);
  return result.data;
}
