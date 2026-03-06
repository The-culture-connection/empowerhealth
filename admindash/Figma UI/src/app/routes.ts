import { createBrowserRouter } from "react-router";
import { Layout } from "./components/Layout";
import { TechnologyLayout } from "./components/TechnologyLayout";
import { Dashboard } from "./pages/Dashboard";
import { Documentation } from "./pages/Documentation";
import { ReleasesAndBuilds } from "./pages/ReleasesAndBuilds";
import { SystemStatus } from "./pages/SystemStatus";
import { UsersAndRoles } from "./pages/UsersAndRoles";
import { Analytics } from "./pages/Analytics";
import { Reports } from "./pages/Reports";
import { Notifications } from "./pages/Notifications";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Layout,
    children: [
      { index: true, Component: Dashboard },
      { path: "documentation", Component: Documentation },
      {
        path: "technology",
        Component: TechnologyLayout,
        children: [
          { index: true, Component: ReleasesAndBuilds },
          { path: "system-status", Component: SystemStatus },
        ],
      },
      { path: "users-roles", Component: UsersAndRoles },
      { path: "analytics", Component: Analytics },
      { path: "reports", Component: Reports },
      { path: "notifications", Component: Notifications },
    ],
  },
]);