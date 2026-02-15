import { useEffect, useState } from 'react';
import { Outlet, useNavigate } from 'react-router';
import { User } from 'firebase/auth';
import { authService } from '../../services/authService';
import { databaseService } from '../../services/databaseService';
import { AuthScreen } from './AuthScreen';

export function AuthWrapper() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [hasProfile, setHasProfile] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const unsubscribe = authService.onAuthStateChanged(async (currentUser) => {
      setUser(currentUser);
      if (currentUser) {
        try {
          const exists = await databaseService.userProfileExists(currentUser.uid);
          setHasProfile(exists);
        } catch (error) {
          console.error('Error checking profile:', error);
        }
      } else {
        setHasProfile(false);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] flex items-center justify-center">
        <div className="text-center">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#663399] to-[#8855bb] flex items-center justify-center mx-auto mb-4 animate-pulse">
            <span className="text-2xl text-white">🤰</span>
          </div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return <AuthScreen />;
  }

  // If user doesn't have a profile, redirect to profile creation
  // For now, we'll just show the app - profile creation can be handled in Profile component
  return <Outlet />;
}
