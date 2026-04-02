/**
 * Releases Management
 * Handles release data from GitHub Actions and Railway
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
} from 'firebase/firestore';
import { firestore, functions } from '../firebase/firebase';
import { httpsCallable } from 'firebase/functions';

export interface FeatureItem {
  name: string;
  description: string;
  status: 'New' | 'Improved' | 'Fixed' | 'active' | 'beta' | 'deprecated';
  tags?: string[];
  userFacingImpacts?: string[];
}

export interface FeatureDossierCategory {
  name: string;
  items: FeatureItem[];
}

export interface FeatureDossier {
  summary: string;
  categories?: FeatureDossierCategory[];
  features?: FeatureItem[]; // Legacy format support
  notes?: string;
  knownIssues?: string[];
  migrationNotes?: string[];
}

export interface GitInfo {
  repoUrl: string;
  commitSha: string;
  branch: string;
  tag: string | null;
  compareUrl: string;
  commitUrl: string;
  commitMessage?: string;
  commitAuthor?: string;
  commitDate?: any;
}

export interface RailwayInfo {
  environment: 'pilot' | 'production';
  deploymentId: string | null;
  deploymentUrl: string | null;
  status: 'success' | 'failed' | 'in-progress';
  deployedAt: any;
}

export interface FunctionalUpdate {
  name: string;
  description: string;
  domain: string;
}

export interface Release {
  fullVersion: string;
  versionName: string;
  buildNumber: number;
  channel: 'pilot' | 'production';
  git: GitInfo;
  railway: RailwayInfo | null;
  featureDossier: FeatureDossier;
  functionalUpdates?: Record<string, FunctionalUpdate[]>; // Extracted from featureDossier
  createdAt: any;
  createdBy: string;
}

/**
 * Get current production release
 */
export async function getCurrentProductionRelease(): Promise<Release | null> {
  const releasesRef = collection(firestore, 'releases');
  const q = query(
    releasesRef,
    where('channel', '==', 'production'),
    orderBy('buildNumber', 'desc'),
    limit(1)
  );
  const snapshot = await getDocs(q);
  
  if (snapshot.empty) {
    return null;
  }

  const doc = snapshot.docs[0];
  const data = doc.data();
  return {
    ...data,
    createdAt: data.createdAt?.toDate(),
    railway: data.railway ? {
      ...data.railway,
      deployedAt: data.railway.deployedAt?.toDate(),
    } : null,
  } as Release;
}

/**
 * Get current pilot release
 */
export async function getCurrentPilotRelease(): Promise<Release | null> {
  const releasesRef = collection(firestore, 'releases');
  const q = query(
    releasesRef,
    where('channel', '==', 'pilot'),
    orderBy('buildNumber', 'desc'),
    limit(1)
  );
  const snapshot = await getDocs(q);
  
  if (snapshot.empty) {
    return null;
  }

  const doc = snapshot.docs[0];
  const data = doc.data();
  return {
    ...data,
    createdAt: data.createdAt?.toDate(),
    railway: data.railway ? {
      ...data.railway,
      deployedAt: data.railway.deployedAt?.toDate(),
    } : null,
  } as Release;
}

/**
 * Get latest releases (last N, default 13)
 */
export async function getLatestReleases(count: number = 13): Promise<Release[]> {
  const releasesRef = collection(firestore, 'releases');
  const q = query(releasesRef, orderBy('buildNumber', 'desc'), limit(count));
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      ...data,
      createdAt: data.createdAt?.toDate(),
      railway: data.railway ? {
        ...data.railway,
        deployedAt: data.railway.deployedAt?.toDate(),
      } : null,
    } as Release;
  });
}

/**
 * Get a specific release by build number
 */
export async function getRelease(buildNumber: number): Promise<Release | null> {
  const docRef = doc(firestore, 'releases', buildNumber.toString());
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) {
    return null;
  }

  const data = docSnap.data();
  return {
    ...data,
    createdAt: data.createdAt?.toDate(),
    railway: data.railway ? {
      ...data.railway,
      deployedAt: data.railway.deployedAt?.toDate(),
    } : null,
  } as Release;
}

/**
 * Group features by category
 */
export function groupFeaturesByCategory(dossier: FeatureDossier): Record<string, FeatureItem[]> {
  const categories: Record<string, FeatureItem[]> = {
    'After Visit Summary': [],
    'Learning Modules': [],
    'Provider Search': [],
    'Community': [],
    'Journal': [],
    'Birth Plan': [],
    'Notifications': [],
    'Admin': [],
    'Other': [],
  };

  // Handle new category-based format
  if (dossier.categories) {
    dossier.categories.forEach((category) => {
      if (categories[category.name]) {
        categories[category.name] = category.items;
      } else {
        categories.Other.push(...category.items);
      }
    });
    return categories;
  }

  // Handle legacy features array format
  if (dossier.features) {
    dossier.features.forEach((feature) => {
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
  }

  // Remove empty categories
  Object.keys(categories).forEach((key) => {
    if (categories[key].length === 0) {
      delete categories[key];
    }
  });

  return categories;
}

/**
 * Extract functional updates from release featureDossier
 * Groups updates by domain for display in release notes
 */
export function extractFunctionalUpdates(release: Release): Record<string, FunctionalUpdate[]> {
  const updates: Record<string, FunctionalUpdate[]> = {};

  // Use functionalUpdates if available (from publishRelease)
  if (release.functionalUpdates) {
    return release.functionalUpdates;
  }

  // Fallback: extract from featureDossier.categories
  if (release.featureDossier?.categories) {
    release.featureDossier.categories.forEach((category) => {
      const domainKey = category.name?.toLowerCase().replace(/\s+/g, '-') || 'other';
      if (!updates[domainKey]) {
        updates[domainKey] = [];
      }
      if (category.items && Array.isArray(category.items)) {
        category.items.forEach((item) => {
          updates[domainKey].push({
            name: item.name || 'Unnamed Update',
            description: item.description || '',
            domain: category.name || 'Other',
          });
        });
      }
    });
  }

  return updates;
}

/**
 * Get GitHub commit URL for a commit SHA
 */
export function getGitHubCommitUrl(commitSha: string, repoUrl?: string): string {
  const baseUrl = repoUrl || 'https://github.com/The-culture-connection/empowerhealth';
  // Remove .git suffix if present
  const cleanUrl = baseUrl.replace(/\.git$/, '');
  return `${cleanUrl}/commit/${commitSha}`;
}
