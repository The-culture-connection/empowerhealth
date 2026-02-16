import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  getDocs,
  addDoc,
  orderBy,
  limit,
  onSnapshot,
  Timestamp,
  QuerySnapshot,
  DocumentData,
} from 'firebase/firestore';
import { db } from '../config/firebase';

export interface UserProfile {
  userId: string;
  name?: string;
  email?: string;
  dueDate?: string;
  currentWeek?: number;
  trimester?: string;
  birthPartner?: string;
  emergencyContact?: string;
  insurance?: {
    provider?: string;
    memberId?: string;
  };
  careTeam?: Array<{
    name: string;
    role: string;
    practice?: string;
  }>;
  chronicConditions?: string[];
  medications?: string[];
  allergies?: string[];
  createdAt?: Date;
  updatedAt?: Date;
}

export interface JournalEntry {
  id?: string;
  userId: string;
  content: string;
  mood?: string;
  prompt?: string;
  isFeelingPrompt?: boolean;
  createdAt: Date;
  updatedAt?: Date;
}

export interface BirthPlan {
  id?: string;
  userId: string;
  supportTeam?: {
    whoWithYou?: string;
    doula?: string;
  };
  environment?: string[];
  painManagement?: string[];
  afterBirth?: {
    skinToSkin?: string;
    feeding?: string;
  };
  emergencyDecisionMaker?: string;
  additionalNotes?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface VisitSummary {
  id?: string;
  userId: string;
  date: Date;
  providerName?: string;
  visitType?: string;
  summary?: string;
  flagged?: boolean;
  createdAt?: Date;
}

export interface LearningTask {
  id?: string;
  userId: string;
  title: string;
  description?: string;
  content?: string | any;
  trimester?: string;
  week?: number;
  isGenerated?: boolean;
  isCompleted?: boolean;
  progress?: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export class DatabaseService {
  // User Profile
  async saveUserProfile(profile: UserProfile): Promise<void> {
    try {
      const profileRef = doc(db, 'users', profile.userId);
      await setDoc(profileRef, {
        ...profile,
        updatedAt: Timestamp.now(),
      }, { merge: true });
    } catch (error: any) {
      throw new Error(`Error saving user profile: ${error.message}`);
    }
  }

  async getUserProfile(userId: string): Promise<UserProfile | null> {
    try {
      const profileRef = doc(db, 'users', userId);
      const docSnap = await getDoc(profileRef);
      if (docSnap.exists()) {
        const data = docSnap.data();
        return {
          ...data,
          createdAt: data.createdAt?.toDate(),
          updatedAt: data.updatedAt?.toDate(),
        } as UserProfile;
      }
      return null;
    } catch (error: any) {
      throw new Error(`Error getting user profile: ${error.message}`);
    }
  }

  streamUserProfile(userId: string, callback: (profile: UserProfile | null) => void) {
    const profileRef = doc(db, 'users', userId);
    return onSnapshot(profileRef, (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        callback({
          ...data,
          createdAt: data.createdAt?.toDate(),
          updatedAt: data.updatedAt?.toDate(),
        } as UserProfile);
      } else {
        callback(null);
      }
    });
  }

  async updateUserProfile(userId: string, updates: Partial<UserProfile>): Promise<void> {
    try {
      const profileRef = doc(db, 'users', userId);
      await updateDoc(profileRef, {
        ...updates,
        updatedAt: Timestamp.now(),
      });
    } catch (error: any) {
      throw new Error(`Error updating user profile: ${error.message}`);
    }
  }

  async userProfileExists(userId: string): Promise<boolean> {
    try {
      const profileRef = doc(db, 'users', userId);
      const docSnap = await getDoc(profileRef);
      return docSnap.exists();
    } catch (error: any) {
      return false;
    }
  }

