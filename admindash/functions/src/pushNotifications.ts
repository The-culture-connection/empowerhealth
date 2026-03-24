/**
 * FCM push notifications — deployed with codebase `admindashboard`.
 * See Flutter `PushNotificationService` for token storage and topic subscription.
 */

import * as admin from 'firebase-admin';
import type { DocumentReference } from 'firebase-admin/firestore';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { deleteStaleFcmDeviceDocs } from './fcmStaleTokenCleanup';
import { safeWriteNotificationLog } from './notificationLog';

const db = admin.firestore();
const REGION = 'us-central1';

function computeTrimesterFromDueDate(
  due: FirebaseFirestore.Timestamp | undefined,
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

function isLearningModuleDoc(data: FirebaseFirestore.DocumentData | undefined): boolean {
  if (!data || !data.userId) return false;
  if (data.isBirthPlanTodo === true) return false;
  if (data.visitSummaryId && !data.moduleType) return false;
  if (data.category && !data.moduleType && !data.content) return false;
  return !!(data.moduleType || data.content);
}

function isTodoTask(data: FirebaseFirestore.DocumentData | undefined): boolean {
  if (!data || !data.userId) return false;
  if (data.isBirthPlanTodo === true) return true;
  if (data.visitSummaryId && !data.moduleType) return true;
  if (data.category && !data.moduleType && !data.content) return true;
  return false;
}

function isIncompleteTask(data: FirebaseFirestore.DocumentData | undefined): boolean {
  if (!data) return false;
  if (data.completed === true || data.isCompleted === true) return false;
  return true;
}

type UserDeviceRow = { ref: DocumentReference; token: string };

async function getFcmDeviceRowsForUser(uid: string): Promise<UserDeviceRow[]> {
  const snap = await db.collection('users').doc(uid).collection('devices').get();
  const rows: UserDeviceRow[] = [];
  for (const doc of snap.docs) {
    const t = doc.data().fcmToken;
    if (typeof t === 'string' && t.length > 0) rows.push({ ref: doc.ref, token: t });
  }
  return rows;
}

async function sendToUserDevices(
  uid: string,
  payload: { title: string; body: string; data?: Record<string, string> },
): Promise<{ sent: number; failures: number }> {
  const { title, body, data = {} } = payload;
  const deviceRows = await getFcmDeviceRowsForUser(uid);
  const tokens = deviceRows.map((r) => r.token);
  if (!tokens.length) {
    console.log(`[push] no FCM tokens for user ${uid}`);
    return { sent: 0, failures: 0 };
  }
  const dataStrings: Record<string, string> = {};
  for (const [k, v] of Object.entries(data)) {
    dataStrings[k] = String(v);
  }
  const threadId = data.type || 'empowerhealth';
  const resp = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: dataStrings,
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default', 'thread-id': threadId } } },
  });
  await deleteStaleFcmDeviceDocs(
    deviceRows.map((r) => r.ref),
    resp.responses,
  );
  if (resp.failureCount > 0) {
    resp.responses.forEach((r, i) => {
      if (!r.success) {
        console.warn(`[push] token fail ${tokens[i]?.slice(0, 12)}…`, r.error?.code, r.error?.message);
      }
    });
  }
  console.log(`[push] user=${uid} success=${resp.successCount} fail=${resp.failureCount} "${title}"`);
  return { sent: resp.successCount, failures: resp.failureCount };
}

function mondayWeekKey(d: Date): string {
  const x = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const day = x.getDay();
  const diff = x.getDate() - day + (day === 0 ? -6 : 1);
  const mon = new Date(x.setDate(diff));
  return mon.toISOString().slice(0, 10);
}

export const onLearningModuleCreated = onDocumentCreated(
  {
    document: 'learning_tasks/{taskId}',
    region: REGION,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data || !isLearningModuleDoc(data)) return;
    const uid = data.userId as string;
    const modTitle = data.title ? String(data.title).slice(0, 80) : 'New learning module';
    const body = `You have new content ready: ${modTitle}`;
    const r = await sendToUserDevices(uid, {
      title: 'New learning module',
      body,
      data: { type: 'learning_module', taskId: String(event.params.taskId) },
    });
    await safeWriteNotificationLog({
      title: 'New learning module',
      body,
      source: 'system',
      channel: 'learning_module',
      sentToSummary:
        r.sent > 0
          ? `User …${uid.slice(-6)} (${r.sent} device${r.sent === 1 ? '' : 's'})`
          : `User …${uid.slice(-6)} (no FCM tokens)`,
      recipientUserIds: [uid],
      deliveredCount: r.sent,
      failureCount: r.failures,
      metadata: { taskId: String(event.params.taskId) },
    });
  },
);

