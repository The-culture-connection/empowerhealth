import { useCallback, useEffect, useState } from "react";
import { Loader2, Plus, Trash2 } from "lucide-react";
import { auth } from "../../firebase/firebase";
import {
  addRecruitmentPathway,
  deleteRecruitmentPathway,
  listRecruitmentPathways,
  type RecruitmentPathwayEntry,
} from "../../lib/researchApi";

export function RecruitmentPathwayEditor() {
  const [pathways, setPathways] = useState<RecruitmentPathwayEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [newCode, setNewCode] = useState("");
  const [newLabel, setNewLabel] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const list = await listRecruitmentPathways();
      setPathways(list);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to load pathways");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function handleAdd(e: React.FormEvent) {
    e.preventDefault();
    const code = parseInt(newCode, 10);
    const label = newLabel.trim();
    if (!Number.isFinite(code) || !label) {
      setError("Enter a numeric code (1–99) and label.");
      return;
    }
    setBusy(true);
    setError("");
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const list = await addRecruitmentPathway(code, label);
      setPathways(list);
      setNewCode("");
      setNewLabel("");
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Add failed");
    } finally {
      setBusy(false);
    }
  }

  async function handleDelete(code: number) {
    if (!window.confirm(`Delete recruitment pathway ${code}? This cannot be undone if no participants use it.`)) {
      return;
    }
    setBusy(true);
    setError("");
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const list = await deleteRecruitmentPathway(code);
      setPathways(list);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Delete failed (pathway may be in use)");
    } finally {
      setBusy(false);
    }
  }

  const rows = pathways.map((p) => ({
    code: String(p.code),
    meaning: p.label,
  }));

  return (
    <section>
      <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
        {"Participants & baseline — "}
        <code className="font-mono text-sm">recruitment_pathway</code>
      </h3>
      <p className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
        Shown in research onboarding (single select). Codes are stored on participants and baseline exports; cohort
        summaries use <code className="font-mono text-xs">research_summary_by_pathway/{"{code}"}</code>. Delete is blocked
        when any participant already has that code.
      </p>
      {error ? (
        <p className="text-sm text-red-600 mb-2" role="alert">
          {error}
        </p>
      ) : null}
      {loading ? (
        <div className="flex items-center gap-2 text-sm" style={{ color: "var(--warm-500)" }}>
          <Loader2 className="w-4 h-4 animate-spin" /> Loading pathways…
        </div>
      ) : (
        <div className="overflow-x-auto rounded-lg border text-sm" style={{ borderColor: "var(--lavender-200)" }}>
          <table className="w-full min-w-[280px] border-collapse">
            <thead>
              <tr style={{ backgroundColor: "var(--lavender-50)" }}>
                <th className="text-left px-3 py-2 font-medium" style={{ color: "var(--warm-700)", width: "6rem" }}>
                  Code
                </th>
                <th className="text-left px-3 py-2 font-medium" style={{ color: "var(--warm-700)" }}>
                  Meaning
                </th>
                <th className="w-14" />
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.code} className="border-t" style={{ borderColor: "var(--lavender-100)" }}>
                  <td className="px-3 py-2 font-mono" style={{ color: "var(--eh-primary)" }}>
                    {r.code}
                  </td>
                  <td className="px-3 py-2" style={{ color: "var(--warm-700)" }}>
                    {r.meaning}
                  </td>
                  <td className="px-2 py-2 text-right">
                    <button
                      type="button"
                      className="p-1.5 rounded hover:bg-red-50 text-red-600 disabled:opacity-40"
                      title="Delete pathway"
                      disabled={busy || pathways.length <= 1}
                      onClick={() => void handleDelete(parseInt(r.code, 10))}
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <form onSubmit={(e) => void handleAdd(e)} className="mt-4 flex flex-wrap gap-3 items-end">
        <label className="block text-sm">
          <span style={{ color: "var(--warm-600)" }}>New code (1–99)</span>
          <input
            type="number"
            min={1}
            max={99}
            className="mt-1 block w-24 rounded-lg border px-3 py-2 font-mono"
            style={{ borderColor: "var(--lavender-200)" }}
            value={newCode}
            onChange={(e) => setNewCode(e.target.value)}
            disabled={busy}
          />
        </label>
        <label className="block text-sm flex-1 min-w-[12rem]">
          <span style={{ color: "var(--warm-600)" }}>Label</span>
          <input
            type="text"
            maxLength={120}
            className="mt-1 block w-full rounded-lg border px-3 py-2"
            style={{ borderColor: "var(--lavender-200)" }}
            value={newLabel}
            onChange={(e) => setNewLabel(e.target.value)}
            placeholder="e.g. Community health worker cohort"
            disabled={busy}
          />
        </label>
        <button
          type="submit"
          disabled={busy}
          className="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
          style={{ backgroundColor: "var(--eh-primary)" }}
        >
          {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
          Add pathway
        </button>
      </form>
    </section>
  );
}
