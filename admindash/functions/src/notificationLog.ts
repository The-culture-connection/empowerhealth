/**
 * Append-only audit of push sends for admin dashboard (`notification_logs`).
 */

import * as admin from 'firebase-admin';

const db = admin.firestore();

export type NotificationLogSource = 'admin' | 'system';

export interface WriteNotificationLogInput {
  title: string;
  body?: string;
  source: NotificationLogSource;
  /** Short machine id, e.g. learning_module, manual_broadcast, community_topic */
  channel: string;
  /** Human-readable: "3 users", "User ab12…", "Topic: community_new_posts" */
  sentToSummary: string;
  /** Optional; capped when stored */
  recipientUserIds?: string[];
  segment?: string;
  deliveredCount?: number;
  failureCount?: number;
  topic?: string;
  metadata?: Record<string, string>;
}

export async function writeNotificationLog(input: WriteNotificationLogInput): Promise<void> {
  const recipientUserIds =
    input.recipientUserIds && input.recipientUserIds.length > 40
      ? input.recipientUserIds.slice(0, 40)
      : input.recipientUserIds;

  await db.collection('notification_logs').add({
    ...input,
    recipientUserIds: recipientUserIds ?? null,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/** Never throw — logging must not break FCM delivery. */
export async function safeWriteNotificationLog(input: WriteNotificationLogInput): Promise<void> {
  try {
    await writeNotificationLog(input);
  } catch (e) {
    console.error('[notification_logs] write failed', e);
  }
}
