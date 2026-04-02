/**
 * FCM push notifications (EmpowerHealth).
 *
 * - New learning modules: Firestore onCreate learning_tasks (module-like docs only)
 * - Weekly todo reminders: scheduled (Mondays); scans learning_tasks for open todos
 * - Trimester transitions: daily schedule; compares computed trimester vs users.pushNotifications.trimesterNotified
 * - Community: onUpdate for likes/replies (notify post author); onCreate broadcasts to FCM topic community_new_posts
 *
 * Client: store tokens under users/{uid}/devices/{docId} (see Flutter PushNotificationService).
 * For topic "new post" alerts, subscribe: FirebaseMessaging.instance.subscribeToTopic('community_new_posts').
 */

const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

const db = admin.firestore();
const REGION = "us-central1";

/** @param {FirebaseFirestore.Timestamp|undefined} due */
function computeTrimesterFromDueDate(due) {
  if (!due || typeof due.toDate !== "function") return null;
  const dueDate = due.toDate();
  const now = new Date();
  const daysUntilDue = Math.floor((dueDate.getTime() - now.getTime()) / 86400000);
  const weeksPregnant = 40 - Math.floor(daysUntilDue / 7);
  if (weeksPregnant <= 13) return "First";
  if (weeksPregnant <= 27) return "Second";
  return "Third";
}

/** Matches Flutter LearningTodoWidget heuristics: modules have moduleType or content; todos are birth-plan / visit / category-only. */
function isLearningModuleDoc(data) {
  if (!data || !data.userId) return false;
  if (data.isBirthPlanTodo === true) return false;
  if (data.visitSummaryId && !data.moduleType) return false;
  if (data.category && !data.moduleType && !data.content) return false;
  return !!(data.moduleType || data.content);
}

function isTodoTask(data) {
  if (!data || !data.userId) return false;
  if (data.isBirthPlanTodo === true) return true;
  if (data.visitSummaryId && !data.moduleType) return true;
  if (data.category && !data.moduleType && !data.content) return true;
  return false;
}

function isIncompleteTask(data) {
  if (!data) return false;
  if (data.completed === true || data.isCompleted === true) return false;
  return true;
}

/** @param {string} uid */
async function getFcmTokensForUser(uid) {
  const snap = await db.collection("users").doc(uid).collection("devices").get();
  const tokens = [];
  for (const doc of snap.docs) {
    const t = doc.data().fcmToken;
    if (typeof t === "string" && t.length > 0) tokens.push(t);
  }
  return tokens;
}

/**
 * @param {string} uid
 * @param {{ title: string; body: string; data?: Record<string, string> }} payload
 */
async function sendToUserDevices(uid, {title, body, data = {}}) {
  const tokens = await getFcmTokensForUser(uid);
  if (!tokens.length) {
    console.log(`[push] no FCM tokens for user ${uid}`);
    return {sent: 0, failures: 0};
  }
  const dataStrings = {};
  for (const [k, v] of Object.entries(data)) {
    dataStrings[k] = String(v);
  }
  const resp = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
    data: dataStrings,
    android: {priority: "high"},
    apns: {payload: {aps: {sound: "default", "thread-id": data.type || "empowerhealth"}}},
  });
  if (resp.failureCount > 0) {
    resp.responses.forEach((r, i) => {
      if (!r.success) {
        console.warn(`[push] token fail ${tokens[i]?.slice(0, 12)}…`, r.error?.code, r.error?.message);
      }
    });
  }
  console.log(`[push] user=${uid} success=${resp.successCount} fail=${resp.failureCount} "${title}"`);
  return {sent: resp.successCount, failures: resp.failureCount};
}

function mondayWeekKey(d) {
  const x = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const day = x.getDay();
  const diff = x.getDate() - day + (day === 0 ? -6 : 1);
  const mon = new Date(x.setDate(diff));
  return mon.toISOString().slice(0, 10);
}

// --- Triggers ---

exports.onLearningModuleCreated = onDocumentCreated(
  {
    document: "learning_tasks/{taskId}",
    region: REGION,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data || !isLearningModuleDoc(data)) {
      return;
    }
    const uid = data.userId;
    const title = data.title ? String(data.title).slice(0, 80) : "New learning module";
    await sendToUserDevices(uid, {
      title: "New learning module",
      body: `You have new content ready: ${title}`,
      data: {type: "learning_module", taskId: event.params.taskId},
    });
  },
);

