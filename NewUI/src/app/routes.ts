import { createBrowserRouter } from "react-router";
import { Layout } from "./components/Layout";
import { Home } from "./components/Home";
import { Learning } from "./components/Learning";
import { LearningModuleDetail } from "./components/LearningModuleDetail";
import { AfterVisit } from "./components/AfterVisit";
import { BirthPlan } from "./components/BirthPlan";
import { Journal } from "./components/Journal";
import { Community } from "./components/Community";
import { Profile } from "./components/Profile";
import { ProviderSearch } from "./components/ProviderSearch";
import { ProviderSearchEntry } from "./components/ProviderSearchEntry";
import { ProviderSearchResults } from "./components/ProviderSearchResults";
import { ProviderDetailProfile } from "./components/ProviderDetailProfile";
import { AddProvider } from "./components/AddProvider";
import { PostDetail } from "./components/PostDetail";
import { NewPost } from "./components/NewPost";
import { SymptomCheck } from "./components/SymptomCheck";
import { CarePlan } from "./components/CarePlan";
import { CareNavigationSurvey } from "./components/CareNavigationSurvey";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Layout,
    children: [
      { index: true, Component: Home },
      { path: "learning", Component: Learning },
      { path: "learning/:moduleId", Component: LearningModuleDetail },
      { path: "after-visit", Component: AfterVisit },
      { path: "birth-plan", Component: BirthPlan },
      { path: "journal", Component: Journal },
      { path: "community", Component: Community },
      { path: "community/new", Component: NewPost },
      { path: "community/:postId", Component: PostDetail },
      { path: "profile", Component: Profile },
      { path: "providers", Component: ProviderSearch },
      { path: "providers/search", Component: ProviderSearchEntry },
      { path: "providers/results", Component: ProviderSearchResults },
      { path: "providers/add", Component: AddProvider },
      { path: "providers/:providerId", Component: ProviderDetailProfile },
      { path: "symptom-check", Component: SymptomCheck },
      { path: "care-plan", Component: CarePlan },
      { path: "care-check-in", Component: CareNavigationSurvey },
    ],
  },
]);