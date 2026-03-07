/**
 * Firebase Cloud Functions for EmpowerHealth Admin Dashboard
 */

import * as functions from 'firebase-functions';
import * as functionsV1 from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { defineString, defineSecret } from 'firebase-functions/params';

admin.initializeApp();

const db = admin.firestore();

/**
 * Upload Build Version
 * Called from CI/CD or manual script to upload build version info
 */
export const uploadBuildVersion = functions.https.onCall(async (data: any, context: any) => {
  // Verify caller is authenticated
  if (!context || !context.auth) {
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
export const logAnalyticsEvent = functions.https.onCall(async (data: any, context: any) => {
  if (!context || !context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { eventName, feature, metadata, durationMs, sessionId } = data;
  const uid = context.auth.uid;
  
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
    'profile-editing'
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
export const getAnalyticsData = functions.https.onCall(async (data: any, context: any) => {
  if (!context || !context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { dateRange, feature, anonymized = true } = data;
  const uid = context.auth.uid;

  // Check user role
  const isAdmin = await checkUserRole(uid, 'admin');

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
  const events: any[] = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

  // Aggregate data
  const activeUsers = new Set(events.map((e: any) => anonymized ? e.anonUserId : e.uid)).size;
  const featureUsage: Record<string, number> = {};
  const featureDurations: Record<string, number[]> = {};

  events.forEach((event: any) => {
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
export const generateReport = functions.https.onCall(async (data: any, context: any) => {
  if (!context || !context.auth) {
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
 * Get Feature Analytics
 * Aggregates analytics data for a specific feature
 */
export const getFeatureAnalytics = functions.https.onCall(async (data: any, context: any) => {
  if (!context || !context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { featureId, dateRange, anonymized = true } = data;
  const uid = context.auth.uid;

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

  // Apply date range if provided
  if (dateRange) {
    const startDate = dateRange.start ? admin.firestore.Timestamp.fromDate(new Date(dateRange.start)) : null;
    const endDate = dateRange.end ? admin.firestore.Timestamp.fromDate(new Date(dateRange.end)) : null;
    
    if (startDate) {
      query = query.where('timestamp', '>=', startDate);
    }
    if (endDate) {
      query = query.where('timestamp', '<=', endDate);
    }
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
});

/**
 * Update Feature
 * Admin-only function to update feature metadata
 */
export const updateFeature = functions.https.onCall(async (data: any, context: any) => {
  if (!context || !context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { featureId, updates } = data;
  const uid = context.auth.uid;

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
export const processFeatureChanges = functions.https.onCall(async (data: any, context?: any) => {
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
  } else if (!context?.auth) {
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
      performedBy: context?.auth?.uid || 'system',
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
});

/**
 * Parse FEATURES.md markdown content
 */
function parseFeaturesMarkdown(content: string): Record<string, any> {
  const features: Record<string, any> = {};
  const sections = content.split(/^## \d+\. /m);
  
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
        const matchWithCommit = line.match(/^- \*\*(\d{4}-\d{2}-\d{2})\*\* - \*\*([a-f0-9]+)\*\* - \*\*([^\*]+)\*\*: (.+)$/);
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
  });
  
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
        
        for (const [featureId, featureData] of Object.entries(features)) {
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
          const existingUpdates = existingData?.recentUpdates || [];
          const newUpdates = featureData.recentUpdates || [];
          // Combine and deduplicate, keeping most recent
          const allUpdates = [...newUpdates, ...existingUpdates];
          const uniqueUpdates = Array.from(new Set(allUpdates)); // Simple deduplication
          featureUpdate.recentUpdates = uniqueUpdates.slice(0, 10); // Keep last 10 updates
          
          if (!featureDoc.exists) {
            featureUpdate.createdAt = now;
            featureUpdate.visible = true;
          }
          
          await featureRef.set(featureUpdate, { merge: true });
          console.log(`[publishRelease] Updated feature ${featureId} with howItWorks and recentUpdates`);
          
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
export const runHealthCheckNow = functions.https.onCall(async (data: any, context: any) => {
  if (!context || !context.auth) {
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