import { useCallback, useEffect, useState } from "react";
import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  serverTimestamp,
  Timestamp,
} from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { firestore, functions } from "../../firebase/firebase";
import { Check, X, Loader2, Pencil, Trash2 } from "lucide-react";

const backfillClaimsCallable = httpsCallable(functions, "adminBackfillProviderIdentityClaims");

type Row = {
  id: string;
  providerId: string;
  userId: string;
  tagId: string;
  tagName?: string;
  category?: string;
  sourceReviewId?: string;
  status: string;
  confidence?: string;
  sourceType?: string;
  sourceUrl?: string;
  createdAt?: Timestamp | null;
};

type ProviderIdentityTag = {
  id: string;
  name: string;
  category: string;
  source: string;
  verificationStatus: string;
  verifiedAt?: Timestamp | null;
  verifiedBy?: string | null;
};

function asString(v: unknown, fallback = ""): string {
  if (v == null) return fallback;
  return String(v);
}

function readProviderTagArray(raw: unknown): ProviderIdentityTag[] {
  if (!Array.isArray(raw)) return [];
  const out: ProviderIdentityTag[] = [];
  for (const t of raw) {
    if (!t || typeof t !== "object") continue;
    const m = t as Record<string, unknown>;
    out.push({
      id: asString(m.id),
      name: asString(m.name),
      category: asString(m.category),
      source: asString(m.source, "user_claim"),
      verificationStatus: asString(m.verificationStatus, "pending"),
      verifiedAt: m.verifiedAt instanceof Timestamp ? m.verifiedAt : null,
      verifiedBy: m.verifiedBy != null ? String(m.verifiedBy) : null,
    });
  }
  return out;
}

