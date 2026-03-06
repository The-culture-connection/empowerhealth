/**
 * Debug component to help diagnose role resolution issues
 * Add this temporarily to see what's happening
 */

import { useEffect, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { doc, getDoc, collection, getDocs, query, where } from 'firebase/firestore';
import { firestore } from '../firebase/firebase';

export function RoleDebug() {
  const { user, userProfile } = useAuth();
  const [debugInfo, setDebugInfo] = useState<any>(null);

  useEffect(() => {
    async function checkRole() {
      if (!user) return;

      const info: any = {
        uid: user.uid,
        email: user.email,
        resolvedRole: userProfile?.role,
      };

      try {
        // Check ADMIN by uid
        const adminDoc = await getDoc(doc(firestore, 'ADMIN', user.uid));
        info.adminByUid = {
          exists: adminDoc.exists(),
          data: adminDoc.exists() ? adminDoc.data() : null,
        };

        // Check ADMIN by email
        if (user.email) {
          const adminQuery = query(
            collection(firestore, 'ADMIN'),
            where('email', '==', user.email.toLowerCase())
          );
          const adminSnapshot = await getDocs(adminQuery);
          info.adminByEmail = {
            count: adminSnapshot.size,
            docs: adminSnapshot.docs.map(d => ({ id: d.id, data: d.data() })),
          };
        }

        // List all ADMIN docs (first 5)
        const allAdminQuery = query(collection(firestore, 'ADMIN'), where('email', '!=', ''));
        const allAdminSnapshot = await getDocs(allAdminQuery);
        info.allAdminDocs = allAdminSnapshot.docs.slice(0, 5).map(d => ({
          id: d.id,
          email: d.data().email,
        }));

        setDebugInfo(info);
      } catch (error: any) {
        info.error = error.message;
        setDebugInfo(info);
      }
    }

    checkRole();
  }, [user, userProfile]);

  if (!debugInfo) return null;

  return (
    <div className="p-4 m-4 rounded-lg border" style={{
      backgroundColor: '#fef3c7',
      borderColor: '#fbbf24',
    }}>
      <h3 className="font-bold mb-2" style={{ color: '#92400e' }}>Role Debug Info</h3>
      <pre className="text-xs overflow-auto" style={{ color: '#92400e' }}>
        {JSON.stringify(debugInfo, null, 2)}
      </pre>
    </div>
  );
}
