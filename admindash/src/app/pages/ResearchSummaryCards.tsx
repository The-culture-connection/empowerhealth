import { Loader2, RotateCcw } from "lucide-react";
import type { ResearchDashboardSummary } from "../../lib/researchApi";

function fmt(v: number | null | undefined): string {
  if (v == null || Number.isNaN(v)) return "—";
  return v.toFixed(2);
}

function pct(v: number | null | undefined): string {
  if (v == null || Number.isNaN(v)) return "—";
  return `${(v * 100).toFixed(1)}%`;
}

function Kpi({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-xl border p-4" style={{ borderColor: "var(--lavender-100)" }}>
      <div className="text-xs uppercase tracking-wide" style={{ color: "var(--warm-500)" }}>
        {label}
      </div>
      <div className="text-2xl font-semibold mt-1" style={{ color: "var(--eh-primary)" }}>
        {value}
      </div>
    </div>
  );
}

type ResearchSummaryCardsProps = {
  summary: ResearchDashboardSummary | null;
  loading: boolean;
  onRecompute?: () => void;
  recomputeBusy?: boolean;
};

/**
 * KPI grid for the selected date window (Phase 7 layer or live fallback).
 */
export function ResearchSummaryCards({ summary, loading, onRecompute, recomputeBusy }: ResearchSummaryCardsProps) {
  return (
    <section className="rounded-2xl border p-6" style={{ borderColor: "var(--lavender-200)", backgroundColor: "white" }}>
      <div className="flex flex-wrap items-start justify-between gap-3 mb-4">
        <h2 className="text-lg font-medium" style={{ color: "var(--warm-700)" }}>
          Summary (same window as exports)
        </h2>
        {onRecompute ? (
          <button
            type="button"
            disabled={recomputeBusy}
            onClick={() => void onRecompute()}
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg border text-xs disabled:opacity-45"
            style={{ borderColor: "var(--lavender-300)", color: "var(--warm-700)" }}
          >
            {recomputeBusy ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <RotateCcw className="w-3.5 h-3.5" />}
            Recompute summaries
          </button>
        ) : null}
      </div>
      {loading ? (
        <div className="flex items-center gap-2 text-sm" style={{ color: "var(--warm-500)" }}>
          <Loader2 className="w-5 h-5 animate-spin" />
          Loading…
        </div>
      ) : summary ? (
        <div className="space-y-4">
          <div className="flex flex-wrap items-center gap-2 text-xs" style={{ color: "var(--warm-600)" }}>
            <span
              className="rounded-full px-2 py-0.5 font-medium"
              style={{
                backgroundColor: summary.summarySource === "layer" ? "var(--lavender-100)" : "var(--warm-100)",
                color: "var(--warm-800)",
              }}
            >
              Source: {summary.summarySource === "layer" ? "summary layer" : "live queries"}
            </span>
            {summary.summarySource === "layer" && summary.summaryDaysWithData != null ? (
              <span>
                Day docs with activity in range: <strong>{summary.summaryDaysWithData}</strong>
              </span>
            ) : null}
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
            <Kpi label="Participants (rows)" value={summary.participantCount} />
            <Kpi label="Baseline (rows)" value={summary.baselineCount ?? 0} />
            <Kpi label="Micro-measure rows" value={summary.microMeasureCount} />
            <Kpi label="Needs checklists" value={summary.needsChecklistCount} />
            <Kpi label="Navigation outcomes" value={summary.navigationOutcomeCount} />
            <Kpi label="Milestone prompts" value={summary.milestonePromptCount} />
            <Kpi label="App activity rows" value={summary.appActivityCount} />
            <Kpi label="Provider reviews (activity)" value={summary.providerReviewCount ?? 0} />
            <Kpi label="AVS uploads (activity)" value={summary.avsUploadCount ?? 0} />
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-sm">
            <div className="rounded-xl border p-3" style={{ borderColor: "var(--lavender-100)" }}>
              <div className="text-xs uppercase tracking-wide" style={{ color: "var(--warm-500)" }}>
                Navigation success rate
              </div>
              <div className="text-lg font-semibold mt-1" style={{ color: "var(--eh-primary)" }}>
                {pct(summary.navigationSuccessRate)}
              </div>
              <div className="text-xs mt-1" style={{ color: "var(--warm-500)" }}>
                Share of applicable need slots with access codes 4–6
              </div>
            </div>
            <div className="rounded-xl border p-3" style={{ borderColor: "var(--lavender-100)" }}>
              <div className="text-xs uppercase tracking-wide" style={{ color: "var(--warm-500)" }}>
                Module completion rate
              </div>
              <div className="text-lg font-semibold mt-1" style={{ color: "var(--eh-primary)" }}>
                {pct(summary.moduleCompletionRate)}
              </div>
              <div className="text-xs mt-1" style={{ color: "var(--warm-500)" }}>
                Module completions ÷ participants (summary layer)
              </div>
            </div>
            <div className="rounded-xl border p-3" style={{ borderColor: "var(--lavender-100)" }}>
              <div className="text-xs uppercase tracking-wide" style={{ color: "var(--warm-500)" }}>
                Milestone response rate
              </div>
              <div className="text-lg font-semibold mt-1" style={{ color: "var(--eh-primary)" }}>
                {pct(summary.milestoneResponseRate)}
              </div>
              <div className="text-xs mt-1" style={{ color: "var(--warm-500)" }}>
                Milestone prompts ÷ participants (summary layer)
              </div>
            </div>
          </div>
          <div className="p-4 rounded-xl" style={{ backgroundColor: "var(--lavender-50)" }}>
            <div className="font-medium mb-2" style={{ color: "var(--warm-700)" }}>
              Micro averages
              {summary.summarySource === "live" ? " (sample up to 500)" : " (full window sums ÷ row count)"}
            </div>
            <div className="grid grid-cols-3 gap-2" style={{ color: "var(--warm-600)" }}>
              <span>Understand: {fmt(summary.microAverages.micro_understand)}</span>
              <span>Next step: {fmt(summary.microAverages.micro_next_step)}</span>
              <span>Confidence: {fmt(summary.microAverages.micro_confidence)}</span>
            </div>
            <div className="text-xs mt-1" style={{ color: "var(--warm-500)" }}>
              n = {summary.microAverages.sampleSize}
            </div>
          </div>
        </div>
      ) : null}
    </section>
  );
}