export const onCommunityPostUpdated = onDocumentUpdated(
  {
    document: 'community_posts/{postId}',
    region: REGION,
  },
  async (event) => {
    if (!event.data) return;
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};
    const authorId = after.userId as string | undefined;
    if (!authorId) return;

    const beforeLikes = new Set<string>(Array.isArray(before.likes) ? before.likes : []);
    const afterLikes: string[] = Array.isArray(after.likes) ? after.likes : [];

    for (const likerId of afterLikes) {
      if (!beforeLikes.has(likerId) && likerId !== authorId) {
        const r = await sendToUserDevices(authorId, {
          title: 'New like on your post',
          body: 'Someone liked your community post.',
          data: { type: 'community_like', postId: String(event.params.postId) },
        });
        await safeWriteNotificationLog({
          title: 'New like on your post',
          body: 'Someone liked your community post.',
          source: 'system',
          channel: 'community_like',
          sentToSummary: `Post author …${authorId.slice(-6)} · liker …${likerId.slice(-6)}`,
          recipientUserIds: [authorId],
          deliveredCount: r.sent,
          failureCount: r.failures,
          metadata: { postId: String(event.params.postId) },
        });
        break;
      }
    }

    const br = Array.isArray(before.replies) ? before.replies : [];
    const ar = Array.isArray(after.replies) ? after.replies : [];
    if (ar.length > br.length) {
      const newReplies = ar.slice(br.length) as Array<{ userId?: string; authorName?: string }>;
      for (const reply of newReplies) {
        const rid = reply?.userId;
        if (rid && rid !== authorId) {
          const name = (reply.authorName && String(reply.authorName).slice(0, 40)) || 'Someone';
          const r = await sendToUserDevices(authorId, {
            title: 'New reply',
            body: `${name} replied to your post.`,
            data: { type: 'community_reply', postId: String(event.params.postId) },
          });
          await safeWriteNotificationLog({
            title: 'New reply',
            body: `${name} replied to your post.`,
            source: 'system',
            channel: 'community_reply',
            sentToSummary: `Post author …${authorId.slice(-6)} · replier …${String(rid).slice(-6)}`,
            recipientUserIds: [authorId],
            deliveredCount: r.sent,
            failureCount: r.failures,
            metadata: { postId: String(event.params.postId) },
          });
        }
      }
    }
  },
);

