import { ClipboardList, RefreshCw } from "lucide-react";
import { RESEARCH_SPEC_VERSION } from "@research/researchFieldSpec";

type ResearchDashboardHomeProps = {
  onRefresh: () => void;
};

/**
 * Research `/research` header: title, spec line, and refresh (Phase 7 shell).
 */
export function ResearchDashboardHome({ onRefresh }: ResearchDashboardHomeProps) {
  return (
    <div className="flex items-start justify-between gap-4 flex-wrap">
      <div>
        <h1 className="text-2xl font-semibold flex items-center gap-2" style={{ color: "var(--eh-primary)" }}>
          <ClipboardList className="w-8 h-8" />
          Research dataset
        </h1>
        <p className="mt-2 text-sm" style={{ color: "var(--warm-600)" }}>
          Structured exports keyed by <code>study_id</code> (spec {RESEARCH_SPEC_VERSION}). Product analytics remain on the
          Analytics page. Phase 7 summary collections speed KPIs when day-level summaries exist; otherwise the dashboard
          falls back to live counts.
        </p>
      </div>
      <button
        type="button"
        onClick={() => void onRefresh()}
        className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border text-sm"
        style={{ borderColor: "var(--lavender-200)", color: "var(--warm-600)" }}
      >
        <RefreshCw className="w-4 h-4" />
        Refresh
      </button>
    </div>
  );
}
