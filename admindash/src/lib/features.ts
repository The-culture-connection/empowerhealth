/**
 * Feature Management
 * Handles technology features data from Firestore
 */

import { 
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  orderBy,
  where,
  updateDoc,
  setDoc,
  serverTimestamp,
} from 'firebase/firestore';
import { firestore, functions, auth } from '../firebase/firebase';
import { httpsCallable, HttpsCallableOptions } from 'firebase/functions';

export interface FeatureImplementation {
  architecture: string;
  components: string[];
  dataFlow: string;
}

export interface FeatureChangeHistory {
  version: string;
  date: any;
  change: string;
  title?: string;
  description?: string;
  commitSha?: string;
  releaseBuildNumber?: number;
  createdBy: string;
}

export interface TechnologyFeature {
  id: string;
  name: string;
  domain: string;
  category: string;
  description: string;
  howItWorks?: string; // How the feature works - detailed explanation
  updateHighlight?: string;
  recentUpdates?: string[]; // Array of recent updates/changes
  lastUpdated: any;
  visible: boolean;
  displayOrder: number;
  implementation: FeatureImplementation;
  tags: string[];
  createdAt: any;
  updatedAt: any;
  updatedBy: string;
  kpiGoals?: {
    eventGoals?: Record<string, number>;
    cohortGoals?: {
      navigator?: number;
      self_directed?: number;
    };
    usageGoals?: {
      dailyEvents?: number;
      weeklyUsers?: number;
      monthlyUsers?: number;
    };
    trimesterGoals?: {
      first?: number;
      second?: number;
      third?: number;
      postpartum?: number;
    };
  };
}

export interface FeatureUpdate {
  name?: string;
  description?: string;
  updateHighlight?: string;
  domain?: string;
  category?: string;
  tags?: string[];
  implementation?: Partial<FeatureImplementation>;
  visible?: boolean;
  displayOrder?: number;
  kpiGoals?: {
    eventGoals?: Record<string, number>;
    cohortGoals?: {
      navigator?: number;
      self_directed?: number;
    };
    usageGoals?: {
      dailyEvents?: number;
      weeklyUsers?: number;
      monthlyUsers?: number;
    };
    trimesterGoals?: {
      first?: number;
      second?: number;
      third?: number;
      postpartum?: number;
    };
  };
}

/**
 * Get all visible features ordered by displayOrder
 */
export async function getAllFeatures(): Promise<TechnologyFeature[]> {
  const featuresRef = collection(firestore, 'technology_features');
  const q = query(
    featuresRef,
    where('visible', '==', true),
    orderBy('displayOrder', 'asc')
  );
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id, // CRITICAL: Include the document ID
      ...data,
      howItWorks: data.howItWorks || undefined,
      recentUpdates: data.recentUpdates || undefined,
      lastUpdated: data.lastUpdated?.toDate(),
      createdAt: data.createdAt?.toDate(),
      updatedAt: data.updatedAt?.toDate(),
    } as TechnologyFeature;
  });
}

/**
 * Get a single feature by ID with change history
 */
export async function getFeatureById(featureId: string): Promise<TechnologyFeature | null> {
  const featureRef = doc(firestore, 'technology_features', featureId);
  const featureDoc = await getDoc(featureRef);

  if (!featureDoc.exists()) {
    return null;
  }

  const data = featureDoc.data();
  return {
    id: featureDoc.id, // CRITICAL: Include the document ID
    ...data,
    lastUpdated: data.lastUpdated?.toDate(),
    createdAt: data.createdAt?.toDate(),
    updatedAt: data.updatedAt?.toDate(),
  } as TechnologyFeature;
}

/**
 * Get features filtered by domain
 */
export async function getFeaturesByDomain(domain: string): Promise<TechnologyFeature[]> {
  const featuresRef = collection(firestore, 'technology_features');
  const q = query(
    featuresRef,
    where('visible', '==', true),
    where('domain', '==', domain),
    orderBy('displayOrder', 'asc')
  );
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      ...data,
      howItWorks: data.howItWorks || undefined,
      recentUpdates: data.recentUpdates || undefined,
      lastUpdated: data.lastUpdated?.toDate(),
      createdAt: data.createdAt?.toDate(),
      updatedAt: data.updatedAt?.toDate(),
    } as TechnologyFeature;
  });
}

/**
 * Get change history for a feature
 */
export async function getFeatureChangeHistory(featureId: string): Promise<FeatureChangeHistory[]> {
  try {
    if (!featureId || featureId.trim() === '') {
      console.warn('getFeatureChangeHistory: featureId is empty');
      return [];
    }
    
    const historyRef = collection(firestore, 'technology_features', featureId, 'change_history');
    const q = query(historyRef, orderBy('date', 'desc'));
    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      // Handle date conversion safely
      let dateValue: any = null;
      if (data.date) {
        if (data.date.toDate && typeof data.date.toDate === 'function') {
          dateValue = data.date.toDate();
        } else if (data.date instanceof Date) {
          dateValue = data.date;
        } else {
          dateValue = data.date;
        }
      }
      
      return {
        ...data,
        date: dateValue,
      } as FeatureChangeHistory;
    });
  } catch (error) {
    console.error('Error fetching feature change history:', error);
    return [];
  }
}

/**
 * Update a feature (Admin only - calls Cloud Function)
 */
export async function updateFeature(featureId: string, updates: FeatureUpdate): Promise<void> {
  // Ensure user is authenticated
  const currentUser = auth.currentUser;
  if (!currentUser) {
    throw new Error('User must be authenticated to update features');
  }

  // Refresh auth token to ensure it's valid and get it explicitly
  let idToken: string;
  try {
    idToken = await currentUser.getIdToken(true);
    console.log('🔐 [updateFeature] Token refreshed, length:', idToken.length);
  } catch (error) {
    console.error('Error refreshing auth token:', error);
    throw new Error('Failed to refresh authentication token. Please log in again.');
  }

  // Create the callable function with explicit options to ensure auth is included
  const updateFeatureFn = httpsCallable(functions, 'updateFeature', {
    // Explicitly ensure auth is included
  } as HttpsCallableOptions);

  try {
    console.log('📞 [updateFeature] Calling Cloud Function with:', {
      featureId,
      hasUpdates: !!updates,
      userId: currentUser.uid,
    });
    
    const result = await updateFeatureFn({
      featureId,
      updates,
    });
    
    console.log('✅ [updateFeature] Function call successful:', result);
  } catch (error: any) {
    console.error('❌ [updateFeature] Function call failed:', {
      code: error?.code,
      message: error?.message,
      details: error?.details,
    });
    throw error;
  }
}
