/**
 * Admin dashboard: send broadcast push + read logs (callable fallback).
 */

import * as admin from 'firebase-admin';
import type { DocumentData, Timestamp } from 'firebase-admin/firestore';
import * as functions from 'firebase-functions';
import { writeNotificationLog } from './notificationLog';

const db = admin.firestore();

/**
 * Admin “Compose a Message” audience → FCM topic.
 * Must stay in sync with Flutter `lib/constants/push_audience_topics.dart`.
 */
const SEGMENT_TO_FCM_TOPIC: Record<string, string> = {
  all: 'empower_general',
  active: 'empower_general',
  due_date_window: 'empower_general',
  first_trimester: 'empower_trimester_first',
  second_trimester: 'empower_trimester_second',
  third_trimester: 'empower_trimester_third',
  postpartum: 'empower_postpartum',
  navigator: 'empower_cohort_navigator',
  self_directed: 'empower_cohort_self_directed',
};

function fcmTopicForSegment(segment: string): string | undefined {
  return SEGMENT_TO_FCM_TOPIC[segment];
}

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

function computeTrimesterFromDue(
  due: Timestamp | undefined,
): 'First' | 'Second' | 'Third' | null {
  if (!due || typeof due.toDate !== 'function') return null;
  const dueDate = due.toDate();
  const now = new Date();
  const daysUntilDue = Math.floor((dueDate.getTime() - now.getTime()) / 86400000);
  const weeksPregnant = 40 - Math.floor(daysUntilDue / 7);
  if (weeksPregnant <= 13) return 'First';
  if (weeksPregnant <= 27) return 'Second';
  return 'Third';
}

function segmentMatches(
  data: DocumentData,
  segment: string,
): boolean {
  if (segment === 'all' || segment === 'active' || segment === 'due_date_window') return true;

  if (segment === 'navigator') {
    return data.cohortType === 'navigator' || data.hasPrimaryProvider === true;
  }
  if (segment === 'self_directed') {
    return data.cohortType === 'self_directed' || data.hasPrimaryProvider === false;
  }

  const due = data.dueDate as Timestamp | undefined;
  const t = computeTrimesterFromDue(due);

  if (segment === 'first_trimester') return t === 'First';
  if (segment === 'second_trimester') return t === 'Second';
  if (segment === 'third_trimester') return t === 'Third';

  if (segment === 'postpartum') {
    if (data.isPostpartum === true) return true;
    const stage = data.pregnancyStage != null ? String(data.pregnancyStage).toLowerCase() : '';
    return stage.includes('post') || stage.includes('postpartum');
  }

  return true;
}

async function collectTokensForSegment(
  segment: string,
): Promise<{ tokens: string[]; userIds: string[] }> {
  const usersSnap = await db.collection('users').get();
  const tokens: string[] = [];
  const userIds: string[] = [];

  for (const userDoc of usersSnap.docs) {
    const data = userDoc.data();
    if (!segmentMatches(data, segment)) continue;

    const uid = userDoc.id;
    const deviceSnap = await db.collection('users').doc(uid).collection('devices').get();
    for (const d of deviceSnap.docs) {
      const t = d.data().fcmToken;
      if (typeof t === 'string' && t.length > 0) {
        tokens.push(t);
        userIds.push(uid);
      }
    }
  }
  return { tokens, userIds };
}

