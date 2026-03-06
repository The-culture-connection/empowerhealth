/**
 * Firebase Client Library
 * Exports Firebase services and utilities
 */

export { auth, firestore, storage, functions, messaging } from '../firebase/firebase';
export { getFirebaseConfig } from '../firebase/config';

/**
 * Get current authenticated user
 */
import { auth } from '../firebase/firebase';
import { User } from 'firebase/auth';

export async function getCurrentUser(): Promise<User | null> {
  return new Promise((resolve) => {
    const unsubscribe = auth.onAuthStateChanged((user) => {
      unsubscribe();
      resolve(user);
    });
  });
}
