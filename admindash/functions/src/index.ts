/**
 * Firebase Cloud Functions for EmpowerHealth Admin Dashboard
 */

import * as functions from 'firebase-functions';
import * as functionsV1 from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { defineString, defineSecret } from 'firebase-functions/params';

admin.initializeApp();

const db = admin.firestore();

/** Parse callable client date range (ISO strings or timestamps). */
function parseDateRange(raw: any): { start: Date; end: Date } | undefined {
  if (!raw || typeof raw !== 'object') return undefined;
  const start = raw.start != null ? new Date(raw.start) : undefined;
  const end = raw.end != null ? new Date(raw.end) : undefined;
  if (!start || Number.isNaN(start.getTime()) || !end || Number.isNaN(end.getTime())) {
    return undefined;
  }
  return { start, end };
}

/**
 * Upload Build Version
 * Called from CI/CD or manual script to upload build version info
 */
export const uploadBuildVersion = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { fullVersion, commitHash, featureDossier } = request.data || {};

  if (!fullVersion || !featureDossier) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  // Parse version (e.g., "1.2.3+13")
  const versionMatch = fullVersion.match(/^(\d+\.\d+\.\d+)\+(\d+)$/);
  if (!versionMatch) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid version format. Expected: X.Y.Z+BUILD');
  }

  const versionName = versionMatch[1];
  const buildNumber = parseInt(versionMatch[2], 10);

  // Write to build_versions collection
  const buildVersionDoc = {
    versionName,
    buildNumber,
    fullVersion,
    commitHash: commitHash || null,
    releaseDate: admin.firestore.FieldValue.serverTimestamp(),
    featureDossier,
    createdBy: request.auth.uid,
  };

  await db.collection('build_versions').doc(buildNumber.toString()).set(buildVersionDoc);

  // Log audit event
  await db.collection('audit_logs').add({
    action: 'build_version_uploaded',
    buildNumber,
    fullVersion,
    performedBy: request.auth.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, buildNumber };
  },
);

/**
 * Log Analytics Event
 * Handles anonymization server-side
 * 
 * NOTE: This function does NOT require App Check - it only requires user authentication.
 * App Check enforcement must be disabled in Firebase Console → App Check → APIs → Cloud Functions
 * if App Check is not configured for the client app.
 * 
 * The function uses the authenticated user's UID (context.auth.uid) to tie analytics to users.
 */
