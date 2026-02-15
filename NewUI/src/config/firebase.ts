import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getFunctions } from 'firebase/functions';

const firebaseConfig = {
  apiKey: 'AIzaSyA2arGVVaRoFBJ8Bhpq6oPuvIbM8d5gzhM',
  authDomain: 'empower-health-watch.firebaseapp.com',
  projectId: 'empower-health-watch',
  storageBucket: 'empower-health-watch.firebasestorage.app',
  messagingSenderId: '725364003316',
  appId: '1:725364003316:web:1411a89c67dc93338229a1',
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const functions = getFunctions(app);

export default app;
