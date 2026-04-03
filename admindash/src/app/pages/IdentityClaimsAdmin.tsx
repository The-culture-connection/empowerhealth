import { useEffect, useState } from "react";
import {
  collection,
  doc,
  getDocs,
  updateDoc,
  serverTimestamp,
  Timestamp,
} from "firebase/firestore";
import { firestore } from "../../firebase/firebase";
import { Check, X, Loader2 } from "lucide-react";

type Row = {
  id: string;
  providerId: string;
  userId: string;
  tagId: string;
  status: string;
  confidence?: string;
  sourceType?: string;
  sourceUrl?: string;
  createdAt?: Timestamp | null;
};

export function IdentityClaimsAdmin() {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const snap = await getDocs(collection(firestore, "provider_identity_claims"));
        if (cancelled) return;
        const next: Row[] = [];
        snap.forEach((d) => {
          const x = d.data() as Record<string, unknown>;
          next.push({
            id: d.id,
            providerId: String(x.providerId ?? ""),
            userId: String(x.userId ?? ""),
            tagId: String(x.tagId ?? ""),
            status: String(x.status ?? "pending"),
            confidence: x.confidence != null ? String(x.confidence) : undefined,
            sourceType: x.sourceType != null ? String(x.sourceType) : undefined,
            sourceUrl: x.sourceUrl != null ? String(x.sourceUrl) : undefined,
            createdAt: x.createdAt as Timestamp | null | undefined,
          });
        });
        next.sort((a, b) => {
          const ta = a.createdAt?.toMillis() ?? 0;
          const tb = b.createdAt?.toMillis() ?? 0;
          return tb - ta;
        });
        setRows(next);
        setLoading(false);
      } catch (e) {
        if (!cancelled) {
          console.error(e);
          setError(e instanceof Error ? e.message : "Failed to load claims");
          setLoading(false);
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  async function setClaimStatus(id: string, status: string) {
    setBusyId(id);
    try {
      await updateDoc(doc(firestore, "provider_identity_claims", id), {
        status,
        updatedAt: serverTimestamp(),
      });
      setRows((prev) =>
        prev.map((r) => (r.id === id ? { ...r, status } : r)),
      );
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
        Loading identity claims…
      </div>
    );
  }

  return (
    <div className="p-8 max-w-5xl">
      <h1 className="text-2xl font-semibold mb-2" style={{ color: "var(--warm-600)" }}>
        Provider identity claims
      </h1>
      <p className="text-sm mb-6" style={{ color: "var(--warm-500)" }}>
        Flat collection <code className="text-xs">provider_identity_claims</code>. Extend app writes with{" "}
        <code className="text-xs">confidence</code>, <code className="text-xs">sourceType</code>,{" "}
        <code className="text-xs">sourceUrl</code> as you roll out the full claims model.
      </p>
      {error ? (
        <div className="mb-4 p-4 rounded-xl text-sm bg-red-50 text-red-700">{error}</div>
      ) : null}
      {rows.length === 0 ? (
        <p style={{ color: "var(--warm-500)" }}>No claims yet.</p>
      ) : (
        <ul className="space-y-4">
          {rows.map((r) => {
            const busy = busyId === r.id;
            const when = r.createdAt?.toDate?.()?.toLocaleString?.() ?? "—";
            return (
              <li
                key={r.id}
                className="rounded-2xl border p-5"
                style={{ backgroundColor: "white", borderColor: "var(--lavender-200)" }}
              >
                <div className="flex flex-wrap justify-between gap-4">
                  <div className="min-w-0 text-sm">
                    <div>
                      <span className="font-medium">Tag id: </span>
                      <code>{r.tagId}</code>
                    </div>
                    <div className="mt-1">
                      <span className="font-medium">Provider: </span>
                      <code className="break-all">{r.providerId}</code>
                    </div>
                    <div className="mt-1">
                      <span className="font-medium">User: </span>
                      <code>{r.userId}</code>
                    </div>
                    <div className="mt-1">
                      Status: <strong>{r.status}</strong> · {when}
                    </div>
                    {r.sourceType ? (
                      <div className="mt-1">
                        Source type: <code>{r.sourceType}</code>
                        {r.confidence ? <> · confidence: {r.confidence}</> : null}
                      </div>
                    ) : null}
                    {r.sourceUrl ? (
                      <a
                        href={r.sourceUrl}
                        target="_blank"
                        rel="noreferrer"
                        className="text-xs text-purple-700 underline mt-1 inline-block break-all"
                      >
                        {r.sourceUrl}
                      </a>
                    ) : null}
                    <div className="text-xs opacity-60 mt-2">Doc: {r.id}</div>
                  </div>
                  <div className="flex flex-col gap-2 shrink-0">
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => setClaimStatus(r.id, "verified")}
                      className="inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl text-sm text-white disabled:opacity-50"
                      style={{ backgroundColor: "var(--lavender-600)" }}
                    >
                      {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
                      Verify
                    </button>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => setClaimStatus(r.id, "rejected")}
                      className="inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl text-sm border disabled:opacity-50"
                      style={{ borderColor: "var(--lavender-200)" }}
                    >
                      <X className="h-4 w-4" />
                      Reject
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
