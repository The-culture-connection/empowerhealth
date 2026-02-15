import { createBrowserRouter } from "react-router";
import { Layout } from "./components/Layout";
import { Home } from "./components/Home";
import { Learning } from "./components/Learning";
import { AfterVisit } from "./components/AfterVisit";
import { BirthPlan } from "./components/BirthPlan";
import { Journal } from "./components/Journal";
import { Community } from "./components/Community";
import { Profile } from "./components/Profile";
import { ProviderSearch } from "./components/ProviderSearch";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Layout,
    children: [
      { index: true, Component: Home },
      { path: "learning", Component: Learning },
      { path: "after-visit", Component: AfterVisit },
      { path: "birth-plan", Component: BirthPlan },
      { path: "journal", Component: Journal },
      { path: "community", Component: Community },
      { path: "profile", Component: Profile },
      { path: "providers", Component: ProviderSearch },
    ],
  },
]);
