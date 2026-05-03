import { useCallback, useEffect, useState } from "react";
import { auth } from "../../firebase/firebase";
import {
  downloadTextFile,
  exportResearchDataset,
  getResearchDashboardSummary,
} from "../../lib/researchApi";
import { RESEARCH_SPEC_VERSION } from "@research/researchFieldSpec";
import { ClipboardList, Download, Loader2, RefreshCw } from "lucide-react";

type PathwayFilter = "" | "1" | "2";

function defaultRange(): { start: Date; end: Date } {
  const end = new Date();
  const start = new Date();
  start.setDate(start.getDate() - 30);
  start.setHours(0, 0, 0, 0);
  end.setHours(23, 59, 59, 999);
  return { start, end };
}

export function ResearchDashboard() {
  const [range, setRange] = useState(defaultRange);
  const [studyId, setStudyId] = useState("");
  const [pathway, setPathway] = useState<PathwayFilter>("");
  const [summary, setSummary] = useState<Awaited<ReturnType<typeof getResearchDashboardSummary>> | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [exporting, setExporting] = useState(false);

  const loadSummary = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const data = await getResearchDashboardSummary({ dateRange: range });
      setSummary(data);
    } catch (e: unknown) {
      setSummary(null);
      setError(e instanceof Error ? e.message : "Failed to load research summary");
    } finally {
      setLoading(false);
    }
  }, [range]);

  useEffect(() => {
    void loadSummary();
  }, [loadSummary]);

  async function handleExportCsv() {
    setExporting(true);
    setError("");
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const res = await exportResearchDataset({
        format: "csv",
        dateRange: range,
        studyId: studyId.trim() || undefined,
        recruitmentPathway: pathway === "" ? undefined : (Number(pathway) as 1 | 2),
      });
      if (res.files) {
        const stamp = new Date().toISOString().slice(0, 10);
        for (const [name, csv] of Object.entries(res.files)) {
          downloadTextFile(`research_${name}_${stamp}.csv`, csv, "text/csv;charset=utf-8");
        }
      }
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Export failed");
    } finally {
      setExporting(false);
    }
  }

  async function handleExportJson() {
    setExporting(true);
    setError("");
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const res = await exportResearchDataset({
        format: "json",
        dateRange: range,
        studyId: studyId.trim() || undefined,
        recruitmentPathway: pathway === "" ? undefined : (Number(pathway) as 1 | 2),
      });
      const body = JSON.stringify(res.data ?? {}, null, 2);
      downloadTextFile(`research_export_${new Date().toISOString().slice(0, 10)}.json`, body, "application/json");
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Export failed");
    } finally {
      setExporting(false);
    }
  }

  return (
    <div className="p-8 max-w-6xl mx-auto space-y-8">
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <h1 className="text-2xl font-semibold flex items-center gap-2" style={{ color: "var(--eh-primary)" }}>
            <ClipboardList className="w-8 h-8" />
            Research dataset
          </h1>
          <p className="mt-2 text-sm" style={{ color: "var(--warm-600)" }}>
            Structured exports keyed by <code>study_id</code> (spec {RESEARCH_SPEC_VERSION}). Product analytics remain on
            the Analytics page.
          </p>
        </div>
        <button
          type="button"
          onClick={() => void loadSummary()}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border text-sm"
          style={{ borderColor: "var(--lavender-200)", color: "var(--warm-600)" }}
        >
          <RefreshCw className="w-4 h-4" />
          Refresh
        </button>
      </div>

      <section className="rounded-2xl border p-6 space-y-4" style={{ borderColor: "var(--lavender-200)", backgroundColor: "var(--eh-surface)" }}>
        <h2 className="text-lg font-medium" style={{ color: "var(--warm-700)" }}>
          Filters
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <label className="block text-sm">
            <span style={{ color: "var(--warm-600)" }}>Start (local)</span>
            <input
              type="datetime-local"
              className="mt-1 w-full rounded-lg border px-3 py-2"
              style={{ borderColor: "var(--lavender-200)" }}
              value={toLocalInput(range.start)}
              onChange={(e) => {
                const d = new Date(e.target.value);
                if (!Number.isNaN(d.getTime())) setRange((r) => ({ ...r, start: d }));
              }}
            />
          </label>
          <label className="block text-sm">
            <span style={{ color: "var(--warm-600)" }}>End (local)</span>
            <input
              type="datetime-local"
              className="mt-1 w-full rounded-lg border px-3 py-2"
              style={{ borderColor: "var(--lavender-200)" }}
              value={toLocalInput(range.end)}
              onChange={(e) => {
                const d = new Date(e.target.value);
                if (!Number.isNaN(d.getTime())) setRange((r) => ({ ...r, end: d }));
              }}
            />
          </label>
          <label className="block text-sm">
            <span style={{ color: "var(--warm-600)" }}>study_id (optional)</span>
            <input
              type="text"
              className="mt-1 w-full rounded-lg border px-3 py-2 font-mono text-sm"
              style={{ borderColor: "var(--lavender-200)" }}
              value={studyId}
              onChange={(e) => setStudyId(e.target.value)}
              placeholder="EH…"
            />
          </label>
          <label className="block text-sm">
            <span style={{ color: "var(--warm-600)" }}>Recruitment pathway</span>
            <select
              className="mt-1 w-full rounded-lg border px-3 py-2"
              style={{ borderColor: "var(--lavender-200)" }}
              value={pathway}
              onChange={(e) => setPathway(e.target.value as PathwayFilter)}
            >
              <option value="">All</option>
              <option value="1">1 — Navigator-supported</option>
              <option value="2">2 — Self-directed</option>
            </select>
          </label>
        </div>
        <div className="flex flex-wrap gap-3">
          <button
            type="button"
            disabled={exporting}
            onClick={() => void handleExportCsv()}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-white text-sm disabled:opacity-50"
            style={{ backgroundColor: "var(--eh-primary)" }}
          >
            {exporting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4" />}
            Export CSV (all instruments)
          </button>
          <button
            type="button"
            disabled={exporting}
            onClick={() => void handleExportJson()}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border text-sm disabled:opacity-50"
            style={{ borderColor: "var(--lavender-300)", color: "var(--warm-700)" }}
          >
            Export JSON
          </button>
        </div>
      </section>

      {error ? (
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{error}</div>
      ) : null}

      <section className="rounded-2xl border p-6" style={{ borderColor: "var(--lavender-200)", backgroundColor: "white" }}>
        <h2 className="text-lg font-medium mb-4" style={{ color: "var(--warm-700)" }}>
          Summary (same window as exports)
        </h2>
        {loading ? (
          <div className="flex items-center gap-2 text-sm" style={{ color: "var(--warm-500)" }}>
            <Loader2 className="w-5 h-5 animate-spin" />
            Loading…
          </div>
        ) : summary ? (
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
            <Kpi label="Participants (rows)" value={summary.participantCount} />
            <Kpi label="Micro-measure rows" value={summary.microMeasureCount} />
            <Kpi label="Needs checklists" value={summary.needsChecklistCount} />
            <Kpi label="Navigation outcomes" value={summary.navigationOutcomeCount} />
            <Kpi label="Milestone prompts" value={summary.milestonePromptCount} />
            <Kpi label="App activity rows" value={summary.appActivityCount} />
            <div className="col-span-full mt-4 p-4 rounded-xl" style={{ backgroundColor: "var(--lavender-50)" }}>
              <div className="font-medium mb-2" style={{ color: "var(--warm-700)" }}>
                Micro averages (sample up to 500)
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
    </div>
  );
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

function fmt(v: number | null): string {
  if (v == null || Number.isNaN(v)) return "—";
  return v.toFixed(2);
}

function toLocalInput(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
