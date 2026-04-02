/**
 * Mobile App Data Integration
 * Functions to read data from the mobile app's Firestore collections
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  Timestamp,
  QueryConstraint,
} from 'firebase/firestore';
import { firestore } from '../firebase/firebase';

// ============================================
// User Data
// ============================================

export interface MobileUserProfile {
  userId: string;
  name?: string;
  email?: string;
  dueDate?: Date;
  pregnancyStage?: string;
  allergies?: string[];
  medicalConditions?: string[];
  pregnancyComplications?: string[];
  birthPreference?: string;
  educationLevel?: string;
  chronicConditions?: string[];
  healthLiteracyGoals?: string[];
  createdAt?: Date;
  updatedAt?: Date;
}

/**
 * Get all user profiles (for admin dashboard)
 */
export async function getAllUserProfiles(limitCount?: number): Promise<MobileUserProfile[]> {
  const usersRef = collection(firestore, 'users');
  const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];
  if (limitCount) {
    constraints.push(limit(limitCount));
  }
  const q = query(usersRef, ...constraints);
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      userId: doc.id,
      ...data,
      dueDate: data.dueDate?.toDate(),
      createdAt: data.createdAt?.toDate(),
      updatedAt: data.updatedAt?.toDate(),
    } as MobileUserProfile;
  });
}

/**
 * Get a specific user profile
 */
export async function getUserProfile(userId: string): Promise<MobileUserProfile | null> {
  const docRef = doc(firestore, 'users', userId);
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) {
    return null;
  }

  const data = docSnap.data();
  return {
    userId: docSnap.id,
    ...data,
    dueDate: data.dueDate?.toDate(),
    createdAt: data.createdAt?.toDate(),
    updatedAt: data.updatedAt?.toDate(),
  } as MobileUserProfile;
}

// ============================================
// Journal Entries
// ============================================

export interface JournalEntry {
  id: string;
  content: string;
  tag?: string;
  isFeelingPrompt?: boolean;
  moduleTitle?: string;
  moduleId?: string;
  highlightedText?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

/**
 * Get journal entries for a user
 */
export async function getUserJournalEntries(
  userId: string,
  limitCount?: number
): Promise<JournalEntry[]> {
  const notesRef = collection(firestore, 'users', userId, 'notes');
  const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];
  if (limitCount) {
    constraints.push(limit(limitCount));
  }
  const q = query(notesRef, ...constraints);
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      ...data,
      createdAt: data.createdAt?.toDate(),
      updatedAt: data.updatedAt?.toDate(),
    } as JournalEntry;
  });
}

/**
 * Get all journal entries across all users (for analytics)
 */
export async function getAllJournalEntries(limitCount?: number): Promise<Array<JournalEntry & { userId: string }>> {
  const users = await getAllUserProfiles();
  const allEntries: Array<JournalEntry & { userId: string }> = [];

  for (const user of users.slice(0, limitCount || 100)) {
    const entries = await getUserJournalEntries(user.userId, 10);
    allEntries.push(...entries.map(e => ({ ...e, userId: user.userId })));
  }

  return allEntries;
}

// ============================================
// Learning Tasks/Modules
// ============================================

export interface LearningTask {
  id: string;
  title: string;
  description?: string;
  content?: string | Record<string, any>;
  moduleType?: string;
  trimester?: string;
  isCompleted?: boolean;
  isArchived?: boolean;
  category?: string;
  birthPlanId?: string;
  visitSummaryId?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

/**
 * Get learning tasks for a user
 */
export async function getUserLearningTasks(
  userId: string,
  limitCount?: number
): Promise<LearningTask[]> {
  const tasksRef = collection(firestore, 'users', userId, 'learning_tasks');
  const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];
  if (limitCount) {
    constraints.push(limit(limitCount));
  }
  const q = query(tasksRef, ...constraints);
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      ...data,
      createdAt: data.createdAt?.toDate(),
      updatedAt: data.updatedAt?.toDate(),
    } as LearningTask;
  });
}

/**
 * Get all learning tasks across all users (for analytics)
 */
export async function getAllLearningTasks(limitCount?: number): Promise<Array<LearningTask & { userId: string }>> {
  const users = await getAllUserProfiles();
  const allTasks: Array<LearningTask & { userId: string }> = [];

  for (const user of users.slice(0, limitCount || 100)) {
    const tasks = await getUserLearningTasks(user.userId, 10);
    allTasks.push(...tasks.map(t => ({ ...t, userId: user.userId })));
  }

  return allTasks;
}

// ============================================
// Visit Summaries
// ============================================

export interface VisitSummary {
  id: string;
  userId: string;
  appointmentDate?: Date;
  summary?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

/**
 * Get all visit summaries
 */
export async function getAllVisitSummaries(limitCount?: number): Promise<VisitSummary[]> {
  const summariesRef = collection(firestore, 'visit_summaries');
  const constraints: QueryConstraint[] = [orderBy('appointmentDate', 'desc')];
  if (limitCount) {
    constraints.push(limit(limitCount));
  }
  const q = query(summariesRef, ...constraints);
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      ...data,
      appointmentDate: data.appointmentDate?.toDate(),
      createdAt: data.createdAt?.toDate(),
      updatedAt: data.updatedAt?.toDate(),
    } as VisitSummary;
  });
}

/**
 * Get visit summaries for a specific user
 */
export async function getUserVisitSummaries(userId: string): Promise<VisitSummary[]> {
  const summariesRef = collection(firestore, 'visit_summaries');
  const q = query(summariesRef, where('userId', '==', userId), orderBy('appointmentDate', 'desc'));
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      ...data,
      appointmentDate: data.appointmentDate?.toDate(),
      createdAt: data.createdAt?.toDate(),
      updatedAt: data.updatedAt?.toDate(),
    } as VisitSummary;
  });
}

// ============================================
// Analytics Helpers
// ============================================

/**
 * Get user count by pregnancy stage
 */
export async function getUserCountByStage(): Promise<Record<string, number>> {
  const users = await getAllUserProfiles();
  const counts: Record<string, number> = {};

  users.forEach((user) => {
    const stage = user.pregnancyStage || 'unknown';
    counts[stage] = (counts[stage] || 0) + 1;
  });

  return counts;
}

/**
 * Get active users count (users who have activity in last 30 days)
 */
export async function getActiveUsersCount(days: number = 30): Promise<number> {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);

  const users = await getAllUserProfiles();
  const activeUserIds = new Set<string>();

  // Check journal entries
  const allEntries = await getAllJournalEntries(1000);
  allEntries.forEach((entry) => {
    if (entry.createdAt && entry.createdAt >= cutoffDate) {
      activeUserIds.add(entry.userId);
    }
  });

  // Check learning tasks
  const allTasks = await getAllLearningTasks(1000);
  allTasks.forEach((task) => {
    if (task.updatedAt && task.updatedAt >= cutoffDate) {
      activeUserIds.add(task.userId);
    }
  });

  // Check visit summaries
  const summaries = await getAllVisitSummaries(1000);
  summaries.forEach((summary) => {
    if (summary.appointmentDate && summary.appointmentDate >= cutoffDate) {
      activeUserIds.add(summary.userId);
    }
  });

  return activeUserIds.size;
}
