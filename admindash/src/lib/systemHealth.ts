/**
 * System Health Management
 * Handles system health monitoring and status checks
 */

import { 
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  orderBy,
  limit,
} from 'firebase/firestore';
import { firestore, functions } from '../firebase/firebase';
import { httpsCallable } from 'firebase/functions';

export interface SystemHealthDetails {
  message: string;
  latencyMs: number | null;
  errorCode: string | null;
  url: string | null;
}

export interface SystemHealthMetrics {
  errorRate?: number;
  p95LatencyMs?: number;
  queueDepth?: number;
  lastJobRunAt?: any;
  latencyMs?: number;
}

export interface SystemHealth {
  name: string;
  status: 'operational' | 'degraded' | 'down';
  lastCheckedAt: any;
  lastHealthyAt: any;
  details: SystemHealthDetails;
  metrics: SystemHealthMetrics;
}

export interface Incident {
  severity: 'low' | 'medium' | 'high';
  summary: string;
  startedAt: any;
  resolvedAt: any | null;
  releaseVersion: string;
}

/**
 * Get system health for a specific service
 */
export async function getSystemHealth(serviceKey: string): Promise<SystemHealth | null> {
  const docRef = doc(firestore, 'system_health', serviceKey);
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) {
    return null;
  }

  const data = docSnap.data();
  return {
    ...data,
    lastCheckedAt: data.lastCheckedAt?.toDate(),
    lastHealthyAt: data.lastHealthyAt?.toDate(),
    metrics: {
      ...data.metrics,
      lastJobRunAt: data.metrics?.lastJobRunAt?.toDate(),
    },
  } as SystemHealth;
}

/**
 * Get all system health statuses
 */
export async function getAllSystemHealth(): Promise<Record<string, SystemHealth>> {
  const healthRef = collection(firestore, 'system_health');
  const snapshot = await getDocs(healthRef);

  const health: Record<string, SystemHealth> = {};
  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    health[doc.id] = {
      ...data,
      lastCheckedAt: data.lastCheckedAt?.toDate(),
      lastHealthyAt: data.lastHealthyAt?.toDate(),
      metrics: {
        ...data.metrics,
        lastJobRunAt: data.metrics?.lastJobRunAt?.toDate(),
      },
    } as SystemHealth;
  });

  return health;
}

/**
 * Trigger manual health check (Admin only)
 */
export async function runHealthCheckNow(): Promise<Record<string, SystemHealth>> {
  const runHealthCheckNowFn = httpsCallable(functions, 'runHealthCheckNow');
  const result = await runHealthCheckNowFn();
  return (result.data as any).checks;
}

/**
 * Get recent incidents
 */
export async function getRecentIncidents(limitCount: number = 10): Promise<Incident[]> {
  const incidentsRef = collection(firestore, 'incidents');
  const q = query(incidentsRef, orderBy('startedAt', 'desc'), limit(limitCount));
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      ...data,
      startedAt: data.startedAt?.toDate(),
      resolvedAt: data.resolvedAt?.toDate(),
    } as Incident;
  });
}
