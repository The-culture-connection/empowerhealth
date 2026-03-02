/**
 * Firebase Cloud Functions for EmpowerHealth Admin Dashboard
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

/**
 * Upload Build Version
 * Called from CI/CD or manual script to upload build version info
 */
export const uploadBuildVersion = functions.https.onCall(async (data, context) => {
  // Verify caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { fullVersion, commitHash, featureDossier } = data;

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
    createdBy: context.auth.uid,
  };

  await db.collection('build_versions').doc(buildNumber.toString()).set(buildVersionDoc);

  // Log audit event
  await db.collection('audit_logs').add({
    action: 'build_version_uploaded',
    buildNumber,
    fullVersion,
    performedBy: context.auth.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, buildNumber };
});

/**
 * Log Analytics Event
 * Handles anonymization server-side
 */
export const logAnalyticsEvent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { eventName, feature, metadata, durationMs, sessionId } = data;
  const uid = context.auth.uid;

  // Generate anonymized user ID (salted hash)
  const crypto = require('crypto');
  const salt = functions.config().analytics?.salt || 'default-salt-change-in-production';
  const anonUserId = crypto
    .createHash('sha256')
    .update(uid + salt)
    .digest('hex')
    .substring(0, 16);

  const timestamp = admin.firestore.FieldValue.serverTimestamp();

  // Write anonymized event
  const anonEvent = {
    anonUserId,
    eventName,
    feature,
    metadata: metadata || {},
    durationMs: durationMs || null,
    sessionId: sessionId || null,
    timestamp,
  };

  await db.collection('analytics_events').add(anonEvent);

  // Write private event (Admin only)
  const privateEvent = {
    uid,
    anonUserId,
    eventName,
    feature,
    metadata: metadata || {},
    durationMs: durationMs || null,
    sessionId: sessionId || null,
    timestamp,
  };

  await db.collection('analytics_events_private').add(privateEvent);

  return { success: true };
});

/**
 * Get Analytics Data
 * Aggregates analytics data with role-based access
 */
export const getAnalyticsData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { dateRange, feature, anonymized = true } = data;
  const uid = context.auth.uid;

  // Check user role
  const isAdmin = await checkUserRole(uid, 'admin');
  const isResearchPartner = await checkUserRole(uid, 'research_partner');

  // Research partners can only access anonymized data
  if (!anonymized && !isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can access unanonymized data');
  }

  const collectionName = anonymized ? 'analytics_events' : 'analytics_events_private';
  let query: admin.firestore.Query = db.collection(collectionName);

  if (dateRange) {
    query = query.where('timestamp', '>=', admin.firestore.Timestamp.fromDate(new Date(dateRange.start)));
    query = query.where('timestamp', '<=', admin.firestore.Timestamp.fromDate(new Date(dateRange.end)));
  }

  if (feature) {
    query = query.where('feature', '==', feature);
  }

  const snapshot = await query.get();
  const events = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

  // Aggregate data
  const activeUsers = new Set(events.map(e => anonymized ? e.anonUserId : e.uid)).size;
  const featureUsage: Record<string, number> = {};
  const featureDurations: Record<string, number[]> = {};

  events.forEach(event => {
    const feat = event.feature || 'unknown';
    featureUsage[feat] = (featureUsage[feat] || 0) + 1;
    
    if (event.durationMs) {
      if (!featureDurations[feat]) {
        featureDurations[feat] = [];
      }
      featureDurations[feat].push(event.durationMs);
    }
  });

  const avgDurations: Record<string, number> = {};
  Object.keys(featureDurations).forEach(feat => {
    const durations = featureDurations[feat];
    avgDurations[feat] = durations.reduce((a, b) => a + b, 0) / durations.length;
  });

  return {
    activeUsers,
    featureUsage,
    avgDurations,
    totalEvents: events.length,
  };
});

/**
 * Generate Report
 * Creates comprehensive reports with insights
 */