export const logAnalyticsEvent = functions.https.onCall({
  // Explicitly disable App Check enforcement - we only need user authentication
  enforceAppCheck: false,
}, async (request: functions.https.CallableRequest) => {
  // Log incoming request details for debugging
  console.log('[Analytics] Request received');
  console.log('[Analytics] Request.auth exists:', !!request.auth);
  console.log('[Analytics] Request.auth.uid:', request.auth?.uid);
  console.log('[Analytics] Request.app exists:', !!request.app);
  console.log('[Analytics] Raw request keys:', Object.keys(request));
  
  // Extract data and auth from request (v2 format)
  const data = request.data;
  const auth = request.auth;
  
  // Only require authentication - App Check is NOT required
  if (!auth) {
    console.error('[Analytics] Authentication failed - request.auth is null');
    console.error('[Analytics] Full request structure:', {
      hasAuth: !!request.auth,
      hasApp: !!request.app,
      hasData: !!request.data,
      keys: Object.keys(request)
    });
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { eventName, feature, metadata, durationMs, sessionId } = data;
  const uid = auth.uid; // Use authenticated user's UID from request.auth
  
  console.log(`[Analytics] Event received: ${eventName} for feature: ${feature} from user: ${uid}`);
  
  // Validate feature ID
  const validFeatures = [
    'provider-search',
    'authentication-onboarding',
    'user-feedback',
    'appointment-summarizing',
    'journal',
    'learning-modules',
    'birth-plan-generator',
    'community',
    'profile-editing',
    'app' // For system-level events
  ];
  
  if (feature && !validFeatures.includes(feature)) {
    console.warn(`Invalid feature ID: ${feature}, using 'unknown'`);
  }

  // Generate anonymized user ID (salted hash)
  const crypto = require('crypto');
  const analyticsSalt = defineString('ANALYTICS_SALT', { default: 'default-salt-change-in-production' });
  const salt = analyticsSalt.value();
  const anonUserId = crypto
    .createHash('sha256')
    .update(uid + salt)
    .digest('hex')
    .substring(0, 16);

  const timestamp = admin.firestore.FieldValue.serverTimestamp();

  // Extract user lifecycle context from metadata
  // These fields are attached to every event for cohort analysis
  const lifecycleContext: Record<string, any> = {};
  if (metadata) {
    // Core lifecycle fields
    if (metadata.user_id) lifecycleContext.user_id = metadata.user_id;
    if (metadata.cohort_type) lifecycleContext.cohort_type = metadata.cohort_type;
    if (metadata.navigator !== undefined) lifecycleContext.navigator = metadata.navigator;
    if (metadata.self_directed !== undefined) lifecycleContext.self_directed = metadata.self_directed;
    if (metadata.pregnancy_week !== undefined) lifecycleContext.pregnancy_week = metadata.pregnancy_week;
    if (metadata.trimester) lifecycleContext.trimester = metadata.trimester;
    if (metadata.session_id) lifecycleContext.session_id = metadata.session_id;
    
    // Optional lifecycle fields
    if (metadata.provider_selected !== undefined) lifecycleContext.provider_selected = metadata.provider_selected;
    if (metadata.appointment_upcoming !== undefined) lifecycleContext.appointment_upcoming = metadata.appointment_upcoming;
    if (metadata.postpartum_phase) lifecycleContext.postpartum_phase = metadata.postpartum_phase;
  }

  // Merge lifecycle context with event-specific metadata
  const enrichedMetadata = {
    ...lifecycleContext,
    ...(metadata || {}),
  };

  // Write anonymized event (source: cloud_function — skipped by realtime aggregation trigger)
  const anonEvent = {
    anonUserId,
    eventName,
    feature,
    metadata: enrichedMetadata,
    durationMs: durationMs || null,
    sessionId: sessionId || null,
    timestamp,
    source: 'cloud_function',
    aggregationVersion: 1,
  };

  await db.collection('analytics_events').add(anonEvent);

  // Write private event (Admin only)
  const privateEvent = {
    uid,
    anonUserId,
    eventName,
    feature,
    metadata: enrichedMetadata,
    durationMs: durationMs || null,
    sessionId: sessionId || null,
    timestamp,
  };

  await db.collection('analytics_events_private').add(privateEvent);

  console.log(`[Analytics] Event logged successfully: ${eventName} (anonUserId: ${anonUserId}, uid: ${uid})`);
  return { success: true };
});

/**
 * Get Analytics Data
 * Aggregates analytics data with role-based access
 */
export const getAnalyticsData = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
    if (!request.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { feature, anonymized = true } = request.data || {};
    const dateRange = parseDateRange(request.data?.dateRange);
    const uid = request.auth.uid;

    const isAdmin = await checkUserRole(uid, 'admin');

    if (!anonymized && !isAdmin) {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can access unanonymized data');
    }

    const collectionName = anonymized ? 'analytics_events' : 'analytics_events_private';
    let query: admin.firestore.Query = db.collection(collectionName);

    if (dateRange) {
      query = query.where('timestamp', '>=', admin.firestore.Timestamp.fromDate(dateRange.start));
      query = query.where('timestamp', '<=', admin.firestore.Timestamp.fromDate(dateRange.end));
    }

    if (feature) {
      query = query.where('feature', '==', feature);
    }

    const snapshot = await query.get();
    const events: any[] = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const userKeyFor = (e: any): string | null => {
      const id = anonymized ? e.anonUserId : e.uid;
      return typeof id === 'string' && id ? id : null;
    };
    const eventNameOf = (e: any): string => String(e.eventName || 'unknown');
    const featureOf = (e: any): string => String(e.feature || 'unknown');
    const tsMillisOf = (e: any): number | null => {
      const t = e.timestamp;
      if (t && typeof t.toDate === 'function') return t.toDate().getTime();
      const d = new Date(t || 0);
      return Number.isNaN(d.getTime()) ? null : d.getTime();
    };
    const metadataOf = (e: any): Record<string, any> =>
      e.metadata && typeof e.metadata === 'object' ? e.metadata : {};
    const safeNumber = (n: any): number | null =>
      typeof n === 'number' && Number.isFinite(n) ? n : null;

    const activeUsers = new Set(events.map(userKeyFor).filter(Boolean as any)).size;
    const featureUsage: Record<string, number> = {};
    const featureDurations: Record<string, number[]> = {};
    const eventCounts: Record<string, number> = {};

    const stageEvents = {
      awareness: new Set(['session_started', 'screen_view']),
      engagement: new Set(['learning_module_viewed', 'journal_entry_created', 'provider_search_initiated']),
      action: new Set(['visit_summary_created', 'birth_plan_completed', 'provider_contact_clicked']),
      reflection: new Set(['micro_measure_submitted', 'journal_mood_selected', 'confidence_signal_submitted']),
    };

    const highValue = new Set(['birth_plan_completed', 'provider_contact_clicked', 'visit_summary_created']);

    type UserStats = {
      sessions: number;
      screenViews: number;
      featureActions: number;
      highValueActions: number;
      stages: Set<string>;
      firstTs: number | null;
      lastTs: number | null;
      cohortType: string;
      trimester: string;
      confidenceSeries: Array<{ ts: number; score: number }>;
      providerSearches: number;
      providerContacts: number;
      providerViews: number;
      journalEntries: number;
      learningCompleted: number;
      birthPlanCompletedAt: number | null;
      firstLearningCompletedAt: number | null;
      firstSessionAt: number | null;
      firstProviderContactAt: number | null;
      firstVisitSummaryAt: number | null;
    };
    const byUser: Record<string, UserStats> = {};

    const ensureUser = (id: string): UserStats => {
      if (!byUser[id]) {
        byUser[id] = {
          sessions: 0,
          screenViews: 0,
          featureActions: 0,
          highValueActions: 0,
          stages: new Set<string>(),
          firstTs: null,
          lastTs: null,
          cohortType: 'unknown',
          trimester: 'unknown',
          confidenceSeries: [],
          providerSearches: 0,
          providerContacts: 0,
          providerViews: 0,
          journalEntries: 0,
          learningCompleted: 0,
          birthPlanCompletedAt: null,
          firstLearningCompletedAt: null,
          firstSessionAt: null,
          firstProviderContactAt: null,
          firstVisitSummaryAt: null,
        };
      }
      return byUser[id];
    };

    events.forEach((event: any) => {
      const feat = featureOf(event);
      const name = eventNameOf(event);
      featureUsage[feat] = (featureUsage[feat] || 0) + 1;
      eventCounts[name] = (eventCounts[name] || 0) + 1;

      if (event.durationMs) {
        if (!featureDurations[feat]) featureDurations[feat] = [];
        featureDurations[feat].push(event.durationMs);
      }

      const userId = userKeyFor(event);
      if (!userId) return;
      const s = ensureUser(userId);
      const ts = tsMillisOf(event);
      const meta = metadataOf(event);

      if (!s.cohortType && typeof meta.cohort_type === 'string') s.cohortType = meta.cohort_type;
      if (!s.trimester && typeof meta.trimester === 'string') s.trimester = meta.trimester;
      if (s.cohortType === 'unknown' && typeof (event as any).cohort_type === 'string') s.cohortType = (event as any).cohort_type;
      if (s.trimester === 'unknown' && typeof (event as any).trimester === 'string') s.trimester = (event as any).trimester;

      if (ts != null) {
        s.firstTs = s.firstTs == null ? ts : Math.min(s.firstTs, ts);
        s.lastTs = s.lastTs == null ? ts : Math.max(s.lastTs, ts);
      }

      if (name === 'session_started') {
        s.sessions += 1;
        if (ts != null && s.firstSessionAt == null) s.firstSessionAt = ts;
      } else if (name === 'screen_view') {
        s.screenViews += 1;
      } else {
        s.featureActions += 1;
      }

      if (highValue.has(name)) s.highValueActions += 1;
      if (stageEvents.awareness.has(name)) s.stages.add('awareness');
      if (stageEvents.engagement.has(name)) s.stages.add('engagement');
      if (stageEvents.action.has(name)) s.stages.add('action');
      if (stageEvents.reflection.has(name)) s.stages.add('reflection');

      if (name === 'provider_search_initiated') s.providerSearches += 1;
      if (name === 'provider_profile_viewed') s.providerViews += 1;
      if (name === 'provider_contact_clicked') {
        s.providerContacts += 1;
        if (ts != null && s.firstProviderContactAt == null) s.firstProviderContactAt = ts;
      }
      if (name === 'journal_entry_created') s.journalEntries += 1;
      if (name === 'learning_module_completed') {
        s.learningCompleted += 1;
        if (ts != null && s.firstLearningCompletedAt == null) s.firstLearningCompletedAt = ts;
      }
      if (name === 'birth_plan_completed' && ts != null && s.birthPlanCompletedAt == null) s.birthPlanCompletedAt = ts;
      if (name === 'visit_summary_created' && ts != null && s.firstVisitSummaryAt == null) s.firstVisitSummaryAt = ts;

      const confidence =
        safeNumber(meta.confidence_score) ??
        safeNumber(meta.confidence) ??
        safeNumber(meta.confidenceScore) ??
        safeNumber((event as any).confidence_score);
      if (ts != null && confidence != null) {
        s.confidenceSeries.push({ ts, score: confidence });
      }
    });

    const avgDurations: Record<string, number> = {};
    Object.keys(featureDurations).forEach(feat => {
      const durations = featureDurations[feat];
      avgDurations[feat] = durations.reduce((a, b) => a + b, 0) / durations.length;
    });

    const allFlatDurations = Object.values(featureDurations).flat();
    const avgDurationMs =
      allFlatDurations.length > 0
        ? allFlatDurations.reduce((a, b) => a + b, 0) / allFlatDurations.length
        : 0;

    const users = Object.values(byUser);
    const userCount = users.length || 1;

    const engagementScores = users.map((u) =>
      u.sessions * 1 + u.screenViews * 0.5 + u.featureActions * 3 + u.highValueActions * 5,
    );
    const avgEngagementScore =
      engagementScores.length > 0
        ? engagementScores.reduce((a, b) => a + b, 0) / engagementScores.length
        : 0;

    const engagementLevelCounts = { high: 0, medium: 0, low: 0 };
    engagementScores.forEach((score) => {
      if (score >= 40) engagementLevelCounts.high += 1;
      else if (score >= 15) engagementLevelCounts.medium += 1;
      else engagementLevelCounts.low += 1;
    });

    const newVsReturning = users.reduce(
      (acc, u) => {
        if (u.sessions > 1) acc.returning += 1;
        else acc.new += 1;
        return acc;
      },
      { new: 0, returning: 0 },
    );

    const trimesterBreakdown: Record<string, number> = {};
    const cohortBreakdown: Record<string, number> = {};
    users.forEach((u) => {
      trimesterBreakdown[u.trimester] = (trimesterBreakdown[u.trimester] || 0) + 1;
      cohortBreakdown[u.cohortType] = (cohortBreakdown[u.cohortType] || 0) + 1;
    });

    const stageUserCounts = { awareness: 0, engagement: 0, action: 0, reflection: 0, outcome: 0 };
    users.forEach((u) => {
      if (u.stages.has('awareness')) stageUserCounts.awareness += 1;
      if (u.stages.has('engagement')) stageUserCounts.engagement += 1;
      if (u.stages.has('action')) stageUserCounts.action += 1;
      if (u.stages.has('reflection')) stageUserCounts.reflection += 1;
      if (u.confidenceSeries.length >= 2 || u.highValueActions > 0) stageUserCounts.outcome += 1;
    });

    const confidenceDeltas = users
      .map((u) => {
        if (u.confidenceSeries.length < 2) return null;
        const sorted = [...u.confidenceSeries].sort((a, b) => a.ts - b.ts);
        return sorted[sorted.length - 1].score - sorted[0].score;
      })
      .filter((v): v is number => v != null);
    const avgConfidenceDelta =
      confidenceDeltas.length > 0
        ? confidenceDeltas.reduce((a, b) => a + b, 0) / confidenceDeltas.length
        : 0;
    const confidenceImprovedPct = Math.round((confidenceDeltas.filter((d) => d > 0).length / (confidenceDeltas.length || 1)) * 100);

    const understandingSignals = users
      .map((u) => {
        const latest = [...u.confidenceSeries].sort((a, b) => b.ts - a.ts)[0];
        return latest ? latest.score : null;
      })
      .filter((v): v is number => v != null);
    const understandingImprovedPct = Math.round(
      (understandingSignals.filter((s) => s >= 4).length / (understandingSignals.length || 1)) * 100,
    );

    const actionTakenPct = Math.round((users.filter((u) => u.highValueActions > 0).length / userCount) * 100);

    const visitSummaryCreated = eventCounts.visit_summary_created || 0;
    const providerContactClicked = eventCounts.provider_contact_clicked || 0;
    const providerSearchInitiated = eventCounts.provider_search_initiated || 0;
    const providerProfileViewed = eventCounts.provider_profile_viewed || 0;
    const communityPostCreated = eventCounts.community_post_created || 0;
    const communityPostReplied = eventCounts.community_post_replied || 0;
    const communityPostLiked = eventCounts.community_post_liked || 0;

    const usageRateVisitSummary = visitSummaryCreated / userCount;
    const followUpActionRate = visitSummaryCreated > 0 ? providerContactClicked / visitSummaryCreated : 0;
    const providerSearchSuccessRate =
      providerSearchInitiated > 0 ? providerContactClicked / providerSearchInitiated : 0;
    const providerExplorationDepth =
      providerSearchInitiated > 0 ? providerProfileViewed / providerSearchInitiated : 0;
    const postingRate = communityPostCreated / userCount;

    const timeToActionMinutes = users
      .map((u) =>
        u.firstSessionAt != null && u.firstProviderContactAt != null && u.firstProviderContactAt >= u.firstSessionAt
          ? (u.firstProviderContactAt - u.firstSessionAt) / 60000
          : null,
      )
      .filter((v): v is number => v != null);
    const avgTimeToActionMinutes =
      timeToActionMinutes.length > 0
        ? timeToActionMinutes.reduce((a, b) => a + b, 0) / timeToActionMinutes.length
        : 0;

    const learningToBirthPlanMins = users
      .map((u) =>
        u.firstLearningCompletedAt != null && u.birthPlanCompletedAt != null && u.birthPlanCompletedAt >= u.firstLearningCompletedAt
          ? (u.birthPlanCompletedAt - u.firstLearningCompletedAt) / 60000
          : null,
      )
      .filter((v): v is number => v != null);
    const avgLearningToBirthPlanMinutes =
      learningToBirthPlanMins.length > 0
        ? learningToBirthPlanMins.reduce((a, b) => a + b, 0) / learningToBirthPlanMins.length
        : 0;

    const confidenceWithJournal = users
      .filter((u) => u.journalEntries >= 2)
      .flatMap((u) => u.confidenceSeries.map((c) => c.score));
    const confidenceWithoutJournal = users
      .filter((u) => u.journalEntries === 0)
      .flatMap((u) => u.confidenceSeries.map((c) => c.score));
    const avg = (arr: number[]) => (arr.length ? arr.reduce((a, b) => a + b, 0) / arr.length : 0);
    const journalConfidenceLift = avg(confidenceWithJournal) - avg(confidenceWithoutJournal);

    const recommendations: string[] = [];
    if (providerSearchSuccessRate < 0.4) {
      recommendations.push('Provider search has significant drop-off before contact; add guided prompts after results.');
    }
    if (followUpActionRate < 0.5) {
      recommendations.push('Users create visit summaries but fewer continue to provider contact; add follow-up CTA after summary completion.');
    }
    if (journalConfidenceLift > 0.5) {
      recommendations.push('Users with 2+ journal entries show higher confidence; nudge users to journal earlier.');
    }
    if (recommendations.length === 0) {
      recommendations.push('Current journey is balanced; keep monitoring cohort-level variance by trimester and care pathway.');
    }

    return {
      activeUsers,
      featureUsage,
      avgDurations,
      avgDurationMs,
      totalEvents: events.length,
      eventCounts,
      holisticReport: {
        executiveSummary: {
          confidenceImprovedPct,
          understandingImprovedPct,
          actionTakenPct,
          highestPerformingFeatures: Object.entries(featureUsage)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 3)
            .map(([f]) => f),
        },
        cohortBreakdown: {
          trimester: trimesterBreakdown,
          cohortType: cohortBreakdown,
          engagementLevel: engagementLevelCounts,
          newVsReturning,
        },
        journeyFunnel: stageUserCounts,
        featurePerformance: [
          { feature: 'visit-summary', usageRate: usageRateVisitSummary, outcomeImpact: followUpActionRate, notes: 'Usage + follow-up action' },
          { feature: 'provider-search', usageRate: providerSearchSuccessRate, outcomeImpact: providerExplorationDepth, notes: 'Contact success and exploration depth' },
          { feature: 'community', usageRate: postingRate, outcomeImpact: (communityPostReplied + communityPostLiked) / (communityPostCreated || 1), notes: 'Posting and engagement per post' },
        ],
        engagementDepth: {
          averageScore: avgEngagementScore,
          formula: '(sessions*1) + (screen_views*0.5) + (feature_actions*3) + (high_value_actions*5)',
        },
        outcomeMetrics: {
          healthUnderstandingScore: understandingImprovedPct,
          selfAdvocacyScore: confidenceImprovedPct,
          careNavigationSuccess: Math.round(providerSearchSuccessRate * 100),
          carePreparationScore: avgLearningToBirthPlanMinutes > 0 ? Math.max(0, 100 - Math.round(avgLearningToBirthPlanMinutes / 10)) : 0,
          avgConfidenceDelta,
        },
        timeInsights: {
          avgTimeToActionMinutes,
          avgLearningToActionMinutes: avgLearningToBirthPlanMinutes,
        },
        behaviorCorrelations: {
          journalConfidenceLift,
          providerViewsPerSearch: providerExplorationDepth,
          usersWithLearningCompletionPct: Math.round((users.filter((u) => u.learningCompleted > 0).length / userCount) * 100),
        },
        recommendations,
      },
    };
  },
);

