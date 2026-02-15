import { RouterProvider } from 'react-router';
import { Suspense } from 'react';
import { router } from './routes';
import { LoadingFallback } from './components/LoadingFallback';

export default function App() {
  return (
    <Suspense fallback={<LoadingFallback />}>
      <RouterProvider router={router} />
    </Suspense>
  );
}
