import { useCallback, useEffect, useState, type CSSProperties } from "react";
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
import { Check, Loader2, Trash2 } from "lucide-react";

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
  updatedAt?: Timestamp | null;
  /** Set when an admin completes triage: verified = tag kept & verified; tag_removed = tag deleted from listing */
  moderationAction?: string;
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

function providerListingTitle(data: Record<string, unknown> | undefined): string {
  if (!data) return "";
  const practice = String(data.practiceName ?? "").trim();
  const name = String(data.name ?? "").trim();
  return practice || name || "";
}

type ResolutionTone = "pending" | "verified" | "removed" | "closed";

function resolutionPanel(row: Row): { title: string; subtitle: string; tone: ResolutionTone } {
  const st = (row.status || "").toLowerCase();
  const updatedWhen = row.updatedAt?.toDate?.()?.toLocaleString?.() ?? "";
  const createdWhen = row.createdAt?.toDate?.()?.toLocaleString?.() ?? "";
  if (st === "verified") {
    return {
      title: "Action: Verified",
      subtitle: `Tag was approved and marked verified on the provider listing.${updatedWhen ? ` Completed ${updatedWhen}.` : ""}`,
      tone: "verified",
    };
  }
  if (st === "rejected") {
    const tagRemoved = row.moderationAction === "tag_removed";
    return {
      title: tagRemoved ? "Action: Tag removed" : "Action: Claim closed",
      subtitle: tagRemoved
        ? `Tag was deleted from the provider listing; this queue item is closed.${updatedWhen ? ` Completed ${updatedWhen}.` : ""}`
        : `Claim was rejected (legacy).${updatedWhen ? ` Updated ${updatedWhen}.` : ""}`,
      tone: tagRemoved ? "removed" : "closed",
    };
  }
  return {
    title: "Awaiting review",
    subtitle: createdWhen ? `No decision yet · received ${createdWhen}` : "No decision yet.",
    tone: "pending",
  };
}

function resolutionBannerStyle(tone: ResolutionTone): CSSProperties {
  switch (tone) {
    case "verified":
      return {
        backgroundColor: "#ecfdf5",
        borderColor: "#a7f3d0",
        color: "#065f46",
      };
    case "removed":
      return {
        backgroundColor: "#fef2f2",
        borderColor: "#fecaca",
        color: "#991b1b",
      };
    case "closed":
      return {
        backgroundColor: "#fffbeb",
        borderColor: "#fde68a",
        color: "#92400e",
      };
    default:
      return {
        backgroundColor: "#f8fafc",
        borderColor: "#e2e8f0",
        color: "#334155",
      };
  }
}

