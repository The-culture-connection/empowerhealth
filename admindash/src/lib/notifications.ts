/**
 * Push Notifications Management
 * Handles FCM token management and notification sending
 */

import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

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

/**
 * Send a push notification
 */
export async function sendNotification(payload: NotificationPayload): Promise<void> {
  const sendNotificationFn = httpsCallable(functions, 'sendNotification');
  await sendNotificationFn({
    ...payload,
    scheduledFor: payload.scheduledFor?.toISOString(),
  });
}

/**
 * Get notification delivery logs
 */
export async function getNotificationLogs(limitCount: number = 50): Promise<any[]> {
  const getNotificationLogsFn = httpsCallable(functions, 'getNotificationLogs');
  const result = await getNotificationLogsFn({ limit: limitCount });
  return result.data as any[];
}
