import { Link } from "react-router";

type RowStatus = "tracked" | "partial" | "needs-implementation";

type PhaseKind = "lifecycle_start" | "action" | "lifecycle_end";

type EventRow = {
  id: string;
  event: string;
  feature: string;
  phase: PhaseKind;
  behaviorMeasured: string;
  status: RowStatus;
  implementationNotes: string;
};

type FeatureSection = {
  featureId: string;
  title: string;
  intro?: string;
  rows: EventRow[];
};

function phaseLabel(p: PhaseKind): string {
  switch (p) {
    case "lifecycle_start":
      return "Lifecycle — start";
    case "lifecycle_end":
      return "Lifecycle — end";
    case "action":
      return "Action";
  }
}

const SECTIONS: FeatureSection[] = [
  {
    featureId: "app",
    title: "App (session & shell)",
    intro:
      "Session events bracket app foreground time. `screen_view`, `screen_time_spent`, and `feature_time_spent` measure navigation and dwell. Nested feature surfaces also emit `feature_session_started` / `feature_session_ended` (see each feature below).",
    rows: [
      {
        id: "app-session_started",
        event: "session_started",
        feature: "app",
        phase: "lifecycle_start",
        behaviorMeasured: "App session begins (cold start or resume after background)",
        status: "tracked",
        implementationNotes:
          "Cold start uses entry_point `app_cold_start`; resume after pause uses `app_resume`.",
      },
      {
        id: "app-session_ended",
        event: "session_ended",
        feature: "app",
        phase: "lifecycle_end",
        behaviorMeasured: "Session ends with duration; updates `user_sessions`",
        status: "tracked",
        implementationNotes:
          "Emitted on background (`paused`), on auth wrapper dispose (logout), and includes `duration_seconds` from persisted session timing.",
      },
      {
        id: "app-screen_view",
        event: "screen_view",
        feature: "app",
        phase: "action",
        behaviorMeasured: "Screen / surface exposure",
        status: "tracked",
        implementationNotes: "Main nav tabs, key routes, and several feature screens.",
      },
      {
        id: "app-screen_time_spent",
        event: "screen_time_spent",
        feature: "app",
        phase: "action",
        behaviorMeasured: "Dwell time on a named screen",
        status: "tracked",
        implementationNotes: "Tab changes and some screen exits.",
      },
      {
        id: "app-feature_time_spent",
        event: "feature_time_spent",
        feature: "app",
        phase: "action",
        behaviorMeasured: "Dwell time attributed to a feature id",
        status: "tracked",
        implementationNotes: "Tab and nested surfaces (e.g. post detail).",
      },
      {
        id: "app-flow_abandoned",
        event: "flow_abandoned",
        feature: "app",
        phase: "action",
        behaviorMeasured: "User left a key flow before completion",
        status: "partial",
        implementationNotes: "Learning module early exit; extend to other flows as needed.",
      },
    ],
  },
  {
    featureId: "authentication-onboarding",
    title: "Authentication & onboarding",
    rows: [
      {
        id: "auth-feature_session_started",
        event: "feature_session_started",
        feature: "authentication-onboarding",
        phase: "lifecycle_start",
        behaviorMeasured: "User opened an auth/onboarding surface",
        status: "tracked",
        implementationNotes:
          "Auth landing, login, and sign-up screens (ref-counted if multiple nested scopes share the same feature id).",
      },
      {
        id: "auth-sign_in_completed",
        event: "sign_in_completed",
        feature: "authentication-onboarding",
        phase: "action",
        behaviorMeasured: "Successful sign-in (method captured)",
        status: "tracked",
        implementationNotes: "Emitted from auth flows when sign-in succeeds.",
      },
      {
        id: "auth-feature_session_ended",
        event: "feature_session_ended",
        feature: "authentication-onboarding",
        phase: "lifecycle_end",
        behaviorMeasured: "User left the auth/onboarding surface",
        status: "tracked",
        implementationNotes: "Paired duration with matching start; last scope unmount ends the session.",
      },
    ],
  },
  {
    featureId: "provider-search",
    title: "Provider search",
    rows: [
      {
        id: "ps-feature_session_started",
        event: "feature_session_started",
        feature: "provider-search",
        phase: "lifecycle_start",
        behaviorMeasured: "User entered provider search (hub or entry form)",
        status: "tracked",
        implementationNotes:
          "Provider hub + entry screens; nested routes ref-count so overlapping pushes share one logical session.",
      },
      {
        id: "ps-provider_search_initiated",
        event: "provider_search_initiated",
        feature: "provider-search",
        phase: "action",
        behaviorMeasured: "Search intent",
        status: "tracked",
        implementationNotes: "Emitted when a search is started from the entry flow.",
      },
      {
        id: "ps-provider_profile_viewed",
        event: "provider_profile_viewed",
        feature: "provider-search",
        phase: "action",
        behaviorMeasured: "Profile detail viewed",
        status: "tracked",
        implementationNotes: "Results and profile navigation.",
      },
      {
        id: "ps-provider_contact_clicked",
        event: "provider_contact_clicked",
        feature: "provider-search",
        phase: "action",
        behaviorMeasured: "Contact action (call / web / directions)",
        status: "tracked",
        implementationNotes: "Tracked on contact taps.",
      },
      {
        id: "ps-provider_selected_success",
        event: "provider_selected_success",
        feature: "provider-search",
        phase: "action",
        behaviorMeasured: "Successful provider selection / save signal",
        status: "tracked",
        implementationNotes: "Result card selection and profile bookmark/save.",
      },
      {
        id: "ps-provider_review_submitted",
        event: "provider_review_submitted",
        feature: "provider-search",
        phase: "action",
        behaviorMeasured: "User submitted a provider review (rating + optional text)",
        status: "tracked",
        implementationNotes: "After successful Firestore submit on ProviderReviewScreen.",
      },
      {
        id: "ps-provider_filter_applied",
        event: "provider_filter_applied",
        feature: "provider-search",
        phase: "action",
        behaviorMeasured: "Filter refinement",
        status: "needs-implementation",
        implementationNotes: "Helper exists; wire filter UI interactions.",
      },
      {
        id: "ps-feature_session_ended",
        event: "feature_session_ended",
        feature: "provider-search",
        phase: "lifecycle_end",
        behaviorMeasured: "User exited provider search surfaces",
        status: "tracked",
        implementationNotes: "Duration from matching `feature_session_started` for this feature id.",
      },
    ],
  },
  {
    featureId: "user-feedback",
    title: "User feedback",
    rows: [
      {
        id: "uf-feature_session_started",
        event: "feature_session_started",
        feature: "user-feedback",
        phase: "lifecycle_start",
        behaviorMeasured: "User opened a structured feedback surface (e.g. care navigation survey)",
        status: "tracked",
        implementationNotes: "Care navigation survey screen wrapped with `FeatureSessionScope`.",
      },
      {
        id: "uf-micro_measure_submitted",
        event: "micro_measure_submitted",
        feature: "user-feedback",
        phase: "action",
        behaviorMeasured: "Micro-measure / confidence payload stored and logged",
        status: "tracked",
        implementationNotes: "Writes `micro_measures` and analytics event.",
      },
      {
        id: "uf-confidence_signal_submitted",
        event: "confidence_signal_submitted",
        feature: "user-feedback",
        phase: "action",
        behaviorMeasured: "Confidence / understanding pulse",
        status: "tracked",
        implementationNotes: "Routed through micro-measure logging helper.",
      },
      {
        id: "uf-feature_session_ended",
        event: "feature_session_ended",
        feature: "user-feedback",
        phase: "lifecycle_end",
        behaviorMeasured: "User left the feedback surface",
        status: "tracked",
        implementationNotes: "Survey screen dispose ends session with dwell duration.",
      },
    ],
  },
  {
    featureId: "appointment-summarizing",
    title: "Appointment summarizing (visit summary)",
    rows: [
      {
        id: "avs-feature_session_started",
        event: "feature_session_started",
        feature: "appointment-summarizing",
        phase: "lifecycle_start",
        behaviorMeasured: "User opened upload / visit summary flow",
        status: "tracked",
        implementationNotes: "`UploadVisitSummaryScreen` wrapped with `FeatureSessionScope`.",
      },
      {
        id: "avs-visit_summary_created",
        event: "visit_summary_created",
        feature: "appointment-summarizing",
        phase: "action",
        behaviorMeasured: "Summary created or upload succeeded",
        status: "tracked",
        implementationNotes: "Tracked on successful creation.",
      },
      {
        id: "avs-visit_summary_viewed",
        event: "visit_summary_viewed",
        feature: "appointment-summarizing",
        phase: "action",
        behaviorMeasured: "User opened an existing appointment / visit summary (list → detail dialog)",
        status: "tracked",
        implementationNotes: "Logged when tapping a summary row before the dialog opens (`summary_id` = Firestore doc id).",
      },
      {
        id: "avs-visit_summary_edited",
        event: "visit_summary_edited",
        feature: "appointment-summarizing",
        phase: "action",
        behaviorMeasured: "Summary edited",
        status: "needs-implementation",
        implementationNotes: "Helper exists; wire edit flows.",
      },
      {
        id: "avs-feature_session_ended",
        event: "feature_session_ended",
        feature: "appointment-summarizing",
        phase: "lifecycle_end",
        behaviorMeasured: "User left visit summary upload flow",
        status: "tracked",
        implementationNotes: "Screen dispose ends session.",
      },
    ],
  },
  {
    featureId: "journal",
    title: "Journal",
    rows: [
      {
        id: "j-feature_session_started",
        event: "feature_session_started",
        feature: "journal",
        phase: "lifecycle_start",
        behaviorMeasured: "User focused the Journal tab / area",
        status: "tracked",
        implementationNotes: "Emitted from main bottom nav when the Journal tab becomes active (`entry_source: main_tab`).",
      },
      {
        id: "j-journal_entry_created",
        event: "journal_entry_created",
        feature: "journal",
        phase: "action",
        behaviorMeasured: "New journal entry",
        status: "tracked",
        implementationNotes: "Create path instrumentation.",
      },
      {
        id: "j-journal_mood_selected",
        event: "journal_mood_selected",
        feature: "journal",
        phase: "action",
        behaviorMeasured: "Mood self-report",
        status: "tracked",
        implementationNotes: "Mood selection events.",
      },
      {
        id: "j-feature_session_ended",
        event: "feature_session_ended",
        feature: "journal",
        phase: "lifecycle_end",
        behaviorMeasured: "User left the Journal tab",
        status: "tracked",
        implementationNotes: "Ends when switching tabs or leaving main nav (with dwell seconds).",
      },
    ],
  },
  {
    featureId: "learning-modules",
    title: "Learning modules",
    rows: [
      {
        id: "lm-feature_session_started",
        event: "feature_session_started",
        feature: "learning-modules",
        phase: "lifecycle_start",
        behaviorMeasured: "User focused the Learn tab / learning hub",
        status: "tracked",
        implementationNotes: "Main tab `feature_session_started` with `main_tab`.",
      },
      {
        id: "lm-learning_module_viewed",
        event: "learning_module_viewed",
        feature: "learning-modules",
        phase: "action",
        behaviorMeasured: "Module detail opened",
        status: "tracked",
        implementationNotes: "Module detail screen.",
      },
      {
        id: "lm-learning_module_started",
        event: "learning_module_started",
        feature: "learning-modules",
        phase: "action",
        behaviorMeasured: "User began engaging with module content",
        status: "tracked",
        implementationNotes: "Emitted at module entry.",
      },
      {
        id: "lm-learning_module_survey_submitted",
        event: "learning_module_survey_submitted",
        feature: "learning-modules",
        phase: "action",
        behaviorMeasured: "Learning module survey completed (not a quiz)",
        status: "tracked",
        implementationNotes:
          "Two flows: `survey_context` = `qualitative_feedback` (QualitativeSurveyDialog on module detail) or `module_archive_gate` (ModuleSurveyDialog before archiving).",
      },
      {
        id: "lm-learning_module_completed",
        event: "learning_module_completed",
        feature: "learning-modules",
        phase: "action",
        behaviorMeasured: "Module marked complete / archived",
        status: "tracked",
        implementationNotes: "Detail exit and list checkbox / archive flows.",
      },
      {
        id: "lm-feature_session_ended",
        event: "feature_session_ended",
        feature: "learning-modules",
        phase: "lifecycle_end",
        behaviorMeasured: "User left the Learn tab",
        status: "tracked",
        implementationNotes: "Tab switch or main nav dispose.",
      },
    ],
  },
  {
    featureId: "birth-plan-generator",
    title: "Birth plan generator",
    rows: [
      {
        id: "bp-feature_session_started",
        event: "feature_session_started",
        feature: "birth-plan-generator",
        phase: "lifecycle_start",
        behaviorMeasured: "User opened comprehensive birth plan builder",
        status: "tracked",
        implementationNotes: "`ComprehensiveBirthPlanScreen` wrapped with `FeatureSessionScope`.",
      },
      {
        id: "bp-birth_plan_viewed",
        event: "birth_plan_viewed",
        feature: "birth-plan-generator",
        phase: "action",
        behaviorMeasured: "User opened saved birth plan display screen",
        status: "tracked",
        implementationNotes: "Emitted when `BirthPlanDisplayScreen` loads.",
      },
      {
        id: "bp-birth_plan_completed",
        event: "birth_plan_completed",
        feature: "birth-plan-generator",
        phase: "action",
        behaviorMeasured: "Birth plan completed / saved",
        status: "tracked",
        implementationNotes: "Completion analytics on save.",
      },
      {
        id: "bp-birth_plan_exported",
        event: "birth_plan_exported",
        feature: "birth-plan-generator",
        phase: "action",
        behaviorMeasured: "User shared or exported birth plan via system share sheet",
        status: "tracked",
        implementationNotes: "`export_type`: `pdf_share` or `text_share` on BirthPlanDisplayScreen after Share.",
      },
      {
        id: "bp-birth_plan_shared_provider",
        event: "birth_plan_shared_provider",
        feature: "birth-plan-generator",
        phase: "action",
        behaviorMeasured: "Birth plan shared with provider (dedicated flow)",
        status: "partial",
        implementationNotes: "Helper exists; wire when builder exposes share-with-provider.",
      },
      {
        id: "bp-birth_plan_downloaded_pdf",
        event: "birth_plan_downloaded_pdf",
        feature: "birth-plan-generator",
        phase: "action",
        behaviorMeasured: "Birth plan PDF downloaded (legacy naming)",
        status: "partial",
        implementationNotes: "Helper exists; may overlap with `birth_plan_exported` where PDF is used.",
      },
      {
        id: "bp-feature_session_ended",
        event: "feature_session_ended",
        feature: "birth-plan-generator",
        phase: "lifecycle_end",
        behaviorMeasured: "User exited birth plan builder",
        status: "tracked",
        implementationNotes: "Scope ends on pop / dispose with dwell duration.",
      },
    ],
  },
  {
    featureId: "community",
    title: "Community",
    rows: [
      {
        id: "c-feature_session_started",
        event: "feature_session_started",
        feature: "community",
        phase: "lifecycle_start",
        behaviorMeasured: "User focused the Community tab",
        status: "tracked",
        implementationNotes: "Main tab session start.",
      },
      {
        id: "c-community_post_created",
        event: "community_post_created",
        feature: "community",
        phase: "action",
        behaviorMeasured: "New post created",
        status: "tracked",
        implementationNotes: "Post creation path.",
      },
      {
        id: "c-community_post_viewed",
        event: "community_post_viewed",
        feature: "community",
        phase: "action",
        behaviorMeasured: "Post detail viewed",
        status: "tracked",
        implementationNotes: "Post detail screen.",
      },
      {
        id: "c-community_post_liked",
        event: "community_post_liked",
        feature: "community",
        phase: "action",
        behaviorMeasured: "Post liked",
        status: "tracked",
        implementationNotes: "Like toggle to liked.",
      },
      {
        id: "c-community_post_replied",
        event: "community_post_replied",
        feature: "community",
        phase: "action",
        behaviorMeasured: "Reply submitted",
        status: "tracked",
        implementationNotes: "Reply submit on post detail.",
      },
      {
        id: "c-feature_session_ended",
        event: "feature_session_ended",
        feature: "community",
        phase: "lifecycle_end",
        behaviorMeasured: "User left the Community tab",
        status: "tracked",
        implementationNotes: "Tab switch / nav dispose.",
      },
    ],
  },
  {
    featureId: "profile-editing",
    title: "Profile editing",
    rows: [
      {
        id: "pe-feature_session_started",
        event: "feature_session_started",
        feature: "profile-editing",
        phase: "lifecycle_start",
        behaviorMeasured: "User focused the Profile tab",
        status: "tracked",
        implementationNotes: "Main tab session start.",
      },
      {
        id: "pe-profile_updated",
        event: "profile_updated",
        feature: "profile-editing",
        phase: "action",
        behaviorMeasured: "Profile saved from edit screen",
        status: "tracked",
        implementationNotes: "Realtime pipeline event on successful save.",
      },
      {
        id: "pe-feature_session_ended",
        event: "feature_session_ended",
        feature: "profile-editing",
        phase: "lifecycle_end",
        behaviorMeasured: "User left the Profile tab",
        status: "tracked",
        implementationNotes: "Tab switch / nav dispose.",
      },
    ],
  },
];

