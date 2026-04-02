/**
 * System Health Repository
 * Firestore operations for system_health collection
 */

import { 
  collection,
  doc,
  getDoc,
  getDocs,
  Timestamp,
} from 'firebase/firestore';
import { firestore } from '../../firebase/firebase';

export interface SystemHealth {
  name: string;
  status: 'operational' | 'degraded' | 'down';
  lastCheckedAt: Timestamp | Date | null;
  lastHealthyAt: Timestamp | Date | null;
  details: {
    message: string;
    latencyMs: number | null;
    errorCode: string | null;
    url: string | null;
  };
  metrics: {
    errorRate?: number;
    p95LatencyMs?: number;
    queueDepth?: number;
    lastJobRunAt?: Timestamp | Date | null;
    latencyMs?: number;
  };
}

/**
 * Convert Firestore Timestamp to JS Date
 */
function toDate(value: any): Date | null {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (value.toDate && typeof value.toDate === 'function') {
    return value.toDate();
  }
  return null;
}

/**
 * List all system health statuses
 */
export async function listSystemHealth(): Promise<Record<string, SystemHealth>> {
  try {
    const healthRef = collection(firestore, 'system_health');
    const snapshot = await getDocs(healthRef);

    const health: Record<string, SystemHealth> = {};
    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      health[doc.id] = {
        ...data,
        lastCheckedAt: toDate(data.lastCheckedAt),
        lastHealthyAt: toDate(data.lastHealthyAt),
        metrics: {
          ...data.metrics,
          lastJobRunAt: toDate(data.metrics?.lastJobRunAt),
        },
      } as SystemHealth;
    });

    return health;
  } catch (error) {
    console.error('[SystemHealth] Error listing system health:', error);
    throw error;
  }
}

/**
 * Get system health for a specific service
 */
export async function getSystemHealth(serviceKey: string): Promise<SystemHealth | null> {
  try {
    const docRef = doc(firestore, 'system_health', serviceKey);
    const docSnap = await getDoc(docRef);
    
    if (!docSnap.exists()) {
      console.log(`[SystemHealth] Service ${serviceKey} not found`);
      return null;
    }

    const data = docSnap.data();
    return {
      ...data,
      lastCheckedAt: toDate(data.lastCheckedAt),
      lastHealthyAt: toDate(data.lastHealthyAt),
      metrics: {
        ...data.metrics,
        lastJobRunAt: toDate(data.metrics?.lastJobRunAt),
      },
    } as SystemHealth;
  } catch (error) {
    console.error(`[SystemHealth] Error getting system health for ${serviceKey}:`, error);
    throw error;
  }
}