  // Journal Entries
  async saveJournalEntry(entry: JournalEntry): Promise<string> {
    try {
      const entriesRef = collection(db, 'users', entry.userId, 'notes');
      const docRef = await addDoc(entriesRef, {
        ...entry,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
      return docRef.id;
    } catch (error: any) {
      throw new Error(`Error saving journal entry: ${error.message}`);
    }
  }

  async getJournalEntries(userId: string, limitCount: number = 50): Promise<JournalEntry[]> {
    try {
      const entriesRef = collection(db, 'users', userId, 'notes');
      const q = query(entriesRef, orderBy('createdAt', 'desc'), limit(limitCount));
      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as JournalEntry[];
    } catch (error: any) {
      throw new Error(`Error getting journal entries: ${error.message}`);
    }
  }

  streamJournalEntries(userId: string, callback: (entries: JournalEntry[]) => void) {
    const entriesRef = collection(db, 'users', userId, 'notes');
    const q = query(entriesRef, orderBy('createdAt', 'desc'));
    return onSnapshot(q, (querySnapshot) => {
      const entries = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as JournalEntry[];
      callback(entries);
    });
  }

  // Birth Plans
  async saveBirthPlan(plan: BirthPlan): Promise<string> {
    try {
      if (plan.id) {
        const planRef = doc(db, 'users', plan.userId, 'birthPlans', plan.id);
        await updateDoc(planRef, {
          ...plan,
          updatedAt: Timestamp.now(),
        });
        return plan.id;
      } else {
        const plansRef = collection(db, 'users', plan.userId, 'birthPlans');
        const docRef = await addDoc(plansRef, {
          ...plan,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        });
        return docRef.id;
      }
    } catch (error: any) {
      throw new Error(`Error saving birth plan: ${error.message}`);
    }
  }

  async getBirthPlans(userId: string): Promise<BirthPlan[]> {
    try {
      const plansRef = collection(db, 'users', userId, 'birthPlans');
      const q = query(plansRef, orderBy('createdAt', 'desc'));
      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as BirthPlan[];
    } catch (error: any) {
      throw new Error(`Error getting birth plans: ${error.message}`);
    }
  }

  // Visit Summaries
  async saveVisitSummary(summary: VisitSummary): Promise<string> {
    try {
      const summariesRef = collection(db, 'users', summary.userId, 'visitSummaries');
      const docRef = await addDoc(summariesRef, {
        ...summary,
        date: Timestamp.fromDate(summary.date),
        createdAt: Timestamp.now(),
      });
      return docRef.id;
    } catch (error: any) {
      throw new Error(`Error saving visit summary: ${error.message}`);
    }
  }

  async getVisitSummaries(userId: string): Promise<VisitSummary[]> {
    try {
      const summariesRef = collection(db, 'users', userId, 'visitSummaries');
      const q = query(summariesRef, orderBy('date', 'desc'));
      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        date: doc.data().date?.toDate() || new Date(),
        createdAt: doc.data().createdAt?.toDate(),
      })) as VisitSummary[];
    } catch (error: any) {
      throw new Error(`Error getting visit summaries: ${error.message}`);
    }
  }

  // Learning Tasks
  async getLearningTasks(userId: string): Promise<LearningTask[]> {
    try {
      const tasksRef = collection(db, 'learning_tasks');
      const q = query(
        tasksRef,
        where('userId', '==', userId),
        where('isGenerated', '==', true),
        orderBy('createdAt', 'desc')
      );
      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as LearningTask[];
    } catch (error: any) {
      throw new Error(`Error getting learning tasks: ${error.message}`);
    }
  }

  streamLearningTasks(userId: string, callback: (tasks: LearningTask[]) => void) {
    const tasksRef = collection(db, 'learning_tasks');
    const q = query(
      tasksRef,
      where('userId', '==', userId),
      where('isGenerated', '==', true),
      orderBy('createdAt', 'desc')
    );
    return onSnapshot(q, (querySnapshot) => {
      const tasks = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as LearningTask[];
      callback(tasks);
    });
  }

  async updateLearningTask(taskId: string, updates: Partial<LearningTask>): Promise<void> {
    try {
      const taskRef = doc(db, 'learning_tasks', taskId);
      await updateDoc(taskRef, {
        ...updates,
        updatedAt: Timestamp.now(),
      });
    } catch (error: any) {
      throw new Error(`Error updating learning task: ${error.message}`);
    }
  }
}

export const databaseService = new DatabaseService();
export type { LearningTask };
