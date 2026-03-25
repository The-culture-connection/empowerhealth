/**
 * Feature Analytics
 * Tracks and retrieves analytics for specific features
 */

import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

export interface FeatureAnalytics {
  featureId: string;
  activeUsers: number;
  adoptionRate: number;
  engagementTrend: Array<{ date: string; value: number }>;
  usageByWeek: Array<{ week: string; sessions: number }>;
  kpis: {
    completionRate: number;
    exportRate: number;
    avgDuration: number;
    totalViews: number;
    totalCompletions: number;
    totalExports: number;
  };
}

/**
 * Get analytics for a specific feature
 */
export async function getFeatureAnalytics(
  featureId: string,
  dateRange: { start: Date; end: Date } = {
    start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Last 30 days
    end: new Date()
  },
  anonymized: boolean = true
): Promise<FeatureAnalytics> {
  const getFeatureAnalyticsFn = httpsCallable(functions, 'getFeatureAnalytics');
  
  const result = await getFeatureAnalyticsFn({
    featureId,
    dateRange: {
      start: dateRange.start.toISOString(),
      end: dateRange.end.toISOString()
    },
    anonymized
  });
  
  return result.data as FeatureAnalytics;
}

/**
 * Log a feature event (client-side)
 * This should be called from the mobile app or web app when users interact with features
 */
export async function logFeatureEvent(
  featureId: string,
  eventName:
    | 'feature_view_start'
    | 'feature_view_end'
    | 'feature_completion'
    | 'feature_export'
    | 'feature_share'
    | 'provider_selected_success'
    | 'screen_time_spent'
    | 'feature_time_spent'
    | 'community_post_replied'
    | 'community_post_liked'
    | 'learning_module_completed'
    | 'flow_abandoned',
  metadata?: Record<string, any>,
  durationMs?: number
): Promise<void> {
  const logAnalyticsEventFn = httpsCallable(functions, 'logAnalyticsEvent');
  
  await logAnalyticsEventFn({
    eventName,
    feature: featureId,
    metadata: metadata || {},
    durationMs,
    sessionId: getSessionId()
  });
}

/**
 * Get or create session ID
 */
function getSessionId(): string {
  let sessionId = sessionStorage.getItem('analytics_session_id');
  if (!sessionId) {
    sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    sessionStorage.setItem('analytics_session_id', sessionId);
  }
  return sessionId;
}

/**
 * Feature ID constants
 */
export const FEATURE_IDS = {
  PROVIDER_SEARCH: 'provider-search',
  AUTHENTICATION: 'authentication-onboarding',
  USER_FEEDBACK: 'user-feedback',
  APPOINTMENT_SUMMARY: 'appointment-summarizing',
  JOURNAL: 'journal',
  LEARNING_MODULES: 'learning-modules',
  BIRTH_PLAN: 'birth-plan-generator',
  COMMUNITY: 'community',
  PROFILE_EDITING: 'profile-editing'
} as const;
