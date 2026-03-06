import { RouterProvider } from "react-router";
import { router } from "./routes";
import { AuthProvider } from "../contexts/AuthContext";
import { ErrorBoundary } from "../components/ErrorBoundary";
import "../styles/empowerhealth.css";

export default function App() {
  return (
    <ErrorBoundary>
      <AuthProvider>
        <RouterProvider router={router} />
      </AuthProvider>
    </ErrorBoundary>
  );
}
