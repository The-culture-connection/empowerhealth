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
import { firestore, functions } from '../firebase/firebase';
import { httpsCallable } from 'firebase/functions';

export interface FeatureImplementation {
  architecture: string;
  components: string[];
  dataFlow: string;
}

export interface FeatureChangeHistory {
  version: string;
  date: any;
  change: string;
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
}

export interface FeatureUpdate {
  name: string;
  description?: string;
  updateHighlight?: string;
  domain?: string;
  category?: string;
  tags?: string[];
  implementation?: Partial<FeatureImplementation>;
  visible?: boolean;
  displayOrder?: number;
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
  const historyRef = collection(firestore, 'technology_features', featureId, 'change_history');
  const q = query(historyRef, orderBy('date', 'desc'));
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      ...data,
      date: data.date?.toDate(),
    } as FeatureChangeHistory;
  });
}

/**
 * Update a feature (Admin only - calls Cloud Function)
 */
export async function updateFeature(featureId: string, updates: FeatureUpdate): Promise<void> {
  const updateFeatureFn = httpsCallable(functions, 'updateFeature');
  await updateFeatureFn({
    featureId,
    updates,
  });
}