/**
 * Generate Report
 * Creates comprehensive reports with insights
 */
export const generateReport = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
    if (!request.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { reportType, anonymized, cohortType } = request.data || {};
    const dateRange = parseDateRange(request.data?.dateRange);
    const uid = request.auth.uid;

    const isAdmin = await checkUserRole(uid, 'admin');
    const isResearchPartner = await checkUserRole(uid, 'research_partner');

    if (!isAdmin && !isResearchPartner) {
      throw new functions.https.HttpsError('permission-denied', 'Insufficient permissions');
    }

    if (!anonymized && !isAdmin) {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can generate unanonymized reports');
    }

    const collectionName = anonymized ? 'analytics_events' : 'analytics_events_private';

    let query: admin.firestore.Query = db.collection(collectionName);
    if (dateRange) {
      query = query.where('timestamp', '>=', admin.firestore.Timestamp.fromDate(dateRange.start));
      query = query.where('timestamp', '<=', admin.firestore.Timestamp.fromDate(dateRange.end));
    }

    const snapshot = await query.get();
    const events = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const report = generateReportByType(reportType, events, cohortType);

    await db.collection('audit_logs').add({
      action: 'report_generated',
      reportType,
      anonymized,
      performedBy: uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return report;
  },
);

/**
 * Helper: Check user role
 */
async function checkUserRole(uid: string, role: string): Promise<boolean> {
  const roleCollections: Record<string, string> = {
    admin: 'ADMIN',
    research_partner: 'RESEARCH_PARTNERS',
    community_manager: 'COMMUNITY_MANAGERS',
  };

  const collectionName = roleCollections[role];
  if (!collectionName) return false;

  const doc = await db.collection(collectionName).doc(uid).get();
  return doc.exists;
}

/**
 * Resolve a Firebase Auth user by email (Admin SDK).
 * Callers must be admins. Used for role assignment when `users/{uid}` is not created yet.
 */
export const lookupAuthUserByEmail = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
    const auth = request.auth;
    const data = request.data;

    if (!auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const callerUid = auth.uid;
    const isAdmin = await checkUserRole(callerUid, 'admin');
    if (!isAdmin) {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can look up users by email');
    }

    const raw = typeof data?.email === 'string' ? data.email.trim() : '';
    if (!raw || !raw.includes('@')) {
      throw new functions.https.HttpsError('invalid-argument', 'A valid email address is required');
    }

    const normalized = raw.toLowerCase();

    try {
      const userRecord = await admin.auth().getUserByEmail(normalized);
      return {
        uid: userRecord.uid,
        email: userRecord.email || normalized,
        displayName: userRecord.displayName || undefined,
      };
    } catch (e: any) {
      if (e?.code === 'auth/user-not-found') {
        return null;
      }
      console.error('[lookupAuthUserByEmail]', e);
      throw new functions.https.HttpsError('internal', e?.message || 'Failed to look up user');
    }
  }
);