export function AnalyticsInfo() {
  return (
    <div className="p-8">
      <div className="max-w-6xl mx-auto space-y-10">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl mb-2" style={{ color: "var(--warm-600)" }}>
              Analytics Info
            </h1>
            <p style={{ color: "var(--warm-500)" }}>
              Event dictionary by feature: lifecycle start → actions → lifecycle end (matching typical analytics ordering).
            </p>
          </div>
          <Link
            to="/analytics"
            className="px-4 py-2 rounded-lg text-sm"
            style={{ backgroundColor: "var(--lavender-100)", color: "var(--lavender-600)" }}
          >
            Back to Analytics
          </Link>
        </div>

        <div className="p-4 rounded-xl border" style={{ backgroundColor: "var(--lavender-50)", borderColor: "var(--lavender-200)" }}>
          <div className="text-sm" style={{ color: "var(--warm-600)" }}>
            <strong>Tracked</strong> = verified in current app builds.{" "}
            <strong>Partial</strong> = some flows only.{" "}
            <strong>Needs implementation</strong> = helper or contract exists; UI wiring still pending.
          </div>
        </div>

        {SECTIONS.map((section) => (
          <section key={section.featureId} className="space-y-3">
            <h2 className="text-xl font-semibold" style={{ color: "var(--warm-600)" }}>
              {section.title}{" "}
              <code className="text-sm font-normal" style={{ color: "var(--lavender-600)" }}>({section.featureId})</code>
            </h2>
            {section.intro ? (
              <p className="text-sm" style={{ color: "var(--warm-500)" }}>
                {section.intro}
              </p>
            ) : null}
            <div className="rounded-2xl border overflow-hidden" style={{ borderColor: "var(--lavender-200)", backgroundColor: "white" }}>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr style={{ backgroundColor: "var(--lavender-50)" }}>
                      <th className="text-left px-4 py-3" style={{ color: "var(--warm-600)" }}>Phase</th>
                      <th className="text-left px-4 py-3" style={{ color: "var(--warm-600)" }}>Event</th>
                      <th className="text-left px-4 py-3" style={{ color: "var(--warm-600)" }}>Behavior measured</th>
                      <th className="text-left px-4 py-3" style={{ color: "var(--warm-600)" }}>Implementation notes</th>
                      <th className="text-left px-4 py-3" style={{ color: "var(--warm-600)" }}>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {section.rows.map((row) => (
                      <tr key={row.id} className="border-t" style={{ borderColor: "var(--lavender-100)" }}>
                        <td className="px-4 py-3 whitespace-nowrap text-xs font-medium" style={{ color: "var(--lavender-600)" }}>
                          {phaseLabel(row.phase)}
                        </td>
                        <td className="px-4 py-3"><code>{row.event}</code></td>
                        <td className="px-4 py-3" style={{ color: "var(--warm-500)" }}>{row.behaviorMeasured}</td>
                        <td className="px-4 py-3 text-xs" style={{ color: "var(--warm-500)" }}>{row.implementationNotes}</td>
                        <td className="px-4 py-3">
                          <span
                            className="px-2 py-1 rounded-full text-xs"
                            style={{
                              backgroundColor:
                                row.status === "tracked"
                                  ? "var(--success-light)"
                                  : row.status === "partial"
                                    ? "var(--lavender-100)"
                                    : "var(--warm-100)",
                              color:
                                row.status === "tracked"
                                  ? "var(--success)"
                                  : row.status === "partial"
                                    ? "var(--lavender-600)"
                                    : "var(--warm-600)",
                            }}
                          >
                            {row.status === "tracked"
                              ? "Tracked"
                              : row.status === "partial"
                                ? "Partial"
                                : "Needs Implementation"}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </section>
        ))}
      </div>
    </div>
  );
}
