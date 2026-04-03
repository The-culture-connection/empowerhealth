import { useEffect, useState } from "react";
import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  updateDoc,
  serverTimestamp,
  Timestamp,
} from "firebase/firestore";
import { firestore } from "../../firebase/firebase";
import { Loader2 } from "lucide-react";

const REASON_LABELS: Record<string, string> = {
  inaccurate_info: "Information looks wrong",
  harmful_or_unsafe: "Harmful or unsafe",
  wrong_identity_tags: "Identity / cultural tags",
  spam_or_duplicate: "Spam or duplicate",
  other: "Other",
};

type Row = {
  id: string;
  providerId: string;
  providerName?: string;
  userId: string;
  reasonCategory: string;
  reasonCategoryLabel?: string;
  details?: string;
  status?: string;
  createdAt?: Timestamp | null;
};

export function ProviderReportsAdmin() {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(firestore, "provider_reports"),
      orderBy("createdAt", "desc"),
    );
    const unsub = onSnapshot(
      q,
      (snap) => {
        const next: Row[] = [];
        snap.forEach((d) => {
          const x = d.data() as Record<string, unknown>;
          next.push({
            id: d.id,
            providerId: String(x.providerId ?? ""),
            providerName: x.providerName != null ? String(x.providerName) : undefined,
            userId: String(x.userId ?? ""),
            reasonCategory: String(x.reasonCategory ?? ""),
            details: x.details != null ? String(x.details) : undefined,
            status: x.status != null ? String(x.status) : "open",
            createdAt: x.createdAt as Timestamp | null | undefined,
          });
        });
        setRows(next);
        setLoading(false);
        setError("");
      },
      (err) => {
        console.error(err);
        setError(err.message || "Failed to load reports");
        setLoading(false);
      },
    );
    return () => unsub();
  }, []);

  async function setStatus(id: string, status: string) {
    setBusyId(id);
    try {
      await updateDoc(doc(firestore, "provider_reports", id), {
        status,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Update failed");
    } finally {
      setBusyId(null);
    }
  }

  if (loading) {
    return (
      <div className="p-8 flex items-center gap-2" style={{ color: "var(--warm-500)" }}>
        <Loader2 className="h-5 w-5 animate-spin" />
        Loading reports…
      </div>
    );
  }

  return (
    <div className="p-8 max-w-5xl">
      <h1 className="text-2xl font-semibold mb-2" style={{ color: "var(--warm-600)" }}>
        Provider listing reports
      </h1>
      <p className="text-sm mb-6" style={{ color: "var(--warm-500)" }}>
        Submitted from the app via <code className="text-xs">provider_reports</code>. Mark reviewed when triaged.
      </p>
      {error ? (
        <div className="mb-4 p-4 rounded-xl text-sm bg-red-50 text-red-700">{error}</div>
      ) : null}
      {rows.length === 0 ? (
        <p style={{ color: "var(--warm-500)" }}>No reports yet.</p>
      ) : (
        <ul className="space-y-4">
          {rows.map((r) => {
            const busy = busyId === r.id;
            const when = r.createdAt?.toDate?.()?.toLocaleString?.() ?? "—";
            const reasonLine =
              r.reasonCategoryLabel ??
              REASON_LABELS[r.reasonCategory] ??
              r.reasonCategory;
            return (
              <li
                key={r.id}
                className="rounded-2xl border p-5"
                style={{ backgroundColor: "white", borderColor: "var(--lavender-200)" }}
              >
                <div className="flex flex-wrap justify-between gap-4">
                  <div className="min-w-0">
                    <div className="font-medium" style={{ color: "var(--warm-600)" }}>
                      {r.providerName ?? r.providerId}
                    </div>
                    <div className="text-sm mt-1" style={{ color: "var(--warm-500)" }}>
                      {reasonLine} · {when}
                    </div>
                    <div className="text-xs mt-2 opacity-70">
                      Provider id: <code>{r.providerId}</code> · User: <code>{r.userId}</code>
                    </div>
                    {r.details ? (
                      <p className="text-sm mt-3" style={{ color: "var(--warm-600)" }}>
                        {r.details}
                      </p>
                    ) : null}
                    <div className="text-xs mt-2">
                      Status: <strong>{r.status ?? "open"}</strong>
                    </div>
                  </div>
                  <div className="flex flex-col gap-2 shrink-0">
                    <button
                      type="button"
                      disabled={busy || r.status === "acknowledged"}
                      onClick={() => setStatus(r.id, "acknowledged")}
                      className="px-3 py-2 rounded-xl text-sm border disabled:opacity-50"
                      style={{ borderColor: "var(--lavender-200)" }}
                    >
                      Acknowledge
                    </button>
                    <button
                      type="button"
                      disabled={busy || r.status === "resolved"}
                      onClick={() => setStatus(r.id, "resolved")}
                      className="px-3 py-2 rounded-xl text-sm text-white disabled:opacity-50"
                      style={{ backgroundColor: "var(--lavender-600)" }}
                    >
                      Resolved
                    </button>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