/**
 * Helper: Generate report by type
 */
function generateReportByType(
  reportType: string,
  events: any[],
  cohortType?: string
): any {
  // Simplified report generation - implement full logic per report type
  const rows = events.map(e => ({
    timestamp: e.timestamp,
    feature: e.feature,
    eventName: e.eventName,
    durationMs: e.durationMs,
  }));

  const kpis = {
    totalEvents: events.length,
    uniqueUsers: new Set(events.map(e => e.anonUserId || e.uid)).size,
    avgDuration: events
      .filter(e => e.durationMs)
      .reduce((sum, e) => sum + e.durationMs, 0) / events.filter(e => e.durationMs).length || 0,
  };

  const insights = [
    `Total of ${events.length} events recorded`,
    `${kpis.uniqueUsers} unique users engaged`,
    `Average session duration: ${Math.round(kpis.avgDuration / 1000)}s`,
  ];

  return {
    rows,
    kpis,
    charts: {
      series: [],
      labels: [],
    },
    insights,
  };
}

/**
 * Get Feature Analytics
 * Aggregates analytics data for a specific feature
 */
export const getFeatureAnalytics = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
    if (!request.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { featureId, anonymized = true } = request.data || {};
    const dateRange = parseDateRange(request.data?.dateRange);
    const uid = request.auth.uid;

  if (!featureId) {
    throw new functions.https.HttpsError('invalid-argument', 'featureId is required');
  }

  // Check user role
  const isAdmin = await checkUserRole(uid, 'admin');
  const isResearchPartner = await checkUserRole(uid, 'research_partner');
  const isCommunityManager = await checkUserRole(uid, 'community_manager');

  if (!isAdmin && !isResearchPartner && !isCommunityManager) {
    throw new functions.https.HttpsError('permission-denied', 'Insufficient permissions');
  }

  // Research partners can only access anonymized data
  if (!anonymized && !isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can access unanonymized data');
  }

  const collectionName = anonymized ? 'analytics_events' : 'analytics_events_private';
  
  // Build query for this feature
  let query: admin.firestore.Query = db.collection(collectionName)
    .where('feature', '==', featureId);

  if (dateRange) {
    query = query.where(
      'timestamp',
      '>=',
      admin.firestore.Timestamp.fromDate(dateRange.start),
    );
    query = query.where(
      'timestamp',
      '<=',
      admin.firestore.Timestamp.fromDate(dateRange.end),
    );
  }

  const snapshot = await query.get();
  const events: any[] = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

  // Get total user count for adoption rate calculation
  const totalUsersSnapshot = await db.collection('users').limit(1).get();
  const totalUsers = totalUsersSnapshot.size > 0 
    ? (await db.collection('users').count().get()).data().count 
    : 0;

  // Calculate active users (unique users in date range)
  const activeUsers = new Set(events.map((e: any) => anonymized ? e.anonUserId : e.uid)).size;

  // Calculate adoption rate
  const adoptionRate = totalUsers > 0 ? Math.round((activeUsers / totalUsers) * 100) : 0;

  // Calculate engagement trend (daily active users)
  const engagementTrendMap: Record<string, Set<string>> = {};
  events.forEach((event: any) => {
    const date = event.timestamp?.toDate();
    if (date) {
      const dateKey = date.toISOString().split('T')[0]; // YYYY-MM-DD
      if (!engagementTrendMap[dateKey]) {
        engagementTrendMap[dateKey] = new Set();
      }
      const userId = anonymized ? event.anonUserId : event.uid;
      if (userId) {
        engagementTrendMap[dateKey].add(userId);
      }
    }
  });

  const engagementTrend = Object.entries(engagementTrendMap)
    .map(([date, users]) => ({
      date: date.split('-').slice(1).join('/'), // MM/DD format
      value: users.size,
    }))
    .sort((a, b) => a.date.localeCompare(b.date));

  // Calculate usage by week
  const usageByWeekMap: Record<string, number> = {};
  events.forEach((event: any) => {
    const date = event.timestamp?.toDate();
    if (date) {
      const weekStart = new Date(date);
      weekStart.setDate(date.getDate() - date.getDay()); // Start of week (Sunday)
      const weekKey = `Week ${Math.ceil((weekStart.getTime() - new Date(weekStart.getFullYear(), 0, 1).getTime()) / (7 * 24 * 60 * 60 * 1000))}`;
      usageByWeekMap[weekKey] = (usageByWeekMap[weekKey] || 0) + 1;
    }
  });

  const usageByWeek = Object.entries(usageByWeekMap)
    .map(([week, sessions]) => ({ week, sessions }))
    .sort((a, b) => a.week.localeCompare(b.week));

  // Calculate KPIs (feature-specific metrics)
  const completionEvents = events.filter((e: any) => e.eventName === 'feature_completion' || e.eventName === 'feature_view_end');
  const exportEvents = events.filter((e: any) => e.eventName === 'feature_export');
  const viewStartEvents = events.filter((e: any) => e.eventName === 'feature_view_start');
  const durations = events.filter((e: any) => e.durationMs).map((e: any) => e.durationMs);

  const avgDuration = durations.length > 0
    ? durations.reduce((a, b) => a + b, 0) / durations.length
    : 0;

  const completionRate = viewStartEvents.length > 0
    ? Math.round((completionEvents.length / viewStartEvents.length) * 100 * 10) / 10
    : 0;

  const exportRate = viewStartEvents.length > 0
    ? Math.round((exportEvents.length / viewStartEvents.length) * 100 * 10) / 10
    : 0;

  const kpis = [
    {
      name: 'Completion Rate',
      value: `${completionRate}%`,
      trend: completionRate > 0 ? `+${completionRate}%` : '0%',
      target: '75%',
      impact: 'Measures how many users complete the feature workflow',
    },
    {
      name: 'Export Utilization',
      value: `${exportRate}%`,
      trend: exportRate > 0 ? `+${exportRate}%` : '0%',
      target: '50%',
      impact: 'Shows adoption of export/sharing capabilities',
    },
    {
      name: 'Average Duration',
      value: `${Math.round(avgDuration / 1000 / 60 * 10) / 10} min`,
      trend: avgDuration > 0 ? 'Active' : 'N/A',
      target: '10 min',
      impact: 'Average time users spend engaging with the feature',
    },
  ];

  return {
    activeUsers,
    adoptionRate,
    engagementTrend,
    usageByWeek,
    kpis,
    totalEvents: events.length,
  };
  },
);

/**
 * Update Feature
 * Admin-only function to update feature metadata
 */
