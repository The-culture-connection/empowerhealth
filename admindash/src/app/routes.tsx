import { createBrowserRouter } from "react-router";
import { Layout } from "./components/Layout";
import { TechnologyLayout } from "./components/TechnologyLayout";
import { Dashboard } from "./pages/Dashboard";
import { Documentation } from "./pages/Documentation";
import { TechnologyOverview } from "./pages/TechnologyOverview";
import { SystemStatus } from "./pages/SystemStatus";
import { TechnologyInstructions } from "./pages/TechnologyInstructions";
import { UsersAndRoles } from "./pages/UsersAndRoles";
import { Analytics } from "./pages/Analytics";
import { Reports } from "./pages/Reports";
import { Notifications } from "./pages/Notifications";
import { Login } from "./pages/Login";
import { RoleRoute } from "../components/RoleRoute";

export const router = createBrowserRouter([
  {
    path: "/login",
    Component: Login,
  },
  {
    path: "/",
    Component: Layout,
    children: [
      { 
        index: true, 
        element: (
          <RoleRoute allowedRoles={['admin', 'research_partner', 'community_manager']}>
            <Dashboard />
          </RoleRoute>
        )
      },
      { 
        path: "documentation", 
        element: (
          <RoleRoute allowedRoles={['admin', 'research_partner', 'community_manager']}>
            <Documentation />
          </RoleRoute>
        )
      },
      {
        path: "technology",
        element: (
          <RoleRoute allowedRoles={['admin', 'research_partner', 'community_manager']}>
            <TechnologyLayout />
          </RoleRoute>
        ),
        children: [
          {
            index: true,
            element: <TechnologyOverview />
          },
          {
            path: "system-status",
            element: <SystemStatus />
          },
          {
            path: "instructions",
            element: <TechnologyInstructions />
          },
        ],
      },
      { 
        path: "users-roles", 
        element: (
          <RoleRoute allowedRoles={['admin']}>
            <UsersAndRoles />
          </RoleRoute>
        )
      },
      { 
        path: "analytics", 
        element: (
          <RoleRoute allowedRoles={['admin', 'research_partner', 'community_manager']}>
            <Analytics />
          </RoleRoute>
        )
      },
      { 
        path: "reports", 
        element: (
          <RoleRoute allowedRoles={['admin', 'research_partner']}>
            <Reports />
          </RoleRoute>
        )
      },
      { 
        path: "notifications", 
        element: (
          <RoleRoute allowedRoles={['admin', 'community_manager']}>
            <Notifications />
          </RoleRoute>
        )
      },
    ],
  },
]);
