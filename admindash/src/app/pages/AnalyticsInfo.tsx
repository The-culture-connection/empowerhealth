import { Link } from "react-router";

type EventRow = {
  event: string;
  feature: string;
  behaviorMeasured: string;
  status: "tracked" | "partial" | "needs-implementation";
  implementationNotes: string;
};

const EVENT_ROWS: EventRow[] = [
  {
    event: "session_started",
    feature: "app",
    behaviorMeasured: "User begins a session (awareness entry)",
    status: "tracked",
    implementationNotes: "Emitted from app start/session bootstrap.",
  },
  {
    event: "session_ended",
    feature: "app",
    behaviorMeasured: "User session close + duration",
    status: "partial",
    implementationNotes: "Method exists; not consistently fired across all exits/background paths.",
  },
  {
    event: "screen_view",
    feature: "app",
    behaviorMeasured: "Screen exposure/navigation footprint",
    status: "tracked",
    implementationNotes: "Tracked for navigation shell and key feature screens.",
  },
  {
    event: "screen_time_spent",
    feature: "app",
    behaviorMeasured: "Time spent on a screen/surface",
    status: "tracked",
    implementationNotes: "Added on tab transitions and tab-exit handling.",
  },
  {
    event: "feature_time_spent",
    feature: "app",
    behaviorMeasured: "Time spent inside a feature",
    status: "tracked",
    implementationNotes: "Added for tabs + learning detail + provider detail + community post detail.",
  },
  {
    event: "flow_abandoned",
    feature: "app",
    behaviorMeasured: "Drop-off/abandonment in key journey",
    status: "partial",
    implementationNotes: "Implemented for learning-module early exits; more flows can still be instrumented.",
  },
  {
    event: "learning_module_viewed",
    feature: "learning-modules",
    behaviorMeasured: "Educational content discovery",
    status: "tracked",
    implementationNotes: "Tracked when module detail opens.",
  },
  {
    event: "learning_module_started",
    feature: "learning-modules",
    behaviorMeasured: "Learning intent (content start)",
    status: "tracked",
    implementationNotes: "Tracked at module entry.",
  },
  {
    event: "learning_module_completed",
    feature: "learning-modules",
    behaviorMeasured: "Learning completion outcome",
    status: "tracked",
    implementationNotes: "Added on module exit with completion status/time spent.",
  },
  {
    event: "learning_module_quiz_submitted",
    feature: "learning-modules",
    behaviorMeasured: "Knowledge check result submission",
    status: "tracked",
    implementationNotes: "Tracked via quiz submission path.",
  },
  {
    event: "provider_search_initiated",
    feature: "provider-search",
    behaviorMeasured: "Care navigation intent",
    status: "tracked",
    implementationNotes: "Tracked at provider search start.",
  },
  {
    event: "provider_profile_viewed",
    feature: "provider-search",
    behaviorMeasured: "Provider exploration depth",
    status: "tracked",
    implementationNotes: "Tracked from search results and profile open.",
  },
  {
    event: "provider_contact_clicked",
    feature: "provider-search",
    behaviorMeasured: "Action toward provider engagement",
    status: "tracked",
    implementationNotes: "Tracked on call/web/directions actions.",
  },
  {
    event: "provider_selected_success",
    feature: "provider-search",
    behaviorMeasured: "Successful provider selection signal",
    status: "tracked",
    implementationNotes: "Added on result-card selection and profile bookmark/save.",
  },
  {
    event: "provider_filter_applied",
    feature: "provider-search",
    behaviorMeasured: "Filter/refinement behavior",
    status: "needs-implementation",
    implementationNotes: "Event helper exists; not wired in current filter UI interactions.",
  },
  {
    event: "visit_summary_created",
    feature: "appointment-summarizing",
    behaviorMeasured: "Post-visit documentation completed",
    status: "tracked",
    implementationNotes: "Tracked on summary creation/upload success.",
  },
  {
    event: "visit_summary_edited",
    feature: "appointment-summarizing",
    behaviorMeasured: "Summary revision activity",
    status: "needs-implementation",
    implementationNotes: "Event helper exists; edit flow instrumentation still pending.",
  },
  {
    event: "birth_plan_completed",
    feature: "birth-plan-generator",
    behaviorMeasured: "Care preparation milestone completion",
    status: "tracked",
    implementationNotes: "Tracked on birth plan completion.",
  },
  {
    event: "journal_entry_created",
    feature: "journal",
    behaviorMeasured: "Reflection/voice activity",
    status: "tracked",
    implementationNotes: "Tracked on entry create.",
  },
  {
    event: "journal_mood_selected",
    feature: "journal",
    behaviorMeasured: "Affective state self-report",
    status: "tracked",
    implementationNotes: "Tracked on mood selection.",
  },
  {
    event: "micro_measure_submitted",
    feature: "user-feedback",
    behaviorMeasured: "Outcome signal (confidence/understanding)",
    status: "tracked",
    implementationNotes: "Tracked with specialized collection write + event.",
  },
  {
    event: "confidence_signal_submitted",
    feature: "user-feedback",
    behaviorMeasured: "Confidence pulse check",
    status: "tracked",
    implementationNotes: "Tracked through micro-measure logging helper.",
  },
  {
    event: "community_post_created",
    feature: "community",
    behaviorMeasured: "Community contribution initiation",
    status: "tracked",
    implementationNotes: "Tracked on post creation.",
  },
  {
    event: "community_post_replied",
    feature: "community",
    behaviorMeasured: "Community interaction depth (reply)",
    status: "tracked",
    implementationNotes: "Added on reply submission in post detail.",
  },
  {
    event: "community_post_liked",
    feature: "community",
    behaviorMeasured: "Community lightweight engagement (like)",
    status: "tracked",
    implementationNotes: "Added when toggling from unliked to liked.",
  },
];

export function AnalyticsInfo() {
  return (
    <div className="p-8">
      <div className="max-w-6xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl mb-2" style={{ color: "var(--warm-600)" }}>
              Analytics Info
            </h1>
            <p style={{ color: "var(--warm-500)" }}>
              Event dictionary: what we track and the behavior each event measures.
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
            <strong>Tracked</strong> = verified as emitted by current app flows.{" "}
            <strong>Partial</strong> = emitted in some flows, but not complete across all expected paths.{" "}
            <strong>Needs implementation</strong> = defined/expected but not wired in UI runtime yet.
          </div>
        </div>

        <div className="rounded-2xl border overflow-hidden" style={{ borderColor: "var(--lavender-200)", backgroundColor: "white" }}>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr style={{ backgroundColor: "var(--lavender-50)" }}>
                  <th className="text-left px-4 py-3" style={{ color: "var(--warm-600)" }}>Event</th>
                  <th className="text-left px-4 py-3" style={{ color: "var(--warm-600)" }}>Feature</th>
                  <th className="text-left px-4 py-3" style={{ color: "var(--warm-600)" }}>Behavior Measured</th>
                  <th className="text-left px-4 py-3" style={{ color: "var(--warm-600)" }}>Implementation Notes</th>
                  <th className="text-left px-4 py-3" style={{ color: "var(--warm-600)" }}>Status</th>
                </tr>
              </thead>
              <tbody>
                {EVENT_ROWS.map((row) => (
                  <tr key={row.event} className="border-t" style={{ borderColor: "var(--lavender-100)" }}>
                    <td className="px-4 py-3"><code>{row.event}</code></td>
                    <td className="px-4 py-3"><code>{row.feature}</code></td>
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
      </div>
    </div>
  );
}