export const updateFeature = functions.https.onCall({
  // Explicitly disable App Check enforcement - we only need user authentication
  enforceAppCheck: false,
}, async (request: functions.https.CallableRequest) => {
  console.log('[updateFeature] Request received');
  console.log('[updateFeature] Request.auth exists:', !!request?.auth);
  console.log('[updateFeature] Request.auth.uid:', request?.auth?.uid);
  console.log('[updateFeature] Request.data:', request?.data);
  
  if (!request || !request.auth) {
    console.error('[updateFeature] Authentication failed - request.auth is null');
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { featureId, updates } = request.data;
  const uid = request.auth.uid;

  if (!featureId || !updates) {
    throw new functions.https.HttpsError('invalid-argument', 'featureId and updates are required');
  }

  // Check if user is admin
  const isAdmin = await checkUserRole(uid, 'admin');
  if (!isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can update features');
  }

  const featureRef = db.collection('technology_features').doc(featureId);
  const featureDoc = await featureRef.get();

  if (!featureDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Feature not found');
  }

  const currentData = featureDoc.data();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Prepare update data
  const updateData: any = {
    ...updates,
    updatedAt: now,
    updatedBy: uid,
  };

  // Check if description or updateHighlight changed (for change history)
  const descriptionChanged = updates.description && updates.description !== currentData?.description;
  const highlightChanged = updates.updateHighlight && updates.updateHighlight !== currentData?.updateHighlight;

  // Update feature document
  await featureRef.update(updateData);

  // Add change history entry if description or highlight changed
  if (descriptionChanged || highlightChanged) {
    // Get latest release build number for version
    const latestReleaseSnapshot = await db.collection('releases')
      .orderBy('buildNumber', 'desc')
      .limit(1)
      .get();
    
    const latestRelease = latestReleaseSnapshot.empty ? null : latestReleaseSnapshot.docs[0].data();
    const version = latestRelease ? latestRelease.fullVersion : 'Unknown';

    await featureRef.collection('change_history').add({
      version,
      date: now,
      change: descriptionChanged 
        ? `Description updated: ${updates.description?.substring(0, 100)}...`
        : `Update highlight changed: ${updates.updateHighlight}`,
      releaseBuildNumber: latestRelease ? latestRelease.buildNumber : null,
      createdBy: uid,
    });
  }

  // Log audit event
  await db.collection('audit_logs').add({
    action: 'feature_updated',
    featureId,
    performedBy: uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, featureId };
});

/**
 * Process Feature Changes from FEATURES.md
 * Called from GitHub Actions to update feature descriptions and change history
 */
export const processFeatureChanges = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
  const data = request.data || {};
  // Allow unauthenticated calls from GitHub Actions (using secret token)
  const { 
    commitSha,
    commitMessage,
    commitDate,
    commitAuthor,
    secretToken,
    featuresMarkdown
  } = data;

  // Verify secret token if provided (for GitHub Actions)
  if (secretToken) {
    const githubSecretToken = defineString('GITHUB_SECRET_TOKEN');
    const expectedToken = githubSecretToken.value();
    if (!expectedToken || secretToken !== expectedToken) {
      throw new functions.https.HttpsError('permission-denied', 'Invalid secret token');
    }
  } else if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  if (!commitSha || !featuresMarkdown) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: commitSha, featuresMarkdown');
  }

  try {
    // Parse features from markdown
    const features = parseFeaturesMarkdown(featuresMarkdown);
    
    // Update features in Firestore
    const batch = db.batch();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const commitDateTimestamp = commitDate 
      ? admin.firestore.Timestamp.fromDate(new Date(commitDate))
      : now;

    for (const [featureId, featureData] of Object.entries(features)) {
      const featureRef = db.collection('technology_features').doc(featureId);
      
      // Get existing feature
      const featureDoc = await featureRef.get();
      const existingData: any = featureDoc.exists ? featureDoc.data() : {};
      
      // Update feature document
      const featureUpdate: any = {
        name: featureData.name,
        description: featureData.description,
        domain: getDomainFromFeatureId(featureId),
        status: existingData?.status || 'active',
        displayOrder: existingData?.displayOrder || getDefaultDisplayOrder(featureId),
        tags: existingData?.tags || [featureId],
        updatedAt: now,
        updatedBy: 'system',
        lastProcessedCommit: commitSha,
      };

      if (!featureDoc.exists) {
        featureUpdate.createdAt = now;
        featureUpdate.visible = true;
      }

      batch.set(featureRef, featureUpdate, { merge: true });
      
      // Add new change history entries
      const latestChanges = featureData.changeHistory.filter((change: any) => 
        !existingData?.lastProcessedCommit || 
        change.commitSha !== existingData.lastProcessedCommit
      );
      
      for (const change of latestChanges) {
        const changeRef = featureRef.collection('change_history').doc();
        batch.set(changeRef, {
          version: commitSha.substring(0, 7),
          date: commitDateTimestamp,
          change: change.description,
          title: change.title,
          commitSha: change.commitSha,
          commitMessage: commitMessage || '',
          commitAuthor: commitAuthor || 'system',
          releaseBuildNumber: null,
          createdBy: 'system',
          createdAt: now
        });
      }
    }

    await batch.commit();

    // Log audit event
    await db.collection('audit_logs').add({
      action: 'feature_changes_processed',
      commitSha,
      commitMessage: commitMessage || '',
      featuresUpdated: Object.keys(features).length,
      performedBy: request.auth?.uid || 'system',
      timestamp: now,
    });

    return { 
      success: true, 
      featuresUpdated: Object.keys(features).length,
      commitSha 
    };
  } catch (error: any) {
    console.error('Error processing feature changes:', error);
    throw new functions.https.HttpsError('internal', `Failed to process feature changes: ${error.message}`);
  }
  },
);

/**
 * Parse FEATURES.md markdown content
 */
