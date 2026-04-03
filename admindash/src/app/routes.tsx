import { createBrowserRouter, Navigate, Outlet } from "react-router";
import { Layout } from "./components/Layout";
import { TechnologyLayout } from "./components/TechnologyLayout";
import { Documentation } from "./pages/Documentation";
import { TechnologyOverview } from "./pages/TechnologyOverview";
import { TechnologyInstructions } from "./pages/TechnologyInstructions";
import { UsersAndRoles } from "./pages/UsersAndRoles";
import { Analytics } from "./pages/Analytics";
import { AnalyticsInfo } from "./pages/AnalyticsInfo";
import { Reports } from "./pages/Reports";
import { Notifications } from "./pages/Notifications";
import { ModerationHub } from "./pages/ModerationHub";
import { ProviderModeration } from "./pages/ProviderModeration";
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
            <Analytics />
          </RoleRoute>
        )
      },
      {
        path: "analytics",
        element: <Navigate to="/" replace />,
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
        path: "analytics/info", 
        element: (
          <RoleRoute allowedRoles={['admin', 'research_partner', 'community_manager']}>
            <AnalyticsInfo />
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
        element: <Navigate to="/moderation/push" replace />,
      },
      {
        path: "moderation",
        element: (
          <RoleRoute allowedRoles={["admin", "community_manager"]}>
            <Outlet />
          </RoleRoute>
        ),
        children: [
          { index: true, element: <ModerationHub /> },
          { path: "push", element: <Notifications /> },
          {
            path: "providers",
            element: (
              <RoleRoute allowedRoles={["admin"]}>
                <ProviderModeration />
              </RoleRoute>
            ),
          },
        ],
      },
    ],
  },
]);
