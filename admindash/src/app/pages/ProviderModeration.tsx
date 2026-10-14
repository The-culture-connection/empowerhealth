import { useEffect, useState } from "react";
import {
  collection,
  doc,
  getDoc,
  onSnapshot,
  query,
  where,
  serverTimestamp,
  writeBatch,
  Timestamp,
} from "firebase/firestore";
import { auth, firestore } from "../../firebase/firebase";
import {
  buildProvidersPayloadFromUserProvider,
  publicProviderDocIdForUserProvider,
} from "../../lib/userProviderPromotion";
import { Check, X, Loader2 } from "lucide-react";

type UserProviderRow = {
  id: string;
  data: Record<string, unknown>;
};

function formatWhen(ts: Timestamp | null | undefined): string {
  if (!ts) return "—";
  try {
    return ts.toDate().toLocaleString();
  } catch {
    return "—";
  }
}

function str(v: unknown): string | null {
  if (v == null) return null;
  const s = String(v).trim();
  return s.length ? s : null;
}

function formatBool(v: unknown): string {
  if (v === true) return "Yes";
  if (v === false) return "No";
  return "—";
}

function formatStringArray(v: unknown): string | null {
  if (!Array.isArray(v) || v.length === 0) return null;
  return v.map((x) => String(x)).join(", ");
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
          next.push({
            id: d.id,
            data: d.data() as Record<string, unknown>,
          });
        });
        next.sort((a, b) => {
          const ca = a.data.createdAt;
          const cb = b.data.createdAt;
          const ta = ca instanceof Timestamp ? ca.toMillis() : 0;
          const tb = cb instanceof Timestamp ? cb.toMillis() : 0;
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
      const uid = auth.currentUser?.uid ?? null;
      const snap = await getDoc(doc(firestore, "UserProviders", id));
      if (!snap.exists()) {
        setError("This submission is no longer in the queue.");
        return;
      }
      const raw = snap.data() as Record<string, unknown>;
      const pubId = publicProviderDocIdForUserProvider(id);

      if (approved) {
        const payload = buildProvidersPayloadFromUserProvider(id, raw);
        const batch = writeBatch(firestore);
        batch.set(doc(firestore, "providers", pubId), payload);
        batch.update(
          doc(firestore, "UserProviders", id),
          {
            status: "approved",
            mamaApproved: true,
            updatedAt: serverTimestamp(),
            moderatedAt: serverTimestamp(),
            moderationDecision: "approved",
            publishedProviderId: pubId,
            ...(uid ? { moderatedBy: uid } : {}),
          },
        );
        await batch.commit();
      } else {
        const batch = writeBatch(firestore);
        batch.delete(doc(firestore, "providers", pubId));
        batch.update(
          doc(firestore, "UserProviders", id),
          {
            status: "rejected",
            mamaApproved: false,
            updatedAt: serverTimestamp(),
            moderatedAt: serverTimestamp(),
            moderationDecision: "rejected",
            publishedProviderId: null,
            ...(uid ? { moderatedBy: uid } : {}),
          },
        );
        await batch.commit();
      }
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
          Pending rows in <code className="text-xs">UserProviders</code>.{" "}
          <strong>Approve</strong> writes the full submission into the public{" "}
          <code className="text-xs">providers</code> collection (document id{" "}
          <code className="text-xs">up_&#123;submissionId&#125;</code>) with{" "}
          <code className="text-xs">source: user_submission</code> so directory search can return them.
          <strong className="ml-1">Deny</strong> removes that public row (if any) and marks the submission rejected.
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
            const d = r.data;
            const name = str(d.name) ?? "(No name)";
            const locs = Array.isArray(d.locations) ? d.locations : [];
            const loc0 =
              locs[0] && typeof locs[0] === "object"
                ? (locs[0] as Record<string, unknown>)
                : null;
            const locLine = loc0
              ? [
                  str(loc0.address),
                  [str(loc0.city), str(loc0.state)].filter(Boolean).join(", "),
                  str(loc0.zip),
                ]
                  .filter(Boolean)
                  .join(" · ")
              : null;
            const busy = busyId === r.id;
            const createdAt = d.createdAt instanceof Timestamp ? d.createdAt : null;

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
                      {name}
                    </div>
                    {(str(d.practiceName) || str(d.specialty)) && (
                      <div className="text-sm mt-1" style={{ color: "var(--warm-500)" }}>
                        {[str(d.practiceName), str(d.specialty)].filter(Boolean).join(" · ")}
                      </div>
                    )}
                    <dl
                      className="mt-3 grid gap-1.5 text-sm"
                      style={{ color: "var(--warm-600)" }}
                    >
                      <Meta label="NPI" value={str(d.npi)} />
                      <Meta label="Provider types" value={formatStringArray(d.providerTypes)} />
                      <Meta label="Specialties" value={formatStringArray(d.specialties)} />
                      <Meta label="Email" value={str(d.email)} />
                      <Meta label="Phone" value={str(d.phone)} />
                      <Meta label="Website" value={str(d.website)} />
                      <Meta label="Location" value={locLine} />
                      <Meta
                        label="Accepted health"
                        value={
                          formatStringArray(d.acceptedHealthTypes) ??
                          str(d.acceptedHealthType)
                        }
                      />
                      <Meta label="Accepting new patients" value={formatBool(d.acceptingNewPatients)} />
                      <Meta label="Accepts pregnant" value={formatBool(d.acceptsPregnantWomen)} />
                      <Meta label="Accepts newborns" value={formatBool(d.acceptsNewborns)} />
                      <Meta label="Telehealth" value={formatBool(d.telehealth)} />
                      <Meta
                        label="Rating / reviews"
                        value={
                          d.rating != null || d.reviewCount != null
                            ? `${d.rating ?? "—"} ★ · ${d.reviewCount ?? 0} reviews`
                            : null
                        }
                      />
                      <Meta label="Identity tags" value={formatIdentityTagsBrief(d.identityTags)} />
                      <Meta label="Source" value={str(d.source)} />
                      <Meta label="Submitted" value={formatWhen(createdAt)} />
                      <Meta
                        label="Submitted by (uid)"
                        value={str(d.submittedBy) ?? str(d.userId)}
                      />
                      <Meta label="Submission notes" value={str(d.submissionNotes)} />
                      <div className="text-xs opacity-70 pt-1">
                        UserProviders id: {r.id} · Public id if approved:{" "}
                        {publicProviderDocIdForUserProvider(r.id)}
                      </div>
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

function Meta({ label, value }: { label: string; value: string | null }) {
  if (!value) return null;
  return (
    <div>
      <span className="font-medium">{label}: </span>
      {value}
    </div>
  );
}

function formatIdentityTagsBrief(raw: unknown): string | null {
  if (!Array.isArray(raw) || raw.length === 0) return null;
  const names = raw
    .map((t) => {
      if (!t || typeof t !== "object") return null;
      const n = (t as Record<string, unknown>).name;
      return n != null ? String(n) : null;
    })
    .filter((x): x is string => Boolean(x));
  if (names.length === 0) return `${raw.length} tag(s)`;
  return names.join(", ");
}