export function IdentityClaimsAdmin() {
  const [rows, setRows] = useState<Row[]>([]);
  const [providerNames, setProviderNames] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);
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
          updatedAt: x.updatedAt instanceof Timestamp ? x.updatedAt : null,
          moderationAction:
            x.moderationAction != null ? String(x.moderationAction) : undefined,
        });
      });
      next.sort((a, b) => {
        const ta = a.createdAt?.toMillis() ?? 0;
        const tb = b.createdAt?.toMillis() ?? 0;
        return tb - ta;
      });
      const ids = [...new Set(next.map((r) => r.providerId).filter(Boolean))];
      const names: Record<string, string> = {};
      await Promise.all(
        ids.map(async (pid) => {
          try {
            const pSnap = await getDoc(doc(firestore, "providers", pid));
            if (!pSnap.exists()) {
              names[pid] = "";
              return;
            }
            const title = providerListingTitle(pSnap.data() as Record<string, unknown>);
            names[pid] = title || pid;
          } catch {
            names[pid] = "";
          }
        }),
      );
      setProviderNames(names);
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

  async function setClaimStatus(
    id: string,
    status: string,
    moderationAction: "verified" | "tag_removed",
  ) {
    await updateDoc(doc(firestore, "provider_identity_claims", id), {
      status,
      moderationAction,
      updatedAt: serverTimestamp(),
    });
    const now = Timestamp.now();
    setRows((prev) =>
      prev.map((r) =>
        r.id === id ? { ...r, status, moderationAction, updatedAt: now } : r,
      ),
    );
  }

  function defaultTagSource(row: Row, current: ProviderIdentityTag | null): string {
    if (current?.source) return current.source;
    const st = row.sourceType ?? "";
    if (st === "review" || st === "review_backfill") return "review";
    return "user_claim";
  }

  async function updateProviderTagForClaim(row: Row, mode: "verify" | "delete") {
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
    } else {
      const next: ProviderIdentityTag = {
        id: row.tagId,
        name: current?.name || row.tagName || row.tagId,
        category: current?.category || row.category || "identity",
        source: defaultTagSource(row, current),
        verificationStatus: "verified",
        verifiedAt: Timestamp.now(),
        verifiedBy: "admin_dashboard",
      };
      if (idx >= 0) tags[idx] = {...current!, ...next};
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
    if ((row.status || "").toLowerCase() !== "pending") return;
    setBusyId(row.id);
    setError("");
    try {
      await updateProviderTagForClaim(row, "verify");
      await setClaimStatus(row.id, "verified", "verified");
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Verify failed");
    } finally {
      setBusyId(null);
    }
  }

  async function deleteTag(row: Row) {
    if ((row.status || "").toLowerCase() !== "pending") return;
    const listingName = providerNames[row.providerId] || row.providerId;
    if (
      !window.confirm(
        `Remove tag "${row.tagName ?? row.tagId}" from listing "${listingName}"? This only deletes the tag from the provider document; the claim will be marked closed.`,
      )
    ) {
      return;
    }
    setBusyId(row.id);
    setError("");
    try {
      await updateProviderTagForClaim(row, "delete");
      await setClaimStatus(row.id, "rejected", "tag_removed");
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
        Claims from review flow in <code className="text-xs">provider_identity_claims</code>.{" "}
        <strong>Verify</strong> marks the tag verified on <code className="text-xs">providers.identityTags</code> so
        the app can show the verified state. <strong>Delete tag</strong> removes that tag from the listing only and
        closes the claim.
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
            const panel = resolutionPanel(r);
            const banner = resolutionBannerStyle(panel.tone);
            const listingTitle = providerNames[r.providerId]?.trim();
            const isPending = (r.status || "").toLowerCase() === "pending";
            return (
              <li
                key={r.id}
                className="rounded-2xl border p-5"
                style={{ backgroundColor: "white", borderColor: "var(--lavender-200)" }}
              >
                <div
                  className="mb-4 rounded-xl border px-4 py-3 text-sm"
                  style={banner}
                >
                  <div className="font-semibold">{panel.title}</div>
                  <div className="mt-1 text-xs opacity-90 leading-snug">{panel.subtitle}</div>
                </div>
                <div className="flex flex-wrap justify-between gap-4">
                  <div className="min-w-0 text-sm">
                    <div className="text-base font-semibold" style={{ color: "var(--warm-600)" }}>
                      {listingTitle || "Provider listing"}
                    </div>
                    <div className="mt-0.5 text-xs opacity-70 break-all">
                      <span className="font-medium">Firestore id: </span>
                      <code>{r.providerId}</code>
                    </div>
                    <div className="mt-3">
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
                    {r.sourceType ? (
                      <div className="mt-1 text-xs">
                        Source: <code>{r.sourceType}</code>
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
                    <div className="text-xs opacity-60 mt-2">Claim doc: {r.id}</div>
                  </div>
                  {isPending ? (
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
                        onClick={() => deleteTag(r)}
                        className="inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl text-sm border disabled:opacity-50"
                        style={{ borderColor: "#fecaca", color: "#b91c1c", backgroundColor: "#fef2f2" }}
                      >
                        <Trash2 className="h-4 w-4" />
                        Delete tag
                      </button>
                    </div>
                  ) : null}
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
