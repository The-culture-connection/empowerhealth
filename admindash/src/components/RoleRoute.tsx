/**
 * Role-based Route Protection
 * Wraps routes to enforce role-based access control
 */

import { Navigate, useLocation } from 'react-router';
import { useAuth, UserRole } from '../contexts/AuthContext';
import { auth } from '../firebase/firebase';

interface RoleRouteProps {
  children: React.ReactNode;
  allowedRoles: UserRole | UserRole[];
  fallbackPath?: string;
}

export function RoleRoute({ 
  children, 
  allowedRoles, 
  fallbackPath = '/login' 
}: RoleRouteProps) {
  const { userProfile, loading } = useAuth();
  const location = useLocation();

  // Session exists but profile not hydrated yet (should be brief after auth listener runs)
  const sessionPendingProfile =
    !loading && auth.currentUser && !userProfile;

  if (loading || sessionPendingProfile) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-lg mb-2" style={{ color: 'var(--warm-600)' }}>
            Loading...
          </div>
        </div>
      </div>
    );
  }

  if (!userProfile) {
    return <Navigate to={fallbackPath} state={{ from: location }} replace />;
  }

  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];
  const hasAccess = roles.includes(userProfile.role);

  if (!hasAccess) {
    return (
      <div className="min-h-screen flex items-center justify-center p-8">
        <div className="max-w-md w-full p-8 rounded-2xl border text-center" style={{
          backgroundColor: 'white',
          borderColor: 'var(--lavender-200)',
        }}>
          <h1 className="text-2xl mb-4" style={{ color: 'var(--warm-600)' }}>
            Access Denied
          </h1>
          <p style={{ color: 'var(--warm-500)' }}>
            You don't have permission to access this page. Required role: {roles.join(' or ')}.
          </p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
