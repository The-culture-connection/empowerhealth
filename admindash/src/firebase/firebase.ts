/**
 * Firebase Initialization
 * Exports Firebase services: auth, firestore, storage, functions, messaging
 */

import { initializeApp, getApps, FirebaseApp } from 'firebase/app';
import { getAuth, Auth } from 'firebase/auth';
import { getFirestore, Firestore } from 'firebase/firestore';
import { getStorage, FirebaseStorage } from 'firebase/storage';
import { getFunctions, Functions, httpsCallable } from 'firebase/functions';
import { getMessaging, Messaging } from 'firebase/messaging';
import { getFirebaseConfig, getFunctionsUrl } from './config';

let app: FirebaseApp;
let auth: Auth;
let firestore: Firestore;
let storage: FirebaseStorage;
let functions: Functions;
let messaging: Messaging | null = null;

try {
  const config = getFirebaseConfig();
  
  // Initialize Firebase app (only if not already initialized)
  if (getApps().length === 0) {
    app = initializeApp(config);
  } else {
    app = getApps()[0];
  }

  // Initialize services
  auth = getAuth(app);
  firestore = getFirestore(app);
  storage = getStorage(app);
  
  // Initialize functions with region (default to us-central1)
  const functionsUrl = getFunctionsUrl();
  functions = getFunctions(app, functionsUrl.includes('http') ? undefined : 'us-central1');

  // Initialize messaging only if in browser and service worker is available
  if (typeof window !== 'undefined' && 'serviceWorker' in navigator) {
    try {
      messaging = getMessaging(app);
    } catch (error) {
      console.warn('Firebase Messaging not available:', error);
    }
  }
} catch (error) {
  console.error('Firebase initialization error:', error);
  throw error;
}

export { app, auth, firestore, storage, functions, messaging };
export { httpsCallable };
