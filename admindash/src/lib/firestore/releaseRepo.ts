/**
 * Release Repository
 * Firestore operations for releases collection
 */

import { 
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  orderBy,
  limit,
  where,
  Timestamp,
} from 'firebase/firestore';
import { firestore } from '../../firebase/firebase';

export interface Release {
  fullVersion: string;
  versionName: string;
  buildNumber: number;
  channel: 'pilot' | 'production';
  git: {
    repoUrl: string;
    commitSha: string;
    branch: string;
    tag: string | null;
    compareUrl: string;
    commitUrl: string;
  };
  railway: {
    environment: 'pilot' | 'production';
    deploymentId: string | null;
    deploymentUrl: string | null;
    status: 'success' | 'failed' | 'in-progress';
    deployedAt: Timestamp | Date | null;
  } | null;
  featureDossier: any;
  createdAt: Timestamp | Date;
  createdBy: string;
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
 * Get latest release by channel (pilot or production)
 */
export async function getLatestReleaseByChannel(
  channel: 'pilot' | 'production'
): Promise<Release | null> {
  try {
    const releasesRef = collection(firestore, 'releases');
    const q = query(
      releasesRef,
      where('channel', '==', channel),
      orderBy('buildNumber', 'desc'),
      limit(1)
    );
    const snapshot = await getDocs(q);
    
    if (snapshot.empty) {
      console.log(`[Releases] No ${channel} release found`);
      return null;
    }

    const doc = snapshot.docs[0];
    const data = doc.data();
    
    return {
      ...data,
      createdAt: toDate(data.createdAt) || new Date(),
      railway: data.railway ? {
        ...data.railway,
        deployedAt: toDate(data.railway.deployedAt),
      } : null,
    } as Release;
  } catch (error) {
    console.error('[Releases] Error getting latest release by channel:', error);
    throw error;
  }
}

/**
 * List releases (ordered by buildNumber desc)
 */
export async function listReleases(limitCount: number = 20): Promise<Release[]> {
  try {
    const releasesRef = collection(firestore, 'releases');
    const q = query(
      releasesRef,
      orderBy('buildNumber', 'desc'),
      limit(limitCount)
    );
    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        ...data,
        createdAt: toDate(data.createdAt) || new Date(),
        railway: data.railway ? {
          ...data.railway,
          deployedAt: toDate(data.railway.deployedAt),
        } : null,
      } as Release;
    });
  } catch (error) {
    console.error('[Releases] Error listing releases:', error);
    throw error;
  }
}

/**
 * Get a specific release by build number
 */
export async function getRelease(buildNumber: number): Promise<Release | null> {
  try {
    const docRef = doc(firestore, 'releases', buildNumber.toString());
    const docSnap = await getDoc(docRef);
    
    if (!docSnap.exists()) {
      console.log(`[Releases] Release ${buildNumber} not found`);
      return null;
    }

    const data = docSnap.data();
    return {
      ...data,
      createdAt: toDate(data.createdAt) || new Date(),
      railway: data.railway ? {
        ...data.railway,
        deployedAt: toDate(data.railway.deployedAt),
      } : null,
    } as Release;
  } catch (error) {
    console.error(`[Releases] Error getting release ${buildNumber}:`, error);
    throw error;
  }
}
