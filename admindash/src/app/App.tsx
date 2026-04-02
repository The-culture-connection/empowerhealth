import { useEffect } from "react";
import { RouterProvider } from "react-router";
import { router } from "./routes";
import { AuthProvider } from "../contexts/AuthContext";
import { ErrorBoundary } from "../components/ErrorBoundary";
import { logEvent } from "../lib/analytics";
import "../styles/empowerhealth.css";

// Generate or retrieve session ID
function getSessionId(): string {
  const storageKey = 'app_session_id';
  const timestamp = Date.now();
  
  // Check if we have a session ID in sessionStorage
  let sessionId = sessionStorage.getItem(storageKey);
  
  // If no session ID, create a new one
  if (!sessionId) {
    sessionId = `session_${timestamp}_${Math.random().toString(36).substring(2, 11)}`;
    sessionStorage.setItem(storageKey, sessionId);
  }
  
  return sessionId;
}

export default function App() {
  // Track app open event
  useEffect(() => {
    const sessionId = getSessionId();
    
    logEvent({
      eventName: 'app_open',
      feature: 'app',
      metadata: {
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        platform: navigator.platform,
      },
      sessionId,
    }).catch((error) => {
      // Silently fail - analytics shouldn't break the app
      console.warn('Failed to log app_open event:', error);
    });
  }, []);

  return (
    <ErrorBoundary>
      <AuthProvider>
        <RouterProvider router={router} />
      </AuthProvider>
    </ErrorBoundary>
  );
}