/** Admin / community manager: send FCM to segment; writes notification_logs. */
export const sendNotification = functions.https.onCall(
  {
    enforceAppCheck: false,
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async (request: functions.https.CallableRequest) => {
    if (!request.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const uid = request.auth.uid;
    const isAdmin = await checkUserRole(uid, 'admin');
    const isCommunity = await checkUserRole(uid, 'community_manager');
    if (!isAdmin && !isCommunity) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins or community managers can send notifications',
      );
    }

    const data = request.data || {};
    const title = typeof data.title === 'string' ? data.title.trim() : '';
    const body = typeof data.body === 'string' ? data.body.trim() : '';
    const segment = typeof data.segment === 'string' ? data.segment : 'all';
    const deepLink =
      typeof data.deepLink === 'string' && data.deepLink.trim() ? data.deepLink.trim() : undefined;

    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'title and body are required');
    }

    const scheduledFor = data.scheduledFor;
    if (scheduledFor) {
      throw new functions.https.HttpsError(
        'unimplemented',
        'Scheduled sends are not implemented yet; send without a schedule time.',
      );
    }

    const dataPayload: Record<string, string> = {
      type: 'admin_broadcast',
      segment: String(segment),
    };
    if (deepLink) dataPayload.deepLink = deepLink;

    const topic = fcmTopicForSegment(segment);
    if (topic) {
      try {
        const messageId = await admin.messaging().send({
          topic,
          notification: { title, body },
          data: dataPayload,
          android: { priority: 'high' },
          apns: { payload: { aps: { sound: 'default' } } },
        });
        await writeNotificationLog({
          title,
          body,
          source: 'admin',
          channel: 'manual_broadcast',
          sentToSummary: `FCM topic “${topic}” (Firebase messageId: ${messageId})`,
          segment,
          topic,
          metadata: deepLink ? { deepLink } : undefined,
        });
        return {
          success: true,
          mode: 'topic',
          topic,
          messageId,
        };
      } catch (err) {
        console.error('[sendNotification] FCM topic send failed', segment, err);
        await writeNotificationLog({
          title,
          body,
          source: 'admin',
          channel: 'manual_broadcast',
          sentToSummary: `Topic send failed for “${topic}”`,
          segment,
          topic,
          failureCount: 1,
          metadata: deepLink ? { deepLink } : undefined,
        });
        throw new functions.https.HttpsError(
          'internal',
          err instanceof Error ? err.message : 'FCM topic send failed',
        );
      }
    }

    const { tokens, userIds } = await collectTokensForSegment(segment);
    if (tokens.length === 0) {
      await writeNotificationLog({
        title,
        body,
        source: 'admin',
        channel: 'manual_broadcast',
        sentToSummary: `No devices matched segment "${segment}"`,
        segment,
        deliveredCount: 0,
        failureCount: 0,
        metadata: deepLink ? { deepLink } : undefined,
      });
      return { success: true, delivered: 0, failures: 0, message: 'No FCM tokens for this audience' };
    }

    let delivered = 0;
    let failures = 0;
    const chunkSize = 500;
    for (let i = 0; i < tokens.length; i += chunkSize) {
      const chunk = tokens.slice(i, i + chunkSize);
      const resp = await admin.messaging().sendEachForMulticast({
        tokens: chunk,
        notification: { title, body },
        data: dataPayload,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      delivered += resp.successCount;
      failures += resp.failureCount;
    }

    const uniqueUids = [...new Set(userIds)];
    const sentToSummary =
      uniqueUids.length <= 3
        ? uniqueUids.map((u) => `…${u.slice(-6)}`).join(', ')
        : `${uniqueUids.length} users (${delivered} device deliveries)`;

    await writeNotificationLog({
      title,
      body,
      source: 'admin',
      channel: 'manual_broadcast',
      sentToSummary,
      recipientUserIds: uniqueUids,
      segment,
      deliveredCount: delivered,
      failureCount: failures,
      metadata: deepLink ? { deepLink } : undefined,
    });

    return { success: true, delivered, failures, audienceUsers: uniqueUids.length, mode: 'multicast' };
  },
);

/** Callable fallback for clients that do not use Firestore subscription. */
export const getNotificationLogs = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest) => {
    if (!request.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const uid = request.auth.uid;
    const isAdmin = await checkUserRole(uid, 'admin');
    const isCommunity = await checkUserRole(uid, 'community_manager');
    if (!isAdmin && !isCommunity) {
      throw new functions.https.HttpsError('permission-denied', 'Access denied');
    }

    const limitCount = Math.min(
      Math.max(Number(request.data?.limit) || 50, 1),
      100,
    );
    const snap = await db
      .collection('notification_logs')
      .orderBy('sentAt', 'desc')
      .limit(limitCount)
      .get();

    const rows = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return rows;
  },
);