exports.onCommunityPostUpdated = onDocumentUpdated(
  {
    document: "community_posts/{postId}",
    region: REGION,
  },
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};
    const authorId = after.userId;
    if (!authorId) return;

    const beforeLikes = new Set(Array.isArray(before.likes) ? before.likes : []);
    const afterLikes = Array.isArray(after.likes) ? after.likes : [];

    for (const likerId of afterLikes) {
      if (!beforeLikes.has(likerId) && likerId !== authorId) {
        await sendToUserDevices(authorId, {
          title: "New like on your post",
          body: "Someone liked your community post.",
          data: {type: "community_like", postId: event.params.postId},
        });
        break;
      }
    }

    const br = Array.isArray(before.replies) ? before.replies : [];
    const ar = Array.isArray(after.replies) ? after.replies : [];
    if (ar.length > br.length) {
      const newReplies = ar.slice(br.length);
      for (const reply of newReplies) {
        const rid = reply && reply.userId;
        if (rid && rid !== authorId) {
          const name = (reply.authorName && String(reply.authorName).slice(0, 40)) || "Someone";
          await sendToUserDevices(authorId, {
            title: "New reply",
            body: `${name} replied to your post.`,
            data: {type: "community_reply", postId: event.params.postId},
          });
        }
      }
    }
  },
);

/** Subscribers must call FirebaseMessaging.instance.subscribeToTopic('community_new_posts'). */
exports.onCommunityPostCreated = onDocumentCreated(
  {
    document: "community_posts/{postId}",
    region: REGION,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const snippet = (data.content && String(data.content).trim().slice(0, 120)) || "New discussion in Community";
    try {
      await admin.messaging().send({
        topic: "community_new_posts",
        notification: {
          title: "New community post",
          body: snippet + (snippet.length >= 120 ? "…" : ""),
        },
        data: {
          type: "community_post",
          postId: String(event.params.postId || ""),
        },
        android: {priority: "high"},
        apns: {payload: {aps: {sound: "default"}}},
      });
      console.log(`[push] topic community_new_posts postId=${event.params.postId}`);
    } catch (e) {
      console.error("[push] topic send failed", e);
    }
  },
);

// --- Schedules ---

exports.scheduledWeeklyTodoReminders = onSchedule(
  {
    schedule: "0 9 * * 1",
    timeZone: "America/New_York",
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async () => {
    const weekKey = mondayWeekKey(new Date());
    const userIds = new Set();
    let lastDoc = null;
    const batchSize = 300;
    for (let batch = 0; batch < 50; batch++) {
      let q = db.collection("learning_tasks").orderBy(admin.firestore.FieldPath.documentId()).limit(batchSize);
      if (lastDoc) q = q.startAfter(lastDoc);
      const snap = await q.get();
      if (snap.empty) break;
      for (const doc of snap.docs) {
        const d = doc.data();
        if (isTodoTask(d) && isIncompleteTask(d) && d.userId) {
          userIds.add(d.userId);
        }
      }
      lastDoc = snap.docs[snap.docs.length - 1];
      if (snap.size < batchSize) break;
    }

    let notified = 0;
    for (const uid of userIds) {
      const userRef = db.collection("users").doc(uid);
      const u = await userRef.get();
      if (!u.exists) continue;
      const push = u.data()?.pushNotifications || {};
      if (push.weeklyTodoReminders === false) continue;
      if (push.lastWeeklyTodoWeek === weekKey) continue;

      await sendToUserDevices(uid, {
        title: "You have open to-dos",
        body: "Check your EmpowerHealth tasks for items still waiting for you.",
        data: {type: "weekly_todo_reminder"},
      });
      await userRef.update({
        "pushNotifications.lastWeeklyTodoWeek": weekKey,
      });
      notified++;
    }
    console.log(`[push] weekly todo reminders week=${weekKey} users=${userIds.size} notified=${notified}`);
  },
);

exports.scheduledTrimesterTransitionCheck = onSchedule(
  {
    schedule: "0 10 * * *",
    timeZone: "America/New_York",
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async () => {
    let lastDoc = null;
    const batchSize = 200;
    for (let batch = 0; batch < 100; batch++) {
      let q = db.collection("users").orderBy(admin.firestore.FieldPath.documentId()).limit(batchSize);
      if (lastDoc) q = q.startAfter(lastDoc);
      const snap = await q.get();
      if (snap.empty) break;

      for (const doc of snap.docs) {
        const data = doc.data();
        if (!data) continue;
        const due = data.dueDate;
        if (!due) continue;
        const current = computeTrimesterFromDueDate(due);
        if (!current) continue;
        const push = data.pushNotifications || {};
        if (push.trimesterReminders === false) continue;
        // Seed without notifying so we only fire on real First→Second→Third transitions.
        if (push.trimesterNotified === undefined || push.trimesterNotified === null) {
          await doc.ref.update({
            "pushNotifications.trimesterNotified": current,
          });
          continue;
        }
        if (push.trimesterNotified === current) continue;

        const label =
          current === "First"
            ? "first trimester"
            : current === "Second"
              ? "second trimester"
              : "third trimester";

        await sendToUserDevices(doc.id, {
          title: "You’ve entered a new trimester",
          body: `You’re now in your ${label}. Open EmpowerHealth for tips matched to this stage.`,
          data: {type: "trimester", trimester: current},
        });
        await doc.ref.update({
          "pushNotifications.trimesterNotified": current,
          "pushNotifications.trimesterNotifiedAt": admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      lastDoc = snap.docs[snap.docs.length - 1];
      if (snap.size < batchSize) break;
    }
    console.log("[push] trimester check pass complete");
  },
);