function parseFeaturesMarkdown(content: string): Record<string, any> {
  const features: Record<string, any> = {};
  const sections = content.split(/^## \d+\. /m);
  
  console.log(`[parseFeaturesMarkdown] Found ${sections.length} sections after splitting`);
  
  // Map feature names to IDs
  const featureIdMap: Record<string, string> = {
    'Provider Search': 'provider-search',
    'Authentication and Onboarding': 'authentication-onboarding',
    'User Feedback': 'user-feedback',
    'Appointment Summarizing': 'appointment-summarizing',
    'Journal': 'journal',
    'Learning Modules': 'learning-modules',
    'Birth Plan Generator': 'birth-plan-generator',
    'Community': 'community',
    'Profile Editing': 'profile-editing'
  };
  
  sections.forEach((section, index) => {
    if (index === 0) return; // Skip header
    
    const lines = section.split('\n');
    const featureName = lines[0].trim();
    const featureId = featureIdMap[featureName] || featureName.toLowerCase().replace(/\s+/g, '-');
    
    console.log(`[parseFeaturesMarkdown] Processing section ${index}: featureName="${featureName}", featureId="${featureId}"`);
    
    let currentSection = '';
    let description = '';
    let howItWorks = '';
    const changeHistory: any[] = [];
    const recentUpdates: string[] = [];
    
    for (let i = 1; i < lines.length; i++) {
      const line = lines[i].trim();
      
      if (line === '### Current Functionality') {
        currentSection = 'functionality';
        howItWorks = ''; // Reset
      } else if (line === '### Change History') {
        currentSection = 'changes';
      } else if (line.startsWith('---')) {
        // End of section
        break;
      } else if (line.startsWith('- **') && currentSection === 'changes') {
        // Parse: - **[Date]** - **[Commit SHA]** - **[Title]**: [Description]
        // Or: - **[Date]** - **[Title]**: [Description] (without commit SHA)
        // Note: Commit SHA can be any alphanumeric string (not just hex) for mock/test values
        const matchWithCommit = line.match(/^- \*\*(\d{4}-\d{2}-\d{2})\*\* - \*\*([a-zA-Z0-9]+)\*\* - \*\*([^\*]+)\*\*: (.+)$/);
        const matchWithoutCommit = line.match(/^- \*\*(\d{4}-\d{2}-\d{2})\*\* - \*\*([^\*]+)\*\*: (.+)$/);
        
        if (matchWithCommit) {
          const updateText = `${matchWithCommit[3]}: ${matchWithCommit[4]}`;
          changeHistory.push({
            date: matchWithCommit[1],
            commitSha: matchWithCommit[2],
            title: matchWithCommit[3],
            description: matchWithCommit[4]
          });
          recentUpdates.push(updateText);
        } else if (matchWithoutCommit) {
          const updateText = `${matchWithoutCommit[2]}: ${matchWithoutCommit[3]}`;
          changeHistory.push({
            date: matchWithoutCommit[1],
            commitSha: null,
            title: matchWithoutCommit[2],
            description: matchWithoutCommit[3]
          });
          recentUpdates.push(updateText);
        } else if (line.startsWith('- *No changes tracked yet*')) {
          // Skip "No changes tracked yet" entries
        } else {
          // Log lines that don't match for debugging
          console.log(`[parseFeaturesMarkdown] Line did not match regex for feature ${featureId}:`, line);
        }
      } else if (currentSection === 'functionality' && line && !line.startsWith('---')) {
        // Collect "How the feature works" from Current Functionality section
        howItWorks += (howItWorks ? '\n' : '') + line;
      } else if (currentSection === 'description' && line && !line.startsWith('---')) {
        description += (description ? '\n' : '') + line;
      }
    }
    
    features[featureId] = {
      name: featureName,
      description: description.trim(),
      howItWorks: howItWorks.trim(), // Extract "How the feature works"
      recentUpdates: recentUpdates, // Extract recent updates
      changeHistory: changeHistory
    };
    
    console.log(`[parseFeaturesMarkdown] Added feature ${featureId}:`, {
      hasHowItWorks: !!howItWorks.trim(),
      howItWorksLength: howItWorks.trim().length,
      recentUpdatesCount: recentUpdates.length,
      changeHistoryCount: changeHistory.length
    });
  });
  
  console.log(`[parseFeaturesMarkdown] Returning ${Object.keys(features).length} features:`, Object.keys(features));
  return features;
}

/**
 * Get domain from feature ID
 */
function getDomainFromFeatureId(featureId: string): string {
  const domainMap: Record<string, string> = {
    'provider-search': 'Care Navigation',
    'authentication-onboarding': 'User Experience',
    'user-feedback': 'User Engagement',
    'appointment-summarizing': 'Care Understanding',
    'journal': 'Self-Reflection',
    'learning-modules': 'Care Preparation',
    'birth-plan-generator': 'Care Preparation',
    'community': 'Community Support',
    'profile-editing': 'User Experience'
  };
  
  return domainMap[featureId] || 'Other';
}

/**
 * Get default display order for feature
 */
function getDefaultDisplayOrder(featureId: string): number {
  const orderMap: Record<string, number> = {
    'provider-search': 1,
    'authentication-onboarding': 2,
    'user-feedback': 3,
    'appointment-summarizing': 4,
    'journal': 5,
    'learning-modules': 6,
    'birth-plan-generator': 7,
    'community': 8,
    'profile-editing': 9
  };
  
  return orderMap[featureId] || 999;
}

/**
 * Publish Release
 * Called from GitHub Actions to publish a new release
 * Handles both pilot (push to main) and production (tag prod-v*) releases
 */
// Define secret at module level
const githubSecretToken = defineSecret('GITHUB_SECRET_TOKEN');

export const publishRelease = functions.https.onRequest({
  secrets: [githubSecretToken]
}, async (req, res) => {
  // Handle CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    // Extract the actual payload (from {data: {...}} or direct)
    const payload = req.body?.data || req.body;
  
    console.log('[publishRelease] Received request:', {
      hasDataWrapper: !!req.body?.data,
      commitSha: payload?.commitSha,
      hasSecretToken: !!payload?.secretToken,
      hasFeaturesMarkdown: !!payload?.featuresMarkdown,
      featuresMarkdownLength: payload?.featuresMarkdown?.length || 0,
      featuresMarkdownPreview: payload?.featuresMarkdown?.substring(0, 100) || 'none'
    });
    // #region agent log
    fetch('http://127.0.0.1:7243/ingest/ddaaaa74-c4f8-4176-b507-91d3bb5b2296',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'cf9ac6'},body:JSON.stringify({sessionId:'cf9ac6',runId:'publish-release-1',hypothesisId:'H5',location:'admindash/functions/src/index.ts:publishRelease:request',message:'publishRelease payload received',data:{hasDataWrapper:!!req.body?.data,hasFeaturesMarkdown:!!payload?.featuresMarkdown,featuresMarkdownLength:payload?.featuresMarkdown?.length||0,commitSha:payload?.commitSha||null},timestamp:Date.now()})}).catch(()=>{});
    // #endregion
  
    // Allow unauthenticated calls from GitHub Actions (using secret token)
    const { 
      pubspecVersionLine, 
      commitSha, 
      branch, 
      gitTag, 
      featureDossierJson, 
      environment,
      railwayDeployment,
      secretToken,
      commitMessage,
      commitAuthor,
      commitDate,
      featuresMarkdown  // FEATURES.md content
    } = payload;

    // Verify secret token if provided (for GitHub Actions)
    if (secretToken) {
      const expectedToken = githubSecretToken.value();
      console.log('[publishRelease] Token validation:', {
        hasReceivedToken: !!secretToken,
        receivedTokenLength: secretToken?.length || 0,
        receivedTokenPrefix: secretToken?.substring(0, 10) || 'none',
        hasExpectedToken: !!expectedToken,
        expectedTokenLength: expectedToken?.length || 0,
        expectedTokenPrefix: expectedToken?.substring(0, 10) || 'none',
        tokensMatch: secretToken === expectedToken
      });
      if (!expectedToken || secretToken !== expectedToken) {
        throw { code: 'permission-denied', message: 'Invalid secret token' };
      }
    } else {
      // If no secret token, require authentication (check Authorization header)
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw { code: 'unauthenticated', message: 'Authentication required' };
      }
    }

    if (!pubspecVersionLine || !commitSha || !featureDossierJson) {
      throw { code: 'invalid-argument', message: 'Missing required fields' };
    }

    // Parse version from pubspec.yaml line (e.g., "version: 1.2.3+13")
    const versionMatch = pubspecVersionLine.match(/version:\s*(\d+\.\d+\.\d+)\+(\d+)/);
    if (!versionMatch) {
      throw { code: 'invalid-argument', message: 'Invalid version format in pubspec.yaml' };
    }

  const versionName = versionMatch[1];
  const buildNumber = parseInt(versionMatch[2], 10);
  const fullVersion = `${versionName}+${buildNumber}`;

  // Determine channel based on git tag or branch
  let channel: 'pilot' | 'production' = 'pilot';
  if (gitTag && gitTag.startsWith('prod-v')) {
    channel = 'production';
  } else if (branch === 'production') {
    channel = 'production';
  }

    // Parse feature dossier
    let featureDossier;
    try {
      featureDossier = typeof featureDossierJson === 'string' 
        ? JSON.parse(featureDossierJson) 
        : featureDossierJson;
    } catch (e) {
      throw { code: 'invalid-argument', message: 'Invalid featureDossierJson format' };
    }

  // Build git info
  const repoUrl = 'https://github.com/The-culture-connection/empowerhealth.git';
  const gitInfo = {
    repoUrl,
    commitSha,
    branch: branch || 'main',
    tag: gitTag || null,
    compareUrl: gitTag 
      ? `${repoUrl}/compare/${gitTag}...main`
      : `${repoUrl}/compare/${commitSha}...main`,
    commitUrl: `${repoUrl}/commit/${commitSha}`,
    commitMessage: commitMessage || '',
    commitAuthor: commitAuthor || '',
    commitDate: commitDate ? admin.firestore.Timestamp.fromDate(new Date(commitDate)) : admin.firestore.FieldValue.serverTimestamp(),
  };

  // Build railway info
  const railwayInfo = railwayDeployment ? {
    environment: environment || 'pilot',
    deploymentId: railwayDeployment.deploymentId || null,
    deploymentUrl: railwayDeployment.deploymentUrl || null,
    status: railwayDeployment.status || 'success',
    deployedAt: railwayDeployment.deployedAt 
      ? admin.firestore.Timestamp.fromDate(new Date(railwayDeployment.deployedAt))
      : admin.firestore.FieldValue.serverTimestamp(),
  } : null;

  // Extract functional updates from featureDossier.categories
  const functionalUpdates: Record<string, any[]> = {};
  if (featureDossier.categories && Array.isArray(featureDossier.categories)) {
    featureDossier.categories.forEach((category: any) => {
      const domainKey = category.name?.toLowerCase().replace(/\s+/g, '-') || 'other';
      if (!functionalUpdates[domainKey]) {
        functionalUpdates[domainKey] = [];
      }
      if (category.items && Array.isArray(category.items)) {
        category.items.forEach((item: any) => {
          functionalUpdates[domainKey].push({
            name: item.name || 'Unnamed Update',
            description: item.description || '',
            domain: category.name || 'Other',
          });
        });
      }
    });
  }

    // Create release document
    const releaseDoc = {
      fullVersion,
      versionName,
      buildNumber,
      channel,
      git: gitInfo,
      railway: railwayInfo,
      featureDossier,
      functionalUpdates, // Add extracted functional updates
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: 'system', // GitHub Actions calls are unauthenticated
    };

    // Upsert to releases collection (docId = buildNumber)
    await db.collection('releases').doc(buildNumber.toString()).set(releaseDoc, { merge: true });

    // Also create a commit tracking document for this commit
    console.log('[publishRelease] Creating commit document:', commitSha);
    await db.collection('commits').doc(commitSha).set({
      commitSha,
      commitMessage: commitMessage || '',
      commitAuthor: commitAuthor || '',
      commitDate: commitDate ? admin.firestore.Timestamp.fromDate(new Date(commitDate)) : admin.firestore.FieldValue.serverTimestamp(),
      branch: branch || 'main',
      gitTag: gitTag || null,
      buildNumber,
      fullVersion,
      channel,
      releaseDocId: buildNumber.toString(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log('[publishRelease] Commit document created successfully:', commitSha);

    // Process FEATURES.md if provided (extract "How the feature works" and "Updates")
    console.log('[publishRelease] Checking featuresMarkdown:', {
      hasFeaturesMarkdown: !!featuresMarkdown,
      type: typeof featuresMarkdown,
      length: featuresMarkdown?.length || 0,
      isEmpty: !featuresMarkdown || featuresMarkdown.trim().length === 0
    });
    
    if (featuresMarkdown && featuresMarkdown.trim().length > 0) {
      try {
        console.log('[publishRelease] Processing FEATURES.md content, length:', featuresMarkdown.length);
        const features = parseFeaturesMarkdown(featuresMarkdown);
        console.log(`[publishRelease] Parsed ${Object.keys(features).length} features from FEATURES.md`);
        // #region agent log
        fetch('http://127.0.0.1:7243/ingest/ddaaaa74-c4f8-4176-b507-91d3bb5b2296',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'cf9ac6'},body:JSON.stringify({sessionId:'cf9ac6',runId:'publish-release-1',hypothesisId:'H6',location:'admindash/functions/src/index.ts:publishRelease:parseFeatures',message:'Parsed FEATURES.md into feature map',data:{featureCount:Object.keys(features).length,featureIds:Object.keys(features).slice(0,12)},timestamp:Date.now()})}).catch(()=>{});
        // #endregion
        
        for (const [featureId, featureData] of Object.entries(features)) {
          console.log(`[publishRelease] Processing feature ${featureId}:`, {
            name: featureData.name,
            hasHowItWorks: !!featureData.howItWorks,
            howItWorksLength: featureData.howItWorks?.length || 0,
            recentUpdatesCount: featureData.recentUpdates?.length || 0
          });
          const featureRef = db.collection('technology_features').doc(featureId);
          const featureDoc = await featureRef.get();
          const existingData: any = featureDoc.exists ? featureDoc.data() : {};
          
          const now = admin.firestore.FieldValue.serverTimestamp();
          const featureUpdate: any = {
            name: featureData.name,
            description: featureData.description || existingData?.description || '',
            howItWorks: featureData.howItWorks || existingData?.howItWorks || '', // Update "How the feature works"
            domain: getDomainFromFeatureId(featureId),
            status: existingData?.status || 'active',
            displayOrder: existingData?.displayOrder || getDefaultDisplayOrder(featureId),
            tags: existingData?.tags || [featureId],
            updatedAt: now,
            updatedBy: 'system',
            lastProcessedCommit: commitSha,
          };
          
          // Update recentUpdates array (keep existing + add new ones, limit to last 10)
          // Tag updates with channel (production/pilot) for tracking
          const existingUpdates = existingData?.recentUpdates || [];
          const newUpdates = featureData.recentUpdates || [];
          // Tag new updates with channel
          const taggedNewUpdates = newUpdates.map((update: string) => {
            // Add channel tag if not already present
            if (channel === 'production' && !update.includes('[production]')) {
              return `[production] ${update}`;
            } else if (channel === 'pilot' && !update.includes('[pilot]') && !update.includes('[production]')) {
              return `[pilot] ${update}`;
            }
            return update;
          });
          // Combine and deduplicate, keeping most recent
          const allUpdates = [...taggedNewUpdates, ...existingUpdates];
          const uniqueUpdates = Array.from(new Set(allUpdates)); // Simple deduplication
          featureUpdate.recentUpdates = uniqueUpdates.slice(0, 10); // Keep last 10 updates
          
          if (!featureDoc.exists) {
            featureUpdate.createdAt = now;
            featureUpdate.visible = true;
          }
          
          await featureRef.set(featureUpdate, { merge: true });
          console.log(`[publishRelease] Updated feature ${featureId} with howItWorks and recentUpdates`);
          // #region agent log
          fetch('http://127.0.0.1:7243/ingest/ddaaaa74-c4f8-4176-b507-91d3bb5b2296',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'cf9ac6'},body:JSON.stringify({sessionId:'cf9ac6',runId:'publish-release-1',hypothesisId:'H7',location:'admindash/functions/src/index.ts:publishRelease:updateFeature',message:'Upserted technology_features doc',data:{featureId,recentUpdatesCount:Array.isArray(featureUpdate.recentUpdates)?featureUpdate.recentUpdates.length:0,howItWorksLength:typeof featureUpdate.howItWorks==='string'?featureUpdate.howItWorks.length:0,lastProcessedCommit:featureUpdate.lastProcessedCommit||null},timestamp:Date.now()})}).catch(()=>{});
          // #endregion
          
          // Add change history entries for new changes
          if (featureData.changeHistory && featureData.changeHistory.length > 0) {
            const latestChanges = featureData.changeHistory.filter((change: any) => 
              !existingData?.lastProcessedCommit || 
              change.commitSha !== existingData.lastProcessedCommit
            );
            
            for (const change of latestChanges) {
              await featureRef.collection('change_history').add({
                version: commitSha.substring(0, 7),
                date: commitDate ? admin.firestore.Timestamp.fromDate(new Date(commitDate)) : now,
                change: change.description,
                title: change.title,
                commitSha: change.commitSha,
                commitMessage: commitMessage || '',
                commitAuthor: commitAuthor || 'system',
                releaseBuildNumber: buildNumber,
                createdBy: 'system',
                createdAt: now
              });
            }
          }
        }
        console.log('[publishRelease] Successfully processed FEATURES.md');
      } catch (error: any) {
        console.error('[publishRelease] Error processing FEATURES.md:', error);
        // #region agent log
        fetch('http://127.0.0.1:7243/ingest/ddaaaa74-c4f8-4176-b507-91d3bb5b2296',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'cf9ac6'},body:JSON.stringify({sessionId:'cf9ac6',runId:'publish-release-1',hypothesisId:'H8',location:'admindash/functions/src/index.ts:publishRelease:catchFeatures',message:'FEATURES.md processing failed',data:{error:error?.message||'unknown'},timestamp:Date.now()})}).catch(()=>{});
        // #endregion
        // Don't fail the entire release if FEATURES.md parsing fails
      }
    }

    // Auto-create/update technology_features documents based on dossier categories
    // This ensures features exist even if FEATURES.md is not processed
    if (featureDossier.categories && Array.isArray(featureDossier.categories)) {
      const featureIdMap: Record<string, string> = {
        'After Visit Summary': 'appointment-summarizing',
        'Learning Modules': 'learning-modules',
        'Provider Search': 'provider-search',
        'Community': 'community',
        'Journal': 'journal',
        'Birth Plan': 'birth-plan-generator',
        'Notifications': 'notifications',
        'Admin': 'admin',
        'User Feedback': 'user-feedback',
        'Authentication': 'authentication-onboarding',
        'Profile': 'profile-editing',
      };

      const domainMap: Record<string, string> = {
        'After Visit Summary': 'Care Understanding',
        'Learning Modules': 'Care Preparation',
        'Provider Search': 'Care Navigation',
        'Community': 'Community Support',
        'Journal': 'Self-Reflection',
        'Birth Plan': 'Care Preparation',
        'Notifications': 'Care Navigation',
        'Admin': 'Admin',
      };

      for (const category of featureDossier.categories) {
        const categoryName = category.name || 'Other';
        const featureId = featureIdMap[categoryName] || categoryName.toLowerCase().replace(/\s+/g, '-');
        const domain = domainMap[categoryName] || 'Other';

        const featureRef = db.collection('technology_features').doc(featureId);
        const featureDoc = await featureRef.get();
        const existingData: any = featureDoc.exists ? featureDoc.data() : {};

        const now = admin.firestore.FieldValue.serverTimestamp();
        const featureData: any = {
          id: featureId,
          name: categoryName,
          domain,
          category: categoryName,
          description: existingData?.description || featureDoc.exists 
            ? featureDoc.data()?.description || `Feature updates in ${categoryName}`
            : `Feature updates in ${categoryName}`,
          // Preserve howItWorks and recentUpdates if they exist (from FEATURES.md processing)
          howItWorks: existingData?.howItWorks || '',
          recentUpdates: existingData?.recentUpdates || [],
          lastUpdated: now,
          visible: true,
          displayOrder: existingData?.displayOrder || (Object.keys(featureIdMap).indexOf(categoryName) >= 0 
            ? Object.keys(featureIdMap).indexOf(categoryName) 
            : 999),
          tags: existingData?.tags || [categoryName.toLowerCase().replace(/\s+/g, '-')],
          updatedAt: now,
          updatedBy: 'system',
        };

        if (!featureDoc.exists) {
          featureData.createdAt = now;
        }

        await featureRef.set(featureData, { merge: true });
        console.log(`[publishRelease] Created/updated feature ${featureId} from dossier`);

      // Add change history entry for each feature item in this category
      if (category.items && Array.isArray(category.items)) {
        for (const item of category.items) {
          await featureRef.collection('change_history').add({
            version: fullVersion,
            date: now,
            change: item.description || item.name || 'Feature updated',
            releaseBuildNumber: buildNumber,
            createdBy: 'system',
          });
        }
      }
    }
  }

    // Log audit event
    await db.collection('audit_logs').add({
      action: 'release_published',
      buildNumber,
      fullVersion,
      channel,
      gitTag: gitTag || null,
      performedBy: 'system',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('[publishRelease] Function completed successfully:', {
      buildNumber,
      fullVersion,
      channel,
      commitSha
    });

    res.status(200).json({ 
      result: { 
        success: true, 
        buildNumber, 
        channel, 
        fullVersion, 
        commitSha 
      } 
    });
  } catch (error: any) {
    console.error('[publishRelease] Error:', error);
    const statusCode = error.code === 'permission-denied' ? 403 :
                      error.code === 'invalid-argument' ? 400 :
                      error.code === 'unauthenticated' ? 401 : 500;
    res.status(statusCode).json({ 
      error: {
        code: error.code || 'internal',
        message: error.message || 'Internal server error'
      }
    });
  }
});

