/**
 * Remove Firestore device rows when FCM reports an unusable registration token.
 * Prevents repeated failed sends and lets the client write a fresh token on next launch.
 */

import type { DocumentReference } from 'firebase-admin/firestore';

const STALE_FCM_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

export function isStaleFcmTokenError(code: string | undefined): boolean {
  return code != null && STALE_FCM_TOKEN_CODES.has(code);
}

export async function deleteStaleFcmDeviceDocs(
  deviceRefs: Array<DocumentReference | undefined>,
  responses: Array<{ success: boolean; error?: { code?: string; message?: string } }>,
): Promise<void> {
  await Promise.all(
    responses.map(async (r, i) => {
      if (r.success) return;
      const code = r.error?.code;
      if (!isStaleFcmTokenError(code)) return;
      const ref = deviceRefs[i];
      if (!ref) return;
      try {
        await ref.delete();
        console.log(`[FCM] deleted stale device doc (${code}): ${ref.path}`);
      } catch (e) {
        console.warn(`[FCM] failed to delete stale device doc ${ref.path}`, e);
      }
    }),
  );
}
