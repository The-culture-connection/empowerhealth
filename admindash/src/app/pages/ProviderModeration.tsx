import { useEffect, useState } from "react";
import {
  collection,
  doc,
  onSnapshot,
  query,
  updateDoc,
  where,
  serverTimestamp,
  Timestamp,
} from "firebase/firestore";
import { firestore } from "../../firebase/firebase";
import { Check, X, Loader2 } from "lucide-react";

type UserProviderRow = {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  website?: string;
  source?: string;
  status?: string;
  submittedBy?: string;
  userId?: string;
  submissionNotes?: string | null;
  createdAt?: Timestamp | null;
  locations?: Array<{
    address?: string;
    city?: string;
    state?: string;
    zip?: string;
    phone?: string;
  }>;
  specialties?: string[];
};

function formatWhen(ts: Timestamp | null | undefined): string {
  if (!ts) return "—";
  try {
    return ts.toDate().toLocaleString();
  } catch {
    return "—";
  }
}

export function ProviderModeration() {
  const [rows, setRows] = useState<UserProviderRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(firestore, "UserProviders"),
      where("status", "==", "pending"),
    );
    const unsub = onSnapshot(
      q,
      (snap) => {
        const next: UserProviderRow[] = [];
        snap.forEach((d) => {
          const data = d.data() as Record<string, unknown>;
          next.push({
            id: d.id,
            name: (data.name as string) || "(No name)",
            email: data.email as string | undefined,
            phone: data.phone as string | undefined,
            website: data.website as string | undefined,
            source: data.source as string | undefined,
            status: data.status as string | undefined,
            submittedBy: data.submittedBy as string | undefined,
            userId: data.userId as string | undefined,
            submissionNotes: data.submissionNotes as string | null | undefined,
            createdAt: data.createdAt as Timestamp | null | undefined,
            locations: Array.isArray(data.locations)
              ? (data.locations as UserProviderRow["locations"])
              : undefined,
            specialties: Array.isArray(data.specialties)
              ? (data.specialties as string[])
              : undefined,
          });
        });
        next.sort((a, b) => {
          const ta = a.createdAt?.toMillis() ?? 0;
          const tb = b.createdAt?.toMillis() ?? 0;
          return tb - ta;
        });
        setRows(next);
        setLoading(false);
        setError("");
      },
      (err) => {
        console.error(err);
        setError(err.message || "Failed to load UserProviders");
        setLoading(false);
      },
    );
    return () => unsub();
  }, []);

  async function setDecision(id: string, approved: boolean) {
    setBusyId(id);
    setError("");
    try {
      await updateDoc(doc(firestore, "UserProviders", id), {
        status: approved ? "approved" : "rejected",
        mamaApproved: approved ? true : false,
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
        Loading pending providers…
      </div>
    );
  }

  return (
    <div className="p-8 max-w-5xl">
      <div className="mb-6">
        <h1 className="text-2xl font-semibold" style={{ color: "var(--warm-600)" }}>
          Provider moderation
        </h1>
        <p className="text-sm mt-1" style={{ color: "var(--warm-500)" }}>
          Pending rows in <code className="text-xs">UserProviders</code> (user submissions). Approve sets{" "}
          <code className="text-xs">status</code> to <code className="text-xs">approved</code> and{" "}
          <code className="text-xs">mamaApproved</code> to true; deny sets{" "}
          <code className="text-xs">status</code> to <code className="text-xs">rejected</code>.
        </p>
      </div>

      {error ? (
        <div
          className="mb-4 p-4 rounded-xl text-sm"
          style={{ backgroundColor: "#fef2f2", color: "#b91c1c" }}
        >
          {error}
        </div>
      ) : null}

      {rows.length === 0 ? (
        <p style={{ color: "var(--warm-500)" }}>No pending provider submissions.</p>
      ) : (
        <ul className="space-y-4">
          {rows.map((r) => {
            const loc = r.locations?.[0];
            const locLine = loc
              ? [loc.address, [loc.city, loc.state].filter(Boolean).join(", "), loc.zip]
                  .filter(Boolean)
                  .join(" · ")
              : null;
            const busy = busyId === r.id;
            return (
              <li
                key={r.id}
                className="rounded-2xl border p-5"
                style={{
                  backgroundColor: "white",
                  borderColor: "var(--lavender-200)",
                }}
              >
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div className="min-w-0 flex-1">
                    <div className="font-semibold text-lg" style={{ color: "var(--warm-600)" }}>
                      {r.name}
                    </div>
                    {r.specialties && r.specialties.length > 0 ? (
                      <div className="text-sm mt-1" style={{ color: "var(--warm-500)" }}>
                        {r.specialties.join(", ")}
                      </div>
                    ) : null}
                    <dl className="mt-3 grid gap-1 text-sm" style={{ color: "var(--warm-600)" }}>
                      {r.email ? (
                        <div>
                          <span className="font-medium">Email: </span>
                          {r.email}
                        </div>
                      ) : null}
                      {r.phone ? (
                        <div>
                          <span className="font-medium">Phone: </span>
                          {r.phone}
                        </div>
                      ) : null}
                      {r.website ? (
                        <div>
                          <span className="font-medium">Website: </span>
                          {r.website}
                        </div>
                      ) : null}
                      {locLine ? (
                        <div>
                          <span className="font-medium">Location: </span>
                          {locLine}
                        </div>
                      ) : null}
                      <div>
                        <span className="font-medium">Source: </span>
                        {r.source ?? "—"}
                      </div>
                      <div>
                        <span className="font-medium">Submitted: </span>
                        {formatWhen(r.createdAt ?? null)}
                      </div>
                      <div>
                        <span className="font-medium">User ID: </span>
                        <code className="text-xs break-all">{r.submittedBy ?? r.userId ?? "—"}</code>
                      </div>
                      {r.submissionNotes ? (
                        <div>
                          <span className="font-medium">Notes: </span>
                          {r.submissionNotes}
                        </div>
                      ) : null}
                      <div className="text-xs opacity-70 pt-1">Document: {r.id}</div>
                    </dl>
                  </div>
                  <div className="flex flex-col gap-2 shrink-0">
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => setDecision(r.id, true)}
                      className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-white disabled:opacity-50"
                      style={{ backgroundColor: "var(--lavender-600)" }}
                    >
                      {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
                      Approve
                    </button>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => setDecision(r.id, false)}
                      className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl text-sm font-medium border disabled:opacity-50"
                      style={{
                        borderColor: "var(--lavender-200)",
                        color: "var(--warm-600)",
                        backgroundColor: "var(--eh-background)",
                      }}
                    >
                      {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <X className="h-4 w-4" />}
                      Deny
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
