/**
 * Frontend library for fetching GitHub commits
 */

import { firestore } from '../firebase/firebase';
import { collection, query, orderBy, limit, getDocs, Timestamp } from 'firebase/firestore';

export interface Commit {
  commitSha: string;
  commitMessage: string;
  commitAuthor: string;
  commitDate: Timestamp | Date;
  branch: string;
  gitTag: string | null;
  buildNumber?: number;
  fullVersion?: string;
  channel?: 'pilot' | 'production';
  releaseDocId?: string;
  createdAt: Timestamp | Date;
}

/**
 * Get latest commits from Firestore
 */
export async function getLatestCommits(count: number = 20): Promise<Commit[]> {
  try {
    const commitsRef = collection(firestore, 'commits');
    const q = query(commitsRef, orderBy('commitDate', 'desc'), limit(count));
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        commitSha: data.commitSha || doc.id,
        commitMessage: data.commitMessage || '',
        commitAuthor: data.commitAuthor || 'Unknown',
        commitDate: data.commitDate?.toDate ? data.commitDate.toDate() : new Date(data.commitDate),
        branch: data.branch || 'main',
        gitTag: data.gitTag || null,
        buildNumber: data.buildNumber,
        fullVersion: data.fullVersion,
        channel: data.channel,
        releaseDocId: data.releaseDocId,
        createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(data.createdAt),
      } as Commit;
    });
  } catch (error) {
    console.error('Error fetching commits:', error);
    throw error;
  }
}

/**
 * Get commit by SHA
 */
export async function getCommitBySha(commitSha: string): Promise<Commit | null> {
  try {
    const commitsRef = collection(firestore, 'commits');
    const commitDoc = await getDocs(query(commitsRef));
    const doc = commitDoc.docs.find(d => d.data().commitSha === commitSha || d.id === commitSha);
    
    if (!doc) return null;
    
    const data = doc.data();
    return {
      commitSha: data.commitSha || doc.id,
      commitMessage: data.commitMessage || '',
      commitAuthor: data.commitAuthor || 'Unknown',
      commitDate: data.commitDate?.toDate ? data.commitDate.toDate() : new Date(data.commitDate),
      branch: data.branch || 'main',
      gitTag: data.gitTag || null,
      buildNumber: data.buildNumber,
      fullVersion: data.fullVersion,
      channel: data.channel,
      releaseDocId: data.releaseDocId,
      createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(data.createdAt),
    } as Commit;
  } catch (error) {
    console.error('Error fetching commit:', error);
    return null;
  }
}

/**
 * Get GitHub commit URL
 */
export function getGitHubCommitUrl(commitSha: string, repoUrl?: string): string {
  const baseUrl = repoUrl || 'https://github.com/The-culture-connection/empowerhealth';
  return `${baseUrl}/commit/${commitSha}`;
}
