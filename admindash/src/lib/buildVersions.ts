/**
 * Build Versions Management
 * Handles build version data from Cloud Functions
 */

import { 
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  orderBy,
  limit,
  setDoc,
  serverTimestamp
} from 'firebase/firestore';
import { firestore } from '../firebase/firebase';
import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

export interface Feature {
  name: string;
  description: string;
  status: 'active' | 'beta' | 'deprecated';
  tags?: string[];
  userFacingImpacts?: string[];
}

export interface FeatureDossier {
  summary: string;
  features: Feature[];
  notes?: string;
  knownIssues?: string[];
}

export interface BuildVersion {
  versionName: string;
  buildNumber: number;
  fullVersion: string;
  releaseDate: any;
  commitHash?: string;
  featureDossier: FeatureDossier;
  createdBy: string;
}

/**
 * Get latest build versions (default: 13)
 */
export async function getLatestBuildVersions(count: number = 13): Promise<BuildVersion[]> {
  const versionsRef = collection(firestore, 'build_versions');
  const q = query(versionsRef, orderBy('buildNumber', 'desc'), limit(count));
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      ...data,
      releaseDate: data.releaseDate?.toDate(),
    } as BuildVersion;
  });
}

/**
 * Get a specific build version by build number
 */
export async function getBuildVersion(buildNumber: number): Promise<BuildVersion | null> {
  const docRef = doc(firestore, 'build_versions', buildNumber.toString());
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) {
    return null;
  }

  const data = docSnap.data();
  return {
    ...data,
    releaseDate: data.releaseDate?.toDate(),
  } as BuildVersion;
}

/**
 * Call Cloud Function to upload build version
 * This is typically called from a CI/CD script or manually
 */
export async function uploadBuildVersion(
  fullVersion: string,
  commitHash: string,
  featureDossier: FeatureDossier
): Promise<void> {
  const uploadBuildVersionFn = httpsCallable(functions, 'uploadBuildVersion');
  
  await uploadBuildVersionFn({
    fullVersion,
    commitHash,
    featureDossier,
  });
}

/**
 * Group features by category/tags
 */
export function groupFeaturesByCategory(features: Feature[]): Record<string, Feature[]> {
  const categories: Record<string, Feature[]> = {
    Learning: [],
    AVS: [],
    'Provider Search': [],
    Forum: [],
    Journal: [],
    'Birth Plan': [],
    Notifications: [],
    Admin: [],
    Other: [],
  };

  features.forEach((feature) => {
    const tags = feature.tags || [];
    let categorized = false;

    // Try to match by tags first
    for (const tag of tags) {
      const category = Object.keys(categories).find(
        (cat) => cat.toLowerCase() === tag.toLowerCase()
      );
      if (category) {
        categories[category].push(feature);
        categorized = true;
        break;
      }
    }

    // Try to match by name
    if (!categorized) {
      for (const category of Object.keys(categories)) {
        if (feature.name.toLowerCase().includes(category.toLowerCase())) {
          categories[category].push(feature);
          categorized = true;
          break;
        }
      }
    }

    // Default to Other if no match
    if (!categorized) {
      categories.Other.push(feature);
    }
  });

  // Remove empty categories
  Object.keys(categories).forEach((key) => {
    if (categories[key].length === 0) {
      delete categories[key];
    }
  });

  return categories;
}
