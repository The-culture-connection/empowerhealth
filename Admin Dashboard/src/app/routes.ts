import { createBrowserRouter } from "react-router";
import { Layout } from "./components/Layout";
import { Dashboard } from "./pages/Dashboard";
import { Documentation } from "./pages/Documentation";
import { TechnologyOverview } from "./pages/TechnologyOverview";
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
      { path: "technology", Component: TechnologyOverview },
      { path: "users-roles", Component: UsersAndRoles },
      { path: "analytics", Component: Analytics },
      { path: "reports", Component: Reports },
      { path: "notifications", Component: Notifications },
    ],
  },
]);