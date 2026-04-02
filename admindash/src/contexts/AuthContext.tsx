/**
 * Authentication Context
 * Manages user authentication state and role-based access control
 */

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { 
  User, 
  signInWithEmailAndPassword, 
  signOut as firebaseSignOut,
  onAuthStateChanged,
  sendPasswordResetEmail
} from 'firebase/auth';
import { 
  doc, 
  getDoc, 
  collection,
  query,
  where,
  getDocs
} from 'firebase/firestore';
import { auth, firestore } from '../firebase/firebase';

export type UserRole = 'admin' | 'research_partner' | 'community_manager' | null;

interface UserProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  role: UserRole;
  createdAt?: Date;
  createdBy?: string;
}

interface AuthContextType {
  user: User | null;
  userProfile: UserProfile | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  hasRole: (role: UserRole | UserRole[]) => boolean;
  isAdmin: () => boolean;
  isResearchPartner: () => boolean;
  isCommunityManager: () => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  // Resolve user role from Firestore collections
  async function resolveUserRole(uid: string, email: string | null): Promise<UserRole> {
    try {
      // First, try by uid (standard approach)
      const adminDoc = await getDoc(doc(firestore, 'ADMIN', uid));
      if (adminDoc.exists()) {
        if (import.meta.env.DEV) {
          console.debug('Found admin role by uid:', uid);
        }
        return 'admin';
      }

      const researchDoc = await getDoc(doc(firestore, 'RESEARCH_PARTNERS', uid));
      if (researchDoc.exists()) {
        if (import.meta.env.DEV) {
          console.debug('Found research_partner role by uid:', uid);
        }
        return 'research_partner';
      }

      const communityDoc = await getDoc(doc(firestore, 'COMMUNITY_MANAGERS', uid));
      if (communityDoc.exists()) {
        if (import.meta.env.DEV) {
          console.debug('Found community_manager role by uid:', uid);
        }
        return 'community_manager';
      }

      // Fallback: If not found by uid, try by email (in case document is keyed by email)
      if (email) {
        if (import.meta.env.DEV) {
          console.debug('Role not found by uid, trying by email:', email);
        }

        // Query ADMIN collection by email
        const adminQuery = query(
          collection(firestore, 'ADMIN'),
          where('email', '==', email.toLowerCase())
        );
        const adminSnapshot = await getDocs(adminQuery);
        if (!adminSnapshot.empty) {
          return 'admin';
        }

        // Query RESEARCH_PARTNERS collection by email
        const researchQuery = query(
          collection(firestore, 'RESEARCH_PARTNERS'),
          where('email', '==', email.toLowerCase())
        );
        const researchSnapshot = await getDocs(researchQuery);
        if (!researchSnapshot.empty) {
          return 'research_partner';
        }

        // Query COMMUNITY_MANAGERS collection by email
        const communityQuery = query(
          collection(firestore, 'COMMUNITY_MANAGERS'),
          where('email', '==', email.toLowerCase())
        );
        const communitySnapshot = await getDocs(communityQuery);
        if (!communitySnapshot.empty) {
          return 'community_manager';
        }
      }

      if (import.meta.env.DEV) {
        console.warn('No role found for user:', { uid, email });
      }
      return null;
    } catch (error) {
      console.error('Error resolving user role:', error);
      return null;
    }
  }

  // Load user profile when auth state changes
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      setLoading(true);
      setUser(firebaseUser);

      if (firebaseUser) {
        try {
          if (import.meta.env.DEV) {
            console.debug('Resolving role for user:', { uid: firebaseUser.uid, email: firebaseUser.email });
          }
          const role = await resolveUserRole(firebaseUser.uid, firebaseUser.email);
          if (import.meta.env.DEV) {
            console.debug('Resolved role:', role);
          }
          setUserProfile({
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            role,
          });
        } catch (error) {
          console.error('[RBAC] Error resolving user role:', error);
          setUserProfile({
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            role: null,
          });
        }
      } else {
        setUserProfile(null);
      }

      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  /**
   * Only establishes the Firebase session. Role and userProfile are applied in
   * onAuthStateChanged so we never navigate with loading=false and userProfile=null.
   */
  async function signIn(email: string, password: string) {
    await signInWithEmailAndPassword(auth, email, password);
  }

  async function signOut() {
    await firebaseSignOut(auth);
    setUserProfile(null);
  }

  async function resetPassword(email: string) {
    await sendPasswordResetEmail(auth, email);
  }

  function hasRole(role: UserRole | UserRole[]): boolean {
    if (!userProfile) return false;
    if (Array.isArray(role)) {
      return role.includes(userProfile.role);
    }
    return userProfile.role === role;
  }

  function isAdmin(): boolean {
    return hasRole('admin');
  }

  function isResearchPartner(): boolean {
    return hasRole('research_partner');
  }

  function isCommunityManager(): boolean {
    return hasRole('community_manager');
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        userProfile,
        loading,
        signIn,
        signOut,
        resetPassword,
        hasRole,
        isAdmin,
        isResearchPartner,
        isCommunityManager,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