export const generateReport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { reportType, anonymized, dateRange, cohortType } = data;
  const uid = context.auth.uid;

  // Check permissions
  const isAdmin = await checkUserRole(uid, 'admin');
  const isResearchPartner = await checkUserRole(uid, 'research_partner');

  if (!isAdmin && !isResearchPartner) {
    throw new functions.https.HttpsError('permission-denied', 'Insufficient permissions');
  }

  if (!anonymized && !isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can generate unanonymized reports');
  }

  // This is a simplified version - implement full report logic based on reportType
  const collectionName = anonymized ? 'analytics_events' : 'analytics_events_private';
  
  // Query events in date range
  let query: admin.firestore.Query = db.collection(collectionName);
  if (dateRange) {
    query = query.where('timestamp', '>=', admin.firestore.Timestamp.fromDate(new Date(dateRange.start)));
    query = query.where('timestamp', '<=', admin.firestore.Timestamp.fromDate(new Date(dateRange.end)));
  }

  const snapshot = await query.get();
  const events = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

  // Generate report based on type
  const report = generateReportByType(reportType, events, cohortType);

  // Log audit event
  await db.collection('audit_logs').add({
    action: 'report_generated',
    reportType,
    anonymized,
    performedBy: uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return report;
});

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
 * Publish Release
 * Called from GitHub Actions to publish a new release
 * Handles both pilot (push to main) and production (tag prod-v*) releases
 */
export const publishRelease = functions.https.onCall(async (data, context) => {
  // Allow unauthenticated calls from GitHub Actions (using secret token)
  const { 
    pubspecVersionLine, 
    commitSha, 
    branch, 
    gitTag, 
    featureDossierJson, 
    environment,
    railwayDeployment,
    secretToken 
  } = data;

  // Verify secret token if provided (for GitHub Actions)
  if (secretToken) {
    const expectedToken = functions.config().github?.secret_token;
    if (!expectedToken || secretToken !== expectedToken) {
      throw new functions.https.HttpsError('permission-denied', 'Invalid secret token');
    }
  } else if (!context.auth) {
    // If no secret token, require authentication
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  if (!pubspecVersionLine || !commitSha || !featureDossierJson) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  // Parse version from pubspec.yaml line (e.g., "version: 1.2.3+13")
  const versionMatch = pubspecVersionLine.match(/version:\s*(\d+\.\d+\.\d+)\+(\d+)/);
  if (!versionMatch) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid version format in pubspec.yaml');
  }

  const versionName = versionMatch[1];
  const buildNumber = parseInt(versionMatch[2], 10);
  const fullVersion = `${versionName}+${buildNumber}`;

  // Determine channel based on git tag
  let channel: 'pilot' | 'production' = 'pilot';
  if (gitTag && gitTag.startsWith('prod-v')) {
    channel = 'production';
  }

  // Parse feature dossier
  let featureDossier;
  try {
    featureDossier = typeof featureDossierJson === 'string' 
      ? JSON.parse(featureDossierJson) 
      : featureDossierJson;
  } catch (e) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid featureDossierJson format');
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

  // Create release document
  const releaseDoc = {
    fullVersion,
    versionName,
    buildNumber,
    channel,
    git: gitInfo,
    railway: railwayInfo,
    featureDossier,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: context.auth?.uid || 'system',
  };

  // Upsert to releases collection (docId = buildNumber)
  await db.collection('releases').doc(buildNumber.toString()).set(releaseDoc, { merge: true });

  // Log audit event
  await db.collection('audit_logs').add({
    action: 'release_published',
    buildNumber,
    fullVersion,
    channel,
    gitTag: gitTag || null,
    performedBy: context.auth?.uid || 'system',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, buildNumber, channel, fullVersion };
});

/**
 * Poll System Health
 * Scheduled function that checks system health every 5 minutes
 */
export const pollSystemHealth = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
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
export const runHealthCheckNow = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = context.auth.uid;
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
});

/**
 * Perform Health Checks
 * Checks various system components
 */
async function performHealthChecks(): Promise<Record<string, any>> {
  const checks: Record<string, any> = {};

  // Check Railway API
  try {
    const railwayUrl = functions.config().railway?.health_url || 'https://api.railway.app/health';
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
        url: functions.config().railway?.health_url || 'https://api.railway.app/health',
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