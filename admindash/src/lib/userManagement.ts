/**
 * User Management Functions
 * Handles onboarding, role assignment, and user lookup
 */

import { 
  collection, 
  doc, 
  setDoc, 
  getDoc, 
  deleteDoc,
  query,
  where,
  getDocs,
  serverTimestamp
} from 'firebase/firestore';
import { firestore, functions } from '../firebase/firebase';
import { httpsCallable } from 'firebase/functions';

export type UserRole = 'admin' | 'research_partner' | 'community_manager';

interface UserRoleDoc {
  uid: string;
  email: string;
  displayName?: string;
  role: UserRole;
  createdAt: any;
  createdBy: string;
}

const ROLE_COLLECTIONS: Record<UserRole, string> = {
  admin: 'ADMIN',
  research_partner: 'RESEARCH_PARTNERS',
  community_manager: 'COMMUNITY_MANAGERS',
};

/**
 * Find mobile app user profile by email (users/{uid} in Firestore).
 */
export async function findUserByEmail(email: string): Promise<{ uid: string; email: string; displayName?: string } | null> {
  const normalized = email.trim().toLowerCase();
  if (!normalized) return null;

  const usersRef = collection(firestore, 'users');
  const q = query(usersRef, where('email', '==', normalized));
  const snapshot = await getDocs(q);

  if (!snapshot.empty) {
    const userDoc = snapshot.docs[0];
    return {
      uid: userDoc.id,
      email: userDoc.data().email,
      displayName: userDoc.data().displayName,
    };
  }

  return null;
}

/**
 * Resolve uid + email for role assignment: prefer Firestore `users` profile, then Firebase Auth (callable).
 * Auth-only accounts (no `users` doc yet) still work after the Cloud Function is deployed.
 */
export async function findUserForRoleAssignment(
  email: string
): Promise<{ uid: string; email: string; displayName?: string } | null> {
  const normalized = email.trim().toLowerCase();
  if (!normalized) return null;

  const fromProfile = await findUserByEmail(normalized);
  if (fromProfile) {
    return fromProfile;
  }

  try {
    const lookup = httpsCallable(functions, 'lookupAuthUserByEmail');
    const result = await lookup({ email: normalized });
    const authUser = result.data as { uid: string; email: string; displayName?: string } | null;
    if (!authUser) {
      return null;
    }

    const profileSnap = await getDoc(doc(firestore, 'users', authUser.uid));
    if (profileSnap.exists()) {
      const d = profileSnap.data();
      return {
        uid: authUser.uid,
        email: (typeof d.email === 'string' ? d.email : authUser.email).toLowerCase(),
        displayName: typeof d.displayName === 'string' ? d.displayName : authUser.displayName,
      };
    }

    return {
      uid: authUser.uid,
      email: authUser.email.toLowerCase(),
      displayName: authUser.displayName,
    };
  } catch (e: any) {
    console.error('findUserForRoleAssignment (Auth lookup failed):', e);
    return null;
  }
}

/**
 * Assign role to a user
 */
export async function assignRole(
  uid: string,
  email: string,
  displayName: string,
  role: UserRole,
  createdBy: string
): Promise<void> {
  // Remove from all role collections first
  await Promise.all(
    Object.values(ROLE_COLLECTIONS).map(async (collectionName) => {
      // Try to delete by uid first
      await deleteDoc(doc(firestore, collectionName, uid)).catch(() => {
        // Ignore errors if doc doesn't exist
      });
      
      // Also try to find and delete by email (in case document is keyed by email/auto-id)
      if (email) {
        try {
          const q = query(
            collection(firestore, collectionName),
            where('email', '==', email.toLowerCase())
          );
          const snapshot = await getDocs(q);
          await Promise.all(
            snapshot.docs.map((docSnap) => deleteDoc(docSnap.ref))
          );
        } catch (error) {
          // Ignore errors
        }
      }
    })
  );

  // Add to the appropriate role collection
  // IMPORTANT: Always use uid as document ID
  const roleCollection = ROLE_COLLECTIONS[role];
  const roleDoc: UserRoleDoc = {
    uid,
    email: email.toLowerCase(), // Normalize email
    displayName,
    role,
    createdAt: serverTimestamp(),
    createdBy,
  };

  // Use uid as document ID (not email or auto-generated ID)
  await setDoc(doc(firestore, roleCollection, uid), roleDoc);

  // Log audit event
  await logAuditEvent({
    action: 'role_assigned',
    targetUserId: uid,
    targetEmail: email,
    role,
    performedBy: createdBy,
  });
}

/**
 * Revoke role from a user
 */
export async function revokeRole(uid: string, role: UserRole, performedBy: string): Promise<void> {
  const roleCollection = ROLE_COLLECTIONS[role];
  await deleteDoc(doc(firestore, roleCollection, uid));

  // Log audit event
  await logAuditEvent({
    action: 'role_revoked',
    targetUserId: uid,
    role,
    performedBy,
  });
}

/**
 * Get all users with a specific role
 */
export async function getUsersByRole(role: UserRole): Promise<UserRoleDoc[]> {
  const roleCollection = ROLE_COLLECTIONS[role];
  const snapshot = await getDocs(collection(firestore, roleCollection));

  return snapshot.docs.map((docSnap) => {
    const data = docSnap.data();
    const createdRaw = data.createdAt;
    const createdAt =
      createdRaw && typeof createdRaw.toDate === 'function'
        ? createdRaw.toDate()
        : createdRaw;

    // Document ID is always the user's uid; older docs may omit `uid` / `role` fields
    const uid = typeof data.uid === 'string' && data.uid ? data.uid : docSnap.id;
    const roleField = data.role === 'admin' || data.role === 'research_partner' || data.role === 'community_manager'
      ? data.role
      : role;

    return {
      ...data,
      uid,
      role: roleField,
      email: typeof data.email === 'string' ? data.email : '',
      createdBy: typeof data.createdBy === 'string' ? data.createdBy : '',
      createdAt,
    } as UserRoleDoc;
  });
}

/**
 * Get user's current role
 */
export async function getUserRole(uid: string): Promise<UserRole | null> {
  for (const [role, collectionName] of Object.entries(ROLE_COLLECTIONS)) {
    const docRef = doc(firestore, collectionName, uid);
    const docSnap = await getDoc(docRef);
    if (docSnap.exists()) {
      return role as UserRole;
    }
  }
  return null;
}

/**
 * Log audit event
 */
async function logAuditEvent(event: {
  action: string;
  targetUserId?: string;
  targetEmail?: string;
  role?: UserRole;
  performedBy: string;
  metadata?: Record<string, any>;
}): Promise<void> {
  try {
    await setDoc(doc(firestore, 'audit_logs', `${Date.now()}_${event.performedBy}`), {
      ...event,
      timestamp: serverTimestamp(),
    });
  } catch (error) {
    console.error('Failed to log audit event:', error);
  }
}
