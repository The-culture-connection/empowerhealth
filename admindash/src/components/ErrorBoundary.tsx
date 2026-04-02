/**
 * Error Boundary Component
 * Displays admin-friendly error screen if Firebase config is missing
 */

import { Component, ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: unknown) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      const error = this.state.error;
      const isConfigError = error?.message?.includes('Firebase') || 
                          error?.message?.includes('environment variables');

      return (
        <div className="min-h-screen flex items-center justify-center p-8" style={{ backgroundColor: 'var(--eh-background)' }}>
          <div className="max-w-2xl w-full p-8 rounded-2xl border" style={{
            backgroundColor: 'white',
            borderColor: 'var(--lavender-200)',
          }}>
            <h1 className="text-2xl mb-4" style={{ color: 'var(--warm-600)' }}>
              Configuration Error
            </h1>
            
            {isConfigError ? (
              <>
                <p className="mb-4" style={{ color: 'var(--warm-500)' }}>
                  {error?.message}
                </p>
                <div className="p-4 rounded-xl mb-4" style={{ backgroundColor: 'var(--lavender-50)' }}>
                  <h3 className="mb-2 font-semibold" style={{ color: 'var(--lavender-600)' }}>
                    Setup Instructions:
                  </h3>
                  <ol className="list-decimal list-inside space-y-2 text-sm" style={{ color: 'var(--warm-600)' }}>
                    <li>Copy <code className="px-2 py-1 rounded" style={{ backgroundColor: 'var(--warm-100)' }}>.env.local.example</code> to <code className="px-2 py-1 rounded" style={{ backgroundColor: 'var(--warm-100)' }}>.env.local</code></li>
                    <li>Fill in your Firebase project credentials from the Firebase Console</li>
                    <li>Restart the development server</li>
                  </ol>
                </div>
              </>
            ) : (
              <p className="mb-4" style={{ color: 'var(--warm-500)' }}>
                An unexpected error occurred. Please refresh the page or contact support.
              </p>
            )}

            <button
              onClick={() => window.location.reload()}
              className="px-6 py-3 rounded-xl"
              style={{
                backgroundColor: 'var(--lavender-500)',
                color: 'white',
              }}
            >
              Reload Page
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