/** Requires clients to subscribe: FirebaseMessaging.instance.subscribeToTopic('community_new_posts'). */
export const onCommunityPostCreated = onDocumentCreated(
  {
    document: 'community_posts/{postId}',
    region: REGION,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const raw = data.content != null ? String(data.content).trim() : '';
    const snippet = raw.slice(0, 120) || 'New discussion in Community';
    const notifBody = snippet + (snippet.length >= 120 ? '…' : '');
    try {
      await admin.messaging().send({
        topic: 'community_new_posts',
        notification: {
          title: 'New community post',
          body: notifBody,
        },
        data: {
          type: 'community_post',
          postId: String(event.params.postId ?? ''),
        },
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      console.log(`[push] topic community_new_posts postId=${event.params.postId}`);
      await safeWriteNotificationLog({
        title: 'New community post',
        body: notifBody,
        source: 'system',
        channel: 'community_topic',
        sentToSummary: 'FCM topic: community_new_posts (all subscribers)',
        topic: 'community_new_posts',
        deliveredCount: 1,
        failureCount: 0,
        metadata: { postId: String(event.params.postId ?? '') },
      });
    } catch (e) {
      console.error('[push] topic send failed', e);
      await safeWriteNotificationLog({
        title: 'New community post',
        body: notifBody,
        source: 'system',
        channel: 'community_topic',
        sentToSummary: 'FCM topic send failed — see function logs',
        topic: 'community_new_posts',
        deliveredCount: 0,
        failureCount: 1,
        metadata: { postId: String(event.params.postId ?? ''), err: String(e) },
      });
    }
  },
);

export const scheduledWeeklyTodoReminders = onSchedule(
  {
    schedule: '0 9 * * 1',
    timeZone: 'America/New_York',
    region: REGION,
    timeoutSeconds: 300,
    memory: '512MiB',
  },
  async () => {
    const weekKey = mondayWeekKey(new Date());
    const userIds = new Set<string>();
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    const batchSize = 300;
    for (let batch = 0; batch < 50; batch++) {
      let q = db.collection('learning_tasks').orderBy(admin.firestore.FieldPath.documentId()).limit(batchSize);
      if (lastDoc) q = q.startAfter(lastDoc);
      const snap = await q.get();
      if (snap.empty) break;
      for (const doc of snap.docs) {
        const d = doc.data();
        if (isTodoTask(d) && isIncompleteTask(d) && d.userId) {
          userIds.add(d.userId as string);
        }
      }
      lastDoc = snap.docs[snap.docs.length - 1];
      if (snap.size < batchSize) break;
    }

    let notified = 0;
    for (const uid of userIds) {
      const userRef = db.collection('users').doc(uid);
      const u = await userRef.get();
      if (!u.exists) continue;
      const push = (u.data()?.pushNotifications || {}) as Record<string, unknown>;
      if (push.weeklyTodoReminders === false) continue;
      if (push.lastWeeklyTodoWeek === weekKey) continue;

      const r = await sendToUserDevices(uid, {
        title: 'You have open to-dos',
        body: 'Check your EmpowerHealth tasks for items still waiting for you.',
        data: { type: 'weekly_todo_reminder' },
      });
      await userRef.update({
        'pushNotifications.lastWeeklyTodoWeek': weekKey,
      });
      await safeWriteNotificationLog({
        title: 'Weekly to-do reminder',
        body: 'Check your EmpowerHealth tasks for items still waiting for you.',
        source: 'system',
        channel: 'weekly_todo_reminder',
        sentToSummary: `User …${uid.slice(-6)} (${r.sent} delivered)`,
        recipientUserIds: [uid],
        deliveredCount: r.sent,
        failureCount: r.failures,
        metadata: { weekKey },
      });
      notified++;
    }
    console.log(`[push] weekly todo reminders week=${weekKey} users=${userIds.size} notified=${notified}`);
  },
);

export const scheduledTrimesterTransitionCheck = onSchedule(
  {
    schedule: '0 10 * * *',
    timeZone: 'America/New_York',
    region: REGION,
    timeoutSeconds: 300,
    memory: '512MiB',
  },
  async () => {
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    const batchSize = 200;
    for (let batch = 0; batch < 100; batch++) {
      let q = db.collection('users').orderBy(admin.firestore.FieldPath.documentId()).limit(batchSize);
      if (lastDoc) q = q.startAfter(lastDoc);
      const snap = await q.get();
      if (snap.empty) break;

      for (const doc of snap.docs) {
        const data = doc.data();
        const due = data.dueDate as FirebaseFirestore.Timestamp | undefined;
        if (!due) continue;
        const current = computeTrimesterFromDueDate(due);
        if (!current) continue;
        const push = (data.pushNotifications || {}) as Record<string, unknown>;
        if (push.trimesterReminders === false) continue;
        if (push.trimesterNotified === undefined || push.trimesterNotified === null) {
          await doc.ref.update({
            'pushNotifications.trimesterNotified': current,
          });
          continue;
        }
        if (push.trimesterNotified === current) continue;

        const label =
          current === 'First'
            ? 'first trimester'
            : current === 'Second'
              ? 'second trimester'
              : 'third trimester';

        const uid = doc.id;
        const body = `You're now in your ${label}. Open EmpowerHealth for tips matched to this stage.`;
        const r = await sendToUserDevices(uid, {
          title: "You've entered a new trimester",
          body,
          data: { type: 'trimester', trimester: current },
        });
        await doc.ref.update({
          'pushNotifications.trimesterNotified': current,
          'pushNotifications.trimesterNotifiedAt': admin.firestore.FieldValue.serverTimestamp(),
        });
        await safeWriteNotificationLog({
          title: "You've entered a new trimester",
          body,
          source: 'system',
          channel: 'trimester_transition',
          sentToSummary: `User …${uid.slice(-6)} → ${current} (${r.sent} delivered)`,
          recipientUserIds: [uid],
          deliveredCount: r.sent,
          failureCount: r.failures,
          metadata: { trimester: current },
        });
      }
      lastDoc = snap.docs[snap.docs.length - 1];
      if (snap.size < batchSize) break;
    }
    console.log('[push] trimester check pass complete');
  },
);
