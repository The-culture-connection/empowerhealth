/**
 * Firebase Configuration Loader
 * Validates required environment variables and provides Firebase config
 */

const requiredEnvVars = [
  'VITE_FIREBASE_API_KEY',
  'VITE_FIREBASE_AUTH_DOMAIN',
  'VITE_FIREBASE_PROJECT_ID',
  'VITE_FIREBASE_STORAGE_BUCKET',
  'VITE_FIREBASE_MESSAGING_SENDER_ID',
  'VITE_FIREBASE_APP_ID',
];

export interface FirebaseConfig {
  apiKey: string;
  authDomain: string;
  projectId: string;
  storageBucket: string;
  messagingSenderId: string;
  appId: string;
  measurementId?: string;
}

export function getFirebaseConfig(): FirebaseConfig {
  const missing: string[] = [];
  const env = import.meta.env as unknown as Record<string, string | undefined>;
  
  for (const key of requiredEnvVars) {
    if (!env[key]) {
      missing.push(key);
    }
  }

  if (missing.length > 0) {
    throw new Error(
      `Missing required Firebase environment variables: ${missing.join(', ')}\n` +
      `Please create a .env.local file with your Firebase credentials.`
    );
  }

  return {
    apiKey: env.VITE_FIREBASE_API_KEY!,
    authDomain: env.VITE_FIREBASE_AUTH_DOMAIN!,
    projectId: env.VITE_FIREBASE_PROJECT_ID!,
    storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET!,
    messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID!,
    appId: env.VITE_FIREBASE_APP_ID!,
    measurementId: env.VITE_FIREBASE_MEASUREMENT_ID,
  };
}

export function getFunctionsUrl(): string {
  const env = import.meta.env as unknown as Record<string, string | undefined>;
  return env.VITE_FUNCTIONS_URL || 
    `https://${env.VITE_FIREBASE_AUTH_DOMAIN?.replace('.firebaseapp.com', '')}-default-rtdb.firebaseio.com`;
}
