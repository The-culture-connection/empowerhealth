import { useCallback, useState } from "react";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  updateDoc,
  where,
  Timestamp,
} from "firebase/firestore";
import { auth, firestore } from "../../firebase/firebase";
import { EyeOff, Loader2, Search, Trash2 } from "lucide-react";

type ClaimRow = {
  id: string;
  data: Record<string, unknown>;
};

function formatValue(v: unknown): string {
  if (v == null) return "—";
  if (typeof v === "boolean") return v ? "true" : "false";
  if (typeof v === "number" || typeof v === "string") return String(v);
  if (v instanceof Timestamp) {
    try {
      return v.toDate().toLocaleString();
    } catch {
      return String(v);
    }
  }
  if (typeof v === "object" && v !== null && "toDate" in v) {
    try {
      return (v as { toDate: () => Date }).toDate().toLocaleString();
    } catch {
      /* fall through */
    }
  }
  try {
    return JSON.stringify(v, null, 0);
  } catch {
    return String(v);
  }
}

function sortedKeys(obj: Record<string, unknown>): string[] {
  return Object.keys(obj).sort((a, b) => a.localeCompare(b));
}

export function ProviderDirectoryAdmin() {
  const [idInput, setIdInput] = useState("");
  const [data, setData] = useState<Record<string, unknown> | null>(null);
  const [loadedId, setLoadedId] = useState<string | null>(null);
  const [claims, setClaims] = useState<ClaimRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  const loadProvider = useCallback(async () => {
    const id = idInput.trim();
    if (!id) {
      setError("Enter a Firestore document id (e.g. up_… or npi_…).");
      return;
    }
    setLoading(true);
    setError("");
    setData(null);
    setClaims([]);
    setLoadedId(null);
    try {
      const snap = await getDoc(doc(firestore, "providers", id));
      if (!snap.exists()) {
        setError(`No document at providers/${id}`);
        setLoading(false);
        return;
      }
      const raw = snap.data() as Record<string, unknown>;
      setData(raw);
      setLoadedId(id);

      const cq = query(collection(firestore, "provider_identity_claims"), where("providerId", "==", id));
      const claimSnap = await getDocs(cq);
      const next: ClaimRow[] = [];
      claimSnap.forEach((d) => next.push({ id: d.id, data: d.data() as Record<string, unknown> }));
      next.sort((a, b) => {
        const ta = (a.data.createdAt as Timestamp | undefined)?.toMillis?.() ?? 0;
        const tb = (b.data.createdAt as Timestamp | undefined)?.toMillis?.() ?? 0;
        return tb - ta;
      });
      setClaims(next);
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Load failed");
    } finally {
      setLoading(false);
    }
  }, [idInput]);

  async function setHidden(hidden: boolean) {
    if (!loadedId) return;
    setBusy(true);
    setError("");
    const uid = auth.currentUser?.uid ?? null;
    try {
      await updateDoc(doc(firestore, "providers", loadedId), {
        directoryHidden: hidden,
        directoryHiddenAt: serverTimestamp(),
        ...(uid ? { directoryHiddenBy: uid } : {}),
        updatedAt: serverTimestamp(),
      });
      setData((prev) =>
        prev
          ? {
              ...prev,
              directoryHidden: hidden,
            }
          : prev,
      );
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Update failed");
    } finally {
      setBusy(false);
    }
  }

  async function hardDelete() {
    if (!loadedId) return;
    if (
      !window.confirm(
        `Permanently delete providers/${loadedId}? This cannot be undone. Reviews and claims are not deleted.`,
      )
    ) {
      return;
    }
    setBusy(true);
    setError("");
    try {
      await deleteDoc(doc(firestore, "providers", loadedId));
      setData(null);
      setClaims([]);
      setLoadedId(null);
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Delete failed");
    } finally {
      setBusy(false);
    }
  }

  const hidden = data?.directoryHidden === true;

  return (
    <div className="p-8 max-w-5xl">
      <h1 className="text-2xl font-semibold mb-2" style={{ color: "var(--warm-600)" }}>
        Provider directory (Firestore)
      </h1>
      <p className="text-sm mb-6" style={{ color: "var(--warm-500)" }}>
        Load a <code className="text-xs">providers</code> document by id. Shows every stored field, related{" "}
        <code className="text-xs">provider_identity_claims</code>, and actions to hide the listing from the app or delete
        the document.
      </p>

      <div className="flex flex-wrap gap-2 mb-6">
        <input
          type="text"
          value={idInput}
          onChange={(e) => setIdInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && loadProvider()}
          placeholder="Provider document id"
          className="flex-1 min-w-[200px] px-4 py-2 rounded-xl border text-sm"
          style={{ borderColor: "var(--lavender-200)" }}
        />
        <button
          type="button"
          disabled={loading}
          onClick={() => void loadProvider()}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-white disabled:opacity-50"
          style={{ backgroundColor: "var(--lavender-600)" }}
        >
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Search className="h-4 w-4" />}
          Load
        </button>
      </div>

      {error ? (
        <div className="mb-4 p-4 rounded-xl text-sm bg-red-50 text-red-700">{error}</div>
      ) : null}

      {data && loadedId ? (
        <div className="space-y-6">
          <div className="flex flex-wrap gap-2">
            {hidden ? (
              <button
                type="button"
                disabled={busy}
                onClick={() => void setHidden(false)}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm border disabled:opacity-50"
                style={{ borderColor: "var(--lavender-200)" }}
              >
                Show in app again
              </button>
            ) : (
              <button
                type="button"
                disabled={busy}
                onClick={() => void setHidden(true)}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-white disabled:opacity-50"
                style={{ backgroundColor: "#b45309" }}
              >
                {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <EyeOff className="h-4 w-4" />}
                Hide from app (directory)
              </button>
            )}
            <button
              type="button"
              disabled={busy}
              onClick={() => void hardDelete()}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium border border-red-300 text-red-700 disabled:opacity-50"
              style={{ backgroundColor: "#fef2f2" }}
            >
              {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
              Delete document
            </button>
          </div>

          {hidden ? (
            <p className="text-sm text-amber-800 bg-amber-50 border border-amber-200 rounded-xl p-3">
              This row is hidden from in-app directory merge, profile load by id, and Mama Approved lists. API-sourced
              results may still appear unless you also manage upstream data.
            </p>
          ) : null}

          <section>
            <h2 className="text-lg font-semibold mb-3" style={{ color: "var(--warm-600)" }}>
              All fields
            </h2>
            <dl className="rounded-2xl border p-4 text-sm space-y-2" style={{ borderColor: "var(--lavender-200)", backgroundColor: "white" }}>
              {sortedKeys(data).map((k) => (
                <div key={k} className="grid grid-cols-1 sm:grid-cols-[minmax(0,220px)_1fr] gap-x-4 gap-y-1 border-b border-gray-100 pb-2 last:border-0 last:pb-0">
                  <dt className="font-mono text-xs opacity-80 shrink-0">{k}</dt>
                  <dd className="break-words" style={{ color: "var(--warm-600)" }}>
                    {typeof data[k] === "object" && data[k] !== null && !(data[k] instanceof Timestamp) ? (
                      <pre className="text-xs whitespace-pre-wrap bg-gray-50 p-2 rounded-lg overflow-x-auto">
                        {formatValue(data[k])}
                      </pre>
                    ) : (
                      formatValue(data[k])
                    )}
                  </dd>
                </div>
              ))}
            </dl>
          </section>

          <section>
            <h2 className="text-lg font-semibold mb-3" style={{ color: "var(--warm-600)" }}>
              Identity claims ({claims.length})
            </h2>
            {claims.length === 0 ? (
              <p className="text-sm" style={{ color: "var(--warm-500)" }}>
                No rows in <code className="text-xs">provider_identity_claims</code> for this provider id.
              </p>
            ) : (
              <ul className="space-y-3">
                {claims.map((c) => (
                  <li
                    key={c.id}
                    className="rounded-xl border p-4 text-sm"
                    style={{ backgroundColor: "white", borderColor: "var(--lavender-200)" }}
                  >
                    <div className="font-mono text-xs mb-2 opacity-70">
                      {c.id}
                    </div>
                    <dl className="space-y-1">
                      {sortedKeys(c.data).map((k) => (
                        <div key={k}>
                          <span className="font-medium">{k}: </span>
                          <span className="break-words">{formatValue(c.data[k])}</span>
                        </div>
                      ))}
                    </dl>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>
      ) : null}
    </div>
  );
}
