/**
 * Login Page
 * Handles user authentication
 */

import { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router';
import { useAuth } from '../../contexts/AuthContext';
import { LogIn } from 'lucide-react';

export function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const { signIn, user, userProfile, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const from = (location.state as { from?: { pathname: string } })?.from?.pathname || '/';

  // No dashboard role (session exists but not in ADMIN / RESEARCH_PARTNERS / COMMUNITY_MANAGERS)
  useEffect(() => {
    if (authLoading) return;
    if (!user || !userProfile) {
      setError('');
      return;
    }
    if (userProfile.role === null) {
      setError('You do not have access to the admin dashboard. Contact an administrator.');
    } else {
      setError('');
    }
  }, [authLoading, user, userProfile]);

  // Navigate only after Firebase auth + Firestore role resolution completes (avoids double sign-in)
  useEffect(() => {
    if (authLoading) return;
    if (!user || !userProfile || userProfile.role === null) return;
    navigate(from, { replace: true });
  }, [authLoading, user, userProfile, navigate, from]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setSubmitting(true);

    try {
      await signIn(email, password);
    } catch (err: any) {
      setError(err.message || 'Failed to sign in');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-8" style={{ backgroundColor: 'var(--eh-background)' }}>
      <div className="max-w-md w-full p-8 rounded-2xl border" style={{
        backgroundColor: 'white',
        borderColor: 'var(--lavender-200)',
      }}>
        <div className="text-center mb-8">
          <h1 className="text-3xl mb-2" style={{ color: 'var(--warm-600)' }}>
            EmpowerHealth
          </h1>
          <p style={{ color: 'var(--warm-500)' }}>
            Admin Dashboard
          </p>
        </div>

        {error && (
          <div className="mb-4 p-4 rounded-xl" style={{ 
            backgroundColor: '#fee2e2',
            color: '#dc2626',
          }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
              Email Address
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full px-4 py-3 rounded-xl border"
              style={{
                backgroundColor: 'var(--warm-50)',
                borderColor: 'var(--lavender-200)',
              }}
              placeholder="admin@empowerhealth.org"
            />
          </div>

          <div>
            <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
              Password
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full px-4 py-3 rounded-xl border"
              style={{
                backgroundColor: 'var(--warm-50)',
                borderColor: 'var(--lavender-200)',
              }}
              placeholder="••••••••"
            />
          </div>

          <button
            type="submit"
            disabled={submitting || authLoading}
            className="w-full flex items-center justify-center gap-2 px-6 py-3 rounded-xl shadow-sm hover:shadow-md transition-all disabled:opacity-50"
            style={{
              backgroundColor: 'var(--lavender-500)',
              color: 'white',
            }}
          >
            <LogIn className="w-5 h-5" />
            {submitting || authLoading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>
      </div>
    </div>
  );
}
