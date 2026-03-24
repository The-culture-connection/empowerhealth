/**
 * Push Notifications Management
 * Handles FCM token management and notification sending
 */

import {
  collection,
  limit,
  onSnapshot,
  orderBy,
  query,
  type Unsubscribe,
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { functions, firestore } from '../firebase/firebase';

export type NotificationSegment = 
  | 'all'
  | 'active'
  | 'first_trimester'
  | 'second_trimester'
  | 'third_trimester'
  | 'postpartum'
  | 'due_date_window'
  | 'navigator'
  | 'self_directed';

export interface NotificationPayload {
  title: string;
  body: string;
  deepLink?: string;
  segment: NotificationSegment;
  scheduledFor?: Date;
}

/** Row from `notification_logs` (admin + system pushes). */
export interface NotificationLogRow {
  id: string;
  title: string;
  body?: string;
  source?: 'admin' | 'system';
  channel?: string;
  segment?: string;
  sentToSummary?: string;
  deliveredCount?: number;
  failureCount?: number;
  topic?: string;
  sentAt: Date | null;
}

/**
 * Send a push notification (callable; writes `notification_logs`).
 */
export async function sendNotification(payload: NotificationPayload): Promise<void> {
  const sendNotificationFn = httpsCallable(functions, 'sendNotification');
  await sendNotificationFn({
    ...payload,
    scheduledFor: payload.scheduledFor?.toISOString(),
  });
}

/**
 * Get notification delivery logs (callable fallback).
 */
export async function getNotificationLogs(limitCount: number = 50): Promise<unknown[]> {
  const getNotificationLogsFn = httpsCallable(functions, 'getNotificationLogs');
  const result = await getNotificationLogsFn({ limit: limitCount });
  return result.data as unknown[];
}

function mapLogDoc(id: string, data: Record<string, unknown>): NotificationLogRow {
  const sentAtRaw = data.sentAt;
  let sentAt: Date | null = null;
  if (sentAtRaw && typeof (sentAtRaw as { toDate?: () => Date }).toDate === 'function') {
    sentAt = (sentAtRaw as { toDate: () => Date }).toDate();
  } else if (sentAtRaw instanceof Date) {
    sentAt = sentAtRaw;
  }
  return {
    id,
    title: typeof data.title === 'string' ? data.title : '',
    body: typeof data.body === 'string' ? data.body : undefined,
    source: data.source as NotificationLogRow['source'],
    channel: typeof data.channel === 'string' ? data.channel : undefined,
    segment: typeof data.segment === 'string' ? data.segment : undefined,
    sentToSummary: typeof data.sentToSummary === 'string' ? data.sentToSummary : undefined,
    deliveredCount: typeof data.deliveredCount === 'number' ? data.deliveredCount : undefined,
    failureCount: typeof data.failureCount === 'number' ? data.failureCount : undefined,
    topic: typeof data.topic === 'string' ? data.topic : undefined,
    sentAt,
  };
}

/**
 * Real-time subscription to `notification_logs` (newest first).
 */
export function subscribeNotificationLogs(
  limitCount: number,
  onNext: (rows: NotificationLogRow[]) => void,
  onError?: (err: Error) => void,
): Unsubscribe {
  const q = query(
    collection(firestore, 'notification_logs'),
    orderBy('sentAt', 'desc'),
    limit(Math.min(Math.max(limitCount, 1), 100)),
  );
  return onSnapshot(
    q,
    (snap) => {
      const rows = snap.docs.map((d) => mapLogDoc(d.id, d.data() as Record<string, unknown>));
      onNext(rows);
    },
    (err) => {
      if (onError) onError(err);
      else console.error('subscribeNotificationLogs:', err);
    },
  );
}