/**
 * Poll System Health
 * Scheduled function that checks system health every 5 minutes
 */
export const pollSystemHealth = functionsV1.pubsub.schedule('every 5 minutes').onRun(async (context: any) => {
  const checks = await performHealthChecks();
  
  // Write results to system_health collection
  for (const [serviceKey, health] of Object.entries(checks)) {
    await db.collection('system_health').doc(serviceKey).set({
      name: health.name,
      status: health.status,
      lastCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastHealthyAt: health.status === 'operational' 
        ? admin.firestore.FieldValue.serverTimestamp()
        : admin.firestore.FieldValue.serverTimestamp(), // Keep existing if not operational
      details: health.details,
      metrics: health.metrics || {},
    }, { merge: true });
  }

  return null;
});

/**
 * Run Health Check Now
 * Manual health check trigger (Admin only)
 */
export const runHealthCheckNow = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = request.auth.uid;
  const isAdmin = await checkUserRole(uid, 'admin');
  
  if (!isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can trigger health checks');
  }

  const checks = await performHealthChecks();
  
  // Write results to system_health collection
  for (const [serviceKey, health] of Object.entries(checks)) {
    await db.collection('system_health').doc(serviceKey).set({
      name: health.name,
      status: health.status,
      lastCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastHealthyAt: health.status === 'operational' 
        ? admin.firestore.FieldValue.serverTimestamp()
        : admin.firestore.FieldValue.serverTimestamp(),
      details: health.details,
      metrics: health.metrics || {},
    }, { merge: true });
  }

  // Log audit event
  await db.collection('audit_logs').add({
    action: 'health_check_triggered',
    performedBy: uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, checks };
  },
);