export function IdentityClaimsAdmin() {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editName, setEditName] = useState("");
  const [editCategory, setEditCategory] = useState("");
  const [editSource, setEditSource] = useState("");
  const [backfillBusy, setBackfillBusy] = useState(false);
  const [backfillSummary, setBackfillSummary] = useState("");

  const fetchClaims = useCallback(async () => {
    setError("");
    setLoading(true);
    try {
      const snap = await getDocs(collection(firestore, "provider_identity_claims"));
      const next: Row[] = [];
      snap.forEach((d) => {
        const x = d.data() as Record<string, unknown>;
        next.push({
          id: d.id,
          providerId: String(x.providerId ?? ""),
          userId: String(x.userId ?? ""),
          tagId: String(x.tagId ?? ""),
          tagName: x.tagName != null ? String(x.tagName) : undefined,
          category: x.category != null ? String(x.category) : undefined,
          sourceReviewId: x.sourceReviewId != null ? String(x.sourceReviewId) : undefined,
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
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Failed to load claims");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchClaims();
  }, [fetchClaims]);

  async function runBackfillMissingClaims() {
    setBackfillBusy(true);
    setBackfillSummary("");
    setError("");
    let totalCreated = 0;
    let batches = 0;
    try {
      let startAfter: string | null = null;
      while (batches < 80) {
        batches++;
        const res = await backfillClaimsCallable({
          maxProviders: 200,
          ...(startAfter ? { startAfter } : {}),
        });
        const data = res.data as {
          created?: number;
          scanned?: number;
          done?: boolean;
          nextStartAfter?: string | null;
        };
        totalCreated += data.created ?? 0;
        if (data.done || !data.nextStartAfter) {
          break;
        }
        startAfter = data.nextStartAfter;
      }
      setBackfillSummary(
        totalCreated > 0
          ? `Created ${totalCreated} new claim document(s) from provider identity tags (${batches} batch(es)).`
          : `No missing claims found in ${batches} provider batch(es). If you still see nothing, confirm Functions are deployed and you are on the correct Firebase project.`,
      );
      await fetchClaims();
      if (batches >= 80) {
        setError("Backfill reached 80 batches; run sync again if the project has more providers.");
      }
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Backfill failed");
    } finally {
      setBackfillBusy(false);
    }
  }

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

  async function updateProviderTagForClaim(
    row: Row,
    mode: "verify" | "edit" | "delete",
  ) {
    const pRef = doc(firestore, "providers", row.providerId);
    const pSnap = await getDoc(pRef);
    if (!pSnap.exists()) {
      throw new Error(`providers/${row.providerId} does not exist`);
    }
    const pdata = pSnap.data() as Record<string, unknown>;
    const tags = readProviderTagArray(pdata.identityTags);
    const idx = tags.findIndex((t) => t.id === row.tagId);
    const current = idx >= 0 ? tags[idx] : null;

    if (mode === "delete") {
      if (idx >= 0) tags.splice(idx, 1);
    } else if (mode === "verify") {
      const next: ProviderIdentityTag = {
        id: row.tagId,
        name: current?.name || row.tagId,
        category: current?.category || "identity",
        source: current?.source || "user_claim",
        verificationStatus: "verified",
        verifiedAt: Timestamp.now(),
        verifiedBy: "admin_dashboard",
      };
      if (idx >= 0) tags[idx] = {...current!, ...next};
      else tags.push(next);
    } else {
      const name = editName.trim();
      const category = editCategory.trim();
      const source = editSource.trim();
      if (!name || !category || !source) {
        throw new Error("Name, category, and source are required");
      }
      const base: ProviderIdentityTag = current || {
        id: row.tagId,
        name,
        category,
        source,
        verificationStatus: "pending",
        verifiedAt: null,
        verifiedBy: null,
      };
      const next: ProviderIdentityTag = {
        ...base,
        name,
        category,
        source,
      };
      if (idx >= 0) tags[idx] = next;
      else tags.push(next);
    }

    await setDoc(
      pRef,
      {
        identityTags: tags.map((t) => ({
          id: t.id,
          name: t.name,
          category: t.category,
          source: t.source,
          verificationStatus: t.verificationStatus,
          ...(t.verifiedAt ? {verifiedAt: t.verifiedAt} : {}),
          ...(t.verifiedBy ? {verifiedBy: t.verifiedBy} : {}),
        })),
        updatedAt: serverTimestamp(),
      },
      {merge: true},
    );
  }

  async function verifyClaimAndTag(row: Row) {
    setBusyId(row.id);
    setError("");
    try {
      await updateProviderTagForClaim(row, "verify");
      await setClaimStatus(row.id, "verified");
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Verify failed");
    } finally {
      setBusyId(null);
    }
  }

  async function rejectClaim(row: Row) {
    setBusyId(row.id);
    setError("");
    try {
      await setClaimStatus(row.id, "rejected");
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Reject failed");
    } finally {
      setBusyId(null);
    }
  }

  function startEdit(row: Row) {
    setEditingId(row.id);
    setEditName((row.tagName ?? row.tagId).trim());
    setEditCategory(row.category || "identity");
    const st = row.sourceType ?? "";
    setEditSource(
      st === "review" || st === "review_backfill" ? "review" : "user_claim",
    );
  }

  async function saveTagEdits(row: Row) {
    setBusyId(row.id);
    setError("");
    try {
      await updateProviderTagForClaim(row, "edit");
      setEditingId(null);
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Tag update failed");
    } finally {
      setBusyId(null);
    }
  }

  async function deleteTag(row: Row) {
    if (!window.confirm(`Delete tag ${row.tagId} from providers/${row.providerId}?`)) return;
    setBusyId(row.id);
    setError("");
    try {
      await updateProviderTagForClaim(row, "delete");
      await setClaimStatus(row.id, "rejected");
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Delete tag failed");
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
      <p className="text-sm mb-4" style={{ color: "var(--warm-500)" }}>
        Claims from review flow in <code className="text-xs">provider_identity_claims</code>. Verify will also upsert
        the corresponding tag into <code className="text-xs">providers.identityTags</code> so the frontend can render
        the verified checkmark. You can also edit or delete tags on the provider document from here.
      </p>
      <p className="text-sm mb-4" style={{ color: "var(--warm-500)" }}>
        Older reviews only updated <code className="text-xs">providers.identityTags</code> and left this queue empty.
        Use <strong>Sync missing claims</strong> once (or after bulk imports) to create claim rows for pending review
        tags that do not already have a claim.
      </p>
      <div className="mb-6 flex flex-wrap items-center gap-3">
        <button
          type="button"
          disabled={backfillBusy || loading}
          onClick={() => void runBackfillMissingClaims()}
          className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl text-sm text-white disabled:opacity-50"
          style={{ backgroundColor: "var(--lavender-600)" }}
        >
          {backfillBusy ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
          Sync missing claims from providers
        </button>
      </div>
      {backfillSummary ? (
        <div className="mb-4 p-4 rounded-xl text-sm bg-emerald-50 text-emerald-900">{backfillSummary}</div>
      ) : null}
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
            const isEditing = editingId === r.id;
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
                    {r.tagName ? (
                      <div className="mt-1">
                        <span className="font-medium">Display name: </span>
                        {r.tagName}
                      </div>
                    ) : null}
                    {r.category ? (
                      <div className="mt-1">
                        <span className="font-medium">Category: </span>
                        <code>{r.category}</code>
                      </div>
                    ) : null}
                    {r.sourceReviewId ? (
                      <div className="mt-1 text-xs">
                        <span className="font-medium">Review: </span>
                        <code className="break-all">{r.sourceReviewId}</code>
                      </div>
                    ) : null}
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
                    {isEditing ? (
                      <div className="mt-3 p-3 rounded-xl border text-xs space-y-2" style={{ borderColor: "var(--lavender-200)" }}>
                        <label className="block">
                          <span className="font-medium">Tag name</span>
                          <input
                            className="mt-1 w-full px-2 py-1 rounded border"
                            style={{ borderColor: "var(--lavender-200)" }}
                            value={editName}
                            onChange={(e) => setEditName(e.target.value)}
                          />
                        </label>
                        <label className="block">
                          <span className="font-medium">Category</span>
                          <input
                            className="mt-1 w-full px-2 py-1 rounded border"
                            style={{ borderColor: "var(--lavender-200)" }}
                            value={editCategory}
                            onChange={(e) => setEditCategory(e.target.value)}
                          />
                        </label>
                        <label className="block">
                          <span className="font-medium">Source</span>
                          <input
                            className="mt-1 w-full px-2 py-1 rounded border"
                            style={{ borderColor: "var(--lavender-200)" }}
                            value={editSource}
                            onChange={(e) => setEditSource(e.target.value)}
                          />
                        </label>
                        <div className="flex gap-2">
                          <button
                            type="button"
                            disabled={busy}
                            onClick={() => saveTagEdits(r)}
                            className="px-2 py-1 rounded-lg text-white disabled:opacity-50"
                            style={{ backgroundColor: "var(--lavender-600)" }}
                          >
                            Save tag
                          </button>
                          <button
                            type="button"
                            disabled={busy}
                            onClick={() => setEditingId(null)}
                            className="px-2 py-1 rounded-lg border"
                            style={{ borderColor: "var(--lavender-200)" }}
                          >
                            Cancel
                          </button>
                        </div>
                      </div>
                    ) : null}
                  </div>
                  <div className="flex flex-col gap-2 shrink-0">
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => verifyClaimAndTag(r)}
                      className="inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl text-sm text-white disabled:opacity-50"
                      style={{ backgroundColor: "var(--lavender-600)" }}
                    >
                      {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
                      Verify
                    </button>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => rejectClaim(r)}
                      className="inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl text-sm border disabled:opacity-50"
                      style={{ borderColor: "var(--lavender-200)" }}
                    >
                      <X className="h-4 w-4" />
                      Reject
                    </button>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => (isEditing ? setEditingId(null) : startEdit(r))}
                      className="inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl text-sm border disabled:opacity-50"
                      style={{ borderColor: "var(--lavender-200)" }}
                    >
                      <Pencil className="h-4 w-4" />
                      {isEditing ? "Close edit" : "Edit tag"}
                    </button>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => deleteTag(r)}
                      className="inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl text-sm border disabled:opacity-50"
                      style={{ borderColor: "#fecaca", color: "#b91c1c", backgroundColor: "#fef2f2" }}
                    >
                      <Trash2 className="h-4 w-4" />
                      Delete tag
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
