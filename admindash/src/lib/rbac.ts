/**
 * Role-Based Access Control Utilities
 * Helper functions for checking user roles and permissions
 */

import { doc, getDoc } from 'firebase/firestore';
import { firestore } from '../firebase/firebase';

export type UserRole = 'admin' | 'research_partner' | 'community_manager' | null;

/**
 * Get user role from Firestore collections
 * Checks in priority order: ADMIN > RESEARCH_PARTNERS > COMMUNITY_MANAGERS
 * 
 * @param uid - User ID
 * @returns User role or null if not found
 */
export async function getUserRole(uid: string): Promise<UserRole> {
  try {
    // Check ADMIN collection
    const adminDoc = await getDoc(doc(firestore, 'ADMIN', uid));
    if (adminDoc.exists()) {
      console.log('[RBAC] Found admin role for uid:', uid);
      return 'admin';
    }

    // Check RESEARCH_PARTNERS collection
    const researchDoc = await getDoc(doc(firestore, 'RESEARCH_PARTNERS', uid));
    if (researchDoc.exists()) {
      console.log('[RBAC] Found research_partner role for uid:', uid);
      return 'research_partner';
    }

    // Check COMMUNITY_MANAGERS collection
    const communityDoc = await getDoc(doc(firestore, 'COMMUNITY_MANAGERS', uid));
    if (communityDoc.exists()) {
      console.log('[RBAC] Found community_manager role for uid:', uid);
      return 'community_manager';
    }

    console.warn('[RBAC] No role found for uid:', uid);
    return null;
  } catch (error) {
    console.error('[RBAC] Error getting user role:', error);
    return null;
  }
}

/**
 * Check if user has a specific role
 */
export function hasRole(userRole: UserRole | null, requiredRole: UserRole | UserRole[]): boolean {
  if (!userRole) return false;
  
  if (Array.isArray(requiredRole)) {
    return requiredRole.includes(userRole);
  }
  
  return userRole === requiredRole;
}

/**
 * Check if user is admin
 */
export function isAdmin(userRole: UserRole | null): boolean {
  return userRole === 'admin';
}

/**
 * Check if user is research partner
 */
export function isResearchPartner(userRole: UserRole | null): boolean {
  return userRole === 'research_partner';
}

/**
 * Check if user is community manager
 */
export function isCommunityManager(userRole: UserRole | null): boolean {
  return userRole === 'community_manager';
}
