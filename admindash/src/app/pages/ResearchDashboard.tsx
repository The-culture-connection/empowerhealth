import { useCallback, useEffect, useState } from "react";
import { auth } from "../../firebase/firebase";
import {
  downloadTextFile,
  exportResearchDataset,
  getResearchDashboardSummary,
  type ResearchInstrumentId,
} from "../../lib/researchApi";
import { RESEARCH_INSTRUMENTS, RESEARCH_SPEC_VERSION } from "@research/researchFieldSpec";
import { ClipboardList, Download, Loader2, RefreshCw } from "lucide-react";
import { ResearchNumericCodeReference } from "./ResearchNumericCodeReference";

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
  /** Which export action is running, e.g. `baseline-csv` or `all-json`. */
  const [exportingKey, setExportingKey] = useState<string | null>(null);

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

  const commonExportArgs = () => ({
    dateRange: range,
    studyId: studyId.trim() || undefined,
    recruitmentPathway: pathway === "" ? undefined : (Number(pathway) as 1 | 2),
  });

  async function handleExportInstrumentCsv(id: ResearchInstrumentId) {
    const key = `${id}-csv`;
    setExportingKey(key);
    setError("");
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const res = await exportResearchDataset({
        format: "csv",
        instruments: [id],
        ...commonExportArgs(),
      });
      const csv = csvForInstrument(id, res.files);
      if (!csv) {
        setError(`No CSV returned for ${instrumentLabel(id)}.`);
        return;
      }
      const stamp = new Date().toISOString().slice(0, 10);
      downloadTextFile(`${downloadStem(id)}_${stamp}.csv`, csv, "text/csv;charset=utf-8");
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Export failed");
    } finally {
      setExportingKey(null);
    }
  }

  async function handleExportInstrumentJson(id: ResearchInstrumentId) {
    const key = `${id}-json`;
    setExportingKey(key);
    setError("");
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const res = await exportResearchDataset({
        format: "json",
        instruments: [id],
        ...commonExportArgs(),
      });
      const rows = jsonRowsForInstrument(id, res.data);
      if (!Array.isArray(rows)) {
        setError(`No JSON rows returned for ${instrumentLabel(id)}.`);
        return;
      }
      const stamp = new Date().toISOString().slice(0, 10);
      downloadTextFile(
        `${downloadStem(id)}_${stamp}.json`,
        JSON.stringify(rows, null, 2),
        "application/json;charset=utf-8",
      );
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Export failed");
    } finally {
      setExportingKey(null);
    }
  }

  async function handleExportAllCsv() {
    setExportingKey("all-csv");
    setError("");
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const res = await exportResearchDataset({
        format: "csv",
        ...commonExportArgs(),
      });
      if (res.files) {
        const stamp = new Date().toISOString().slice(0, 10);
        for (const [name, csv] of Object.entries(res.files)) {
          if (name === "baseline" || name === "micro_measures" || name === "needs_checklist") continue;
          const fileStem =
            name === "baseline_export"
              ? "baseline_export"
              : name === "micro_measures_export"
                ? "micro_measures_export"
                : name === "needs_checklist_export"
                  ? "needs_checklist_export"
                  : `research_${name}`;
          downloadTextFile(`${fileStem}_${stamp}.csv`, csv, "text/csv;charset=utf-8");
        }
      }
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Export failed");
    } finally {
      setExportingKey(null);
    }
  }

  async function handleExportAllJson() {
    setExportingKey("all-json");
    setError("");
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const res = await exportResearchDataset({
        format: "json",
        ...commonExportArgs(),
      });
      const stamp = new Date().toISOString().slice(0, 10);
      const bundle = res.data ?? {};
      const baselineRows = bundle.baseline_export ?? bundle.baseline;
      if (Array.isArray(baselineRows)) {
        downloadTextFile(
          `baseline_export_${stamp}.json`,
          JSON.stringify(baselineRows, null, 2),
          "application/json;charset=utf-8",
        );
      }
      const microRows = bundle.micro_measures_export ?? bundle.micro_measures;
      if (Array.isArray(microRows)) {
        downloadTextFile(
          `micro_measures_export_${stamp}.json`,
          JSON.stringify(microRows, null, 2),
          "application/json;charset=utf-8",
        );
      }
      const needsRows = bundle.needs_checklist_export ?? bundle.needs_checklist;
      if (Array.isArray(needsRows)) {
        downloadTextFile(
          `needs_checklist_export_${stamp}.json`,
          JSON.stringify(needsRows, null, 2),
          "application/json;charset=utf-8",
        );
      }
      downloadTextFile(`research_export_${stamp}.json`, JSON.stringify(bundle, null, 2), "application/json;charset=utf-8");
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Export failed");
    } finally {
      setExportingKey(null);
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

      <ResearchNumericCodeReference />

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
        <div className="border-t pt-4 mt-4 space-y-3" style={{ borderColor: "var(--lavender-100)" }}>
          <h3 className="text-sm font-medium" style={{ color: "var(--warm-700)" }}>
            Export by instrument
          </h3>
          <p className="text-xs leading-relaxed" style={{ color: "var(--warm-500)" }}>
            Each row downloads one dataset for the range and filters above. Baseline and micro-measures use the{" "}
            <code className="text-xs rounded px-1" style={{ backgroundColor: "var(--lavender-50)" }}>
              baseline_export
            </code>{" "}
            and{" "}
            <code className="text-xs rounded px-1" style={{ backgroundColor: "var(--lavender-50)" }}>
              micro_measures_export
            </code>{" "}
            file names. Needs checklist uses{" "}
            <code className="text-xs rounded px-1" style={{ backgroundColor: "var(--lavender-50)" }}>
              needs_checklist_export
            </code>
            . Other instruments use the <code className="text-xs">research_*</code> prefix on the file name.
          </p>
          <div className="rounded-xl border overflow-hidden" style={{ borderColor: "var(--lavender-200)" }}>
            <table className="w-full text-sm">
              <thead>
                <tr style={{ backgroundColor: "var(--lavender-50)" }}>
                  <th className="text-left px-3 py-2 font-medium" style={{ color: "var(--warm-700)" }}>
                    Instrument
                  </th>
                  <th className="text-right px-2 py-2 font-medium whitespace-nowrap w-px">CSV</th>
                  <th className="text-right px-2 py-2 font-medium whitespace-nowrap w-px">JSON</th>
                </tr>
              </thead>
              <tbody>
                {RESEARCH_INSTRUMENTS.map((inst) => (
                  <tr key={inst.id} className="border-t" style={{ borderColor: "var(--lavender-100)" }}>
                    <td className="px-3 py-2.5 align-middle" style={{ color: "var(--warm-700)" }}>
                      {instrumentLabel(inst.id)}
                    </td>
                    <td className="px-2 py-2 text-right align-middle">
                      <button
                        type="button"
                        disabled={exportingKey !== null}
                        onClick={() => void handleExportInstrumentCsv(inst.id)}
                        className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium disabled:opacity-45"
                        style={{ backgroundColor: "var(--eh-primary)", color: "white" }}
                      >
                        {exportingKey === `${inst.id}-csv` ? (
                          <Loader2 className="w-3.5 h-3.5 animate-spin" />
                        ) : (
                          <Download className="w-3.5 h-3.5" />
                        )}
                        CSV
                      </button>
                    </td>
                    <td className="px-2 py-2 text-right align-middle">
                      <button
                        type="button"
                        disabled={exportingKey !== null}
                        onClick={() => void handleExportInstrumentJson(inst.id)}
                        className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium border disabled:opacity-45"
                        style={{ borderColor: "var(--lavender-300)", color: "var(--warm-700)" }}
                      >
                        {exportingKey === `${inst.id}-json` ? (
                          <Loader2 className="w-3.5 h-3.5 animate-spin" />
                        ) : (
                          <Download className="w-3.5 h-3.5" />
                        )}
                        JSON
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="flex flex-wrap items-center gap-3 pt-1">
            <span className="text-xs font-medium" style={{ color: "var(--warm-600)" }}>
              Full dataset (all instruments)
            </span>
            <button
              type="button"
              disabled={exportingKey !== null}
              onClick={() => void handleExportAllCsv()}
              className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg text-white text-xs disabled:opacity-45"
              style={{ backgroundColor: "var(--eh-primary)" }}
            >
              {exportingKey === "all-csv" ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Download className="w-3.5 h-3.5" />}
              All CSV files
            </button>
            <button
              type="button"
              disabled={exportingKey !== null}
              onClick={() => void handleExportAllJson()}
              className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg border text-xs disabled:opacity-45"
              style={{ borderColor: "var(--lavender-300)", color: "var(--warm-700)" }}
            >
              {exportingKey === "all-json" ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Download className="w-3.5 h-3.5" />}
              All JSON + bundle
            </button>
          </div>
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
            <Kpi label="Baseline (rows)" value={summary.baselineCount ?? 0} />
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

const INSTRUMENT_LABELS: Record<ResearchInstrumentId, string> = {
  participants: "Participants",
  baseline: "Baseline",
  micro_measures: "Micro-measures",
  needs_checklist: "Needs checklist",
  navigation_outcomes: "Navigation outcomes",
  milestone_prompts: "Milestone prompts",
  app_activity: "App activity",
};

function instrumentLabel(id: ResearchInstrumentId): string {
  return INSTRUMENT_LABELS[id];
}

/** File stem for a single-instrument download (matches prior naming). */
function downloadStem(id: ResearchInstrumentId): string {
  if (id === "baseline") return "baseline_export";
  if (id === "micro_measures") return "micro_measures_export";
  if (id === "needs_checklist") return "needs_checklist_export";
  return `research_${id}`;
}

function csvForInstrument(id: ResearchInstrumentId, files?: Record<string, string>): string | undefined {
  if (!files) return undefined;
  if (id === "baseline") return files.baseline_export ?? files.baseline;
  if (id === "micro_measures") return files.micro_measures_export ?? files.micro_measures;
  if (id === "needs_checklist") return files.needs_checklist_export ?? files.needs_checklist;
  return files[id];
}

function jsonRowsForInstrument(
  id: ResearchInstrumentId,
  data?: Record<string, Record<string, unknown>[]>,
): Record<string, unknown>[] | undefined {
  if (!data) return undefined;
  if (id === "baseline") return data.baseline_export ?? data.baseline;
  if (id === "micro_measures") return data.micro_measures_export ?? data.micro_measures;
  if (id === "needs_checklist") return data.needs_checklist_export ?? data.needs_checklist;
  return data[id];
}

function toLocalInput(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
