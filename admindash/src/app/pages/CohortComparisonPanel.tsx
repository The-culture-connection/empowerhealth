import type { PathwaySummarySlice, ResearchDashboardSummary } from "../../lib/researchApi";

function fmt(v: number | null | undefined): string {
  if (v == null || Number.isNaN(v)) return "—";
  return v.toFixed(2);
}

function pct(v: number | null | undefined): string {
  if (v == null || Number.isNaN(v)) return "—";
  return `${(v * 100).toFixed(1)}%`;
}

function CohortColumn({ title, slice }: { title: string; slice: PathwaySummarySlice }) {
  if (!slice) {
    return (
      <div className="rounded-xl border p-4 text-sm" style={{ borderColor: "var(--lavender-100)", color: "var(--warm-500)" }}>
        <div className="font-medium mb-2" style={{ color: "var(--warm-700)" }}>
          {title}
        </div>
        No pathway summary yet (enroll activity after Phase 7 deploy, or run recompute).
      </div>
    );
  }
  const topNeeds = Object.entries(slice.needs_frequency_by_category)
    .filter(([, v]) => v > 0)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 4);
  return (
    <div className="rounded-xl border p-4 text-sm space-y-2" style={{ borderColor: "var(--lavender-100)" }}>
      <div className="font-medium" style={{ color: "var(--warm-700)" }}>
        {title}
      </div>
      <div style={{ color: "var(--warm-600)" }}>
        Participants: <strong>{slice.participant_count}</strong> · Micro rows:{" "}
        <strong>{slice.micro_measure_count}</strong>
      </div>
      <div className="grid grid-cols-2 gap-2 text-xs" style={{ color: "var(--warm-600)" }}>
        <span>Nav success: {pct(slice.navigation_success_rate)}</span>
        <span>Module rate: {pct(slice.module_completion_rate)}</span>
        <span>Milestone rate: {pct(slice.milestone_response_rate)}</span>
        <span>Reviews: {slice.provider_review_count}</span>
      </div>
      <div className="text-xs" style={{ color: "var(--warm-600)" }}>
        Micro: {fmt(slice.average_micro_understand)} / {fmt(slice.average_micro_next_step)} /{" "}
        {fmt(slice.average_micro_confidence)}
      </div>
      {topNeeds.length ? (
        <div className="text-xs pt-2 border-t" style={{ borderColor: "var(--lavender-100)", color: "var(--warm-600)" }}>
          <div className="font-medium mb-1" style={{ color: "var(--warm-700)" }}>
            Top needs (frequency)
          </div>
          <ul className="space-y-0.5 font-mono">
            {topNeeds.map(([k, v]) => (
              <li key={k}>
                {k}: {v}
              </li>
            ))}
          </ul>
        </div>
      ) : null}
    </div>
  );
}

type CohortComparisonPanelProps = {
  cohort?: ResearchDashboardSummary["cohortComparison"];
};

/**
 * Navigator-supported (pathway 1) vs self-directed (pathway 2) from `research_summary_by_pathway`.
 */
export function CohortComparisonPanel({ cohort }: CohortComparisonPanelProps) {
  if (!cohort) {
    return (
      <section className="rounded-2xl border p-6 text-sm" style={{ borderColor: "var(--lavender-200)", backgroundColor: "var(--eh-surface)", color: "var(--warm-500)" }}>
        Cohort pathway summaries will appear after Phase 7 triggers populate <code className="text-xs">research_summary_by_pathway</code>.
      </section>
    );
  }
  return (
    <section className="rounded-2xl border p-6 space-y-4" style={{ borderColor: "var(--lavender-200)", backgroundColor: "var(--eh-surface)" }}>
      <h2 className="text-lg font-medium" style={{ color: "var(--warm-700)" }}>
        Cohort comparison (pathway summaries)
      </h2>
      <p className="text-xs leading-relaxed" style={{ color: "var(--warm-500)" }}>
        Incremental updates come from research write triggers; run <strong>Recompute summaries</strong> after deploy or
        bulk imports so pathway docs align with raw rows.
      </p>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <CohortColumn title="1 — Navigator-supported" slice={cohort.navigator_supported} />
        <CohortColumn title="2 — Self-directed" slice={cohort.self_directed} />
      </div>
    </section>
  );
}