/**
 * Perform Health Checks
 * Checks various system components
 */
async function performHealthChecks(): Promise<Record<string, any>> {
  const checks: Record<string, any> = {};

  // Check Railway API
  const railwayHealthUrl = defineString('RAILWAY_HEALTH_URL', { default: 'https://api.railway.app/health' });
  let railwayUrl = railwayHealthUrl.value();
  try {
    const startTime = Date.now();
    // Use node-fetch for Node.js environment
    const nodeFetch = require('node-fetch');
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const response = await nodeFetch(railwayUrl, { 
      method: 'GET', 
      signal: controller.signal
    });
    clearTimeout(timeout);
    const latency = Date.now() - startTime;
    
    checks.railway_api = {
      name: 'Railway API',
      status: response.ok ? 'operational' : 'degraded',
      details: {
        message: response.ok ? 'Railway API responding' : 'Railway API returned error',
        latencyMs: latency,
        errorCode: response.ok ? null : response.status,
        url: railwayUrl,
      },
      metrics: {
        latencyMs: latency,
      },
    };
  } catch (error: any) {
    checks.railway_api = {
      name: 'Railway API',
      status: 'down',
      details: {
        message: `Railway API check failed: ${error.message}`,
        latencyMs: null,
        errorCode: 'TIMEOUT',
        url: railwayUrl,
      },
    };
  }

  // Check Firebase (read test)
  try {
    const startTime = Date.now();
    await db.collection('system_health').doc('_test').get();
    const latency = Date.now() - startTime;
    
    checks.firebase = {
      name: 'Firebase',
      status: 'operational',
      details: {
        message: 'Database and auth running smoothly',
        latencyMs: latency,
        errorCode: null,
        url: null,
      },
      metrics: {
        latencyMs: latency,
      },
    };
  } catch (error: any) {
    checks.firebase = {
      name: 'Firebase',
      status: 'degraded',
      details: {
        message: `Firebase check failed: ${error.message}`,
        latencyMs: null,
        errorCode: 'ERROR',
        url: null,
      },
    };
  }

  // Check Analytics Jobs (check last run time)
  try {
    const analyticsSnapshot = await db.collection('analytics_daily')
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();
    
    const lastRun = analyticsSnapshot.empty 
      ? null 
      : analyticsSnapshot.docs[0].data().createdAt?.toDate();
    
    const hoursSinceLastRun = lastRun 
      ? (Date.now() - lastRun.getTime()) / (1000 * 60 * 60)
      : Infinity;
    
    checks.analytics_jobs = {
      name: 'Analytics Jobs',
      status: hoursSinceLastRun < 24 ? 'operational' : hoursSinceLastRun < 48 ? 'degraded' : 'down',
      details: {
        message: lastRun 
          ? `Last job completed ${Math.round(hoursSinceLastRun)} hours ago`
          : 'No analytics jobs found',
        latencyMs: null,
        errorCode: null,
        url: null,
      },
      metrics: {
        lastJobRunAt: lastRun,
      },
    };
  } catch (error: any) {
    checks.analytics_jobs = {
      name: 'Analytics Jobs',
      status: 'degraded',
      details: {
        message: `Analytics job check failed: ${error.message}`,
        latencyMs: null,
        errorCode: 'ERROR',
        url: null,
      },
    };
  }

  // Check Notification Queue (FCM sender)
  try {
    const notificationsSnapshot = await db.collection('notification_logs')
      .where('status', '==', 'pending')
      .limit(1)
      .get();
    
    const queueDepth = notificationsSnapshot.size;
    
    checks.fcm_sender = {
      name: 'Notification Pipeline',
      status: queueDepth < 100 ? 'operational' : queueDepth < 500 ? 'degraded' : 'down',
      details: {
        message: queueDepth === 0 
          ? 'Queue processing normally'
          : `${queueDepth} notifications pending`,
        latencyMs: null,
        errorCode: null,
        url: null,
      },
      metrics: {
        queueDepth,
      },
    };
  } catch (error: any) {
    checks.fcm_sender = {
      name: 'Notification Pipeline',
      status: 'degraded',
      details: {
        message: `Notification queue check failed: ${error.message}`,
        latencyMs: null,
        errorCode: 'ERROR',
        url: null,
      },
    };
  }

  return checks;
}

export { exportResearchDataset, getResearchDashboardSummary } from './research/researchExport';

export {
  createResearchParticipant,
  deriveAgeGroup,
  submitBaselineResearchData,
  validateResearchBaseline,
} from './research/researchIdentity';

export { submitMicroMeasure, validateMicroMeasure } from './research/researchMicroMeasure';

export { submitNeedsChecklist, validateNeedsChecklist } from './research/researchNeedsChecklist';

export {
  linkOutcomeToNeedsEvent,
  submitNavigationOutcome,
  validateNavigationOutcome,
} from './research/researchNavigationOutcome';

export {
  getMilestoneTrackerSummary,
  scheduleMilestonePrompt,
  submitMilestoneCheckIn,
  validateMilestoneCheckIn,
} from './research/researchMilestone';

export {
  recordAvsUploadActivity,
  recordHealthMadeSimpleAccess,
  recordModuleCompletion,
  recordProviderReviewActivity,
} from './research/researchAppActivity';

export { onAnalyticsEventCreated } from './analyticsAggregation';

export {
  onLearningModuleCreated,
  onCommunityPostUpdated,
  onCommunityPostCreated,
  scheduledWeeklyTodoReminders,
  scheduledTrimesterTransitionCheck,
  scheduledBirthHospitalBasicsReminder,
} from './pushNotifications';

export { sendNotification, getNotificationLogs } from './notificationDashboard';