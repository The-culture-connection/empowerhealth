import { useCallback, useEffect, useState } from "react";
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
import { httpsCallable } from "firebase/functions";
import { Link } from "react-router";
import { firestore, functions } from "../../firebase/firebase";
import { Loader2 } from "lucide-react";

const REASON_LABELS: Record<string, string> = {
  inaccurate_info: "Information looks wrong",
  harmful_or_unsafe: "Harmful or unsafe",
  wrong_identity_tags: "Identity / cultural tags",
  spam_or_duplicate: "Spam or duplicate",
  other: "Other",
};

const STATUS_OPTIONS = [
  "open",
  "acknowledged",
  "resolved",
  "removed",
  "listing_removed",
] as const;

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

const removeListingCallable = httpsCallable(functions, "adminRemoveProviderListing");

export function ProviderReportsAdmin() {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);
  const [removeBusyId, setRemoveBusyId] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editReason, setEditReason] = useState("");
  const [editDetails, setEditDetails] = useState("");
  const [editStatus, setEditStatus] = useState("");

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
            reasonCategoryLabel:
              x.reasonCategoryLabel != null ? String(x.reasonCategoryLabel) : undefined,
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

  const beginEdit = useCallback((r: Row) => {
    setEditingId(r.id);
    setEditReason(r.reasonCategory || "inaccurate_info");
    setEditDetails(r.details ?? "");
    setEditStatus(r.status ?? "open");
  }, []);

  const cancelEdit = useCallback(() => {
    setEditingId(null);
  }, []);

  async function saveEdit(reportId: string) {
    setBusyId(reportId);
    setError("");
    try {
      const label = REASON_LABELS[editReason] ?? editReason;
      await updateDoc(doc(firestore, "provider_reports", reportId), {
        reasonCategory: editReason,
        reasonCategoryLabel: label,
        details: editDetails.trim() || null,
        status: editStatus,
        updatedAt: serverTimestamp(),
      });
      setEditingId(null);
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Update failed");
    } finally {
      setBusyId(null);
    }
  }

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

  async function removeProviderListing(r: Row) {
    if (
      !window.confirm(
        `Remove this listing from the directory and search?\n\n` +
          `This deletes providers/${r.providerId} (if it exists), blocks future search hits, deletes files under providers/${r.providerId}/ in Storage, and marks every provider_reports row for this provider id as listing_removed.`,
      )
    ) {
      return;
    }
    setRemoveBusyId(r.id);
    setError("");
    try {
      await removeListingCallable({
        providerId: r.providerId,
      });
    } catch (e) {
      console.error(e);
      const msg =
        e && typeof e === "object" && "message" in e
          ? String((e as { message: string }).message)
          : "Remove listing failed";
      setError(msg);
    } finally {
      setRemoveBusyId(null);
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
        Submitted from the app via <code className="text-xs">provider_reports</code>. Open the provider name for full
        directory metadata and reviews. Use <strong>Edit report</strong> to change category, details, or status. Use{" "}
        <strong>Remove listing</strong> after triage to delete the Firestore directory row, suppress the listing in{" "}
        <code className="text-xs">searchProviders</code>, clear Storage under <code className="text-xs">providers/…</code>
        , and mark <strong>all</strong> reports for that provider id <code className="text-xs">listing_removed</code>.
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
            const removeBusy = removeBusyId === r.id;
            const when = r.createdAt?.toDate?.()?.toLocaleString?.() ?? "—";
            const reasonLine =
              r.reasonCategoryLabel ??
              REASON_LABELS[r.reasonCategory] ??
              r.reasonCategory;
            const detailHref = `/moderation/reports/provider/${encodeURIComponent(r.providerId)}`;
            const listingRemoved = r.status === "listing_removed";
            const isEditing = editingId === r.id;
            return (
              <li
                key={r.id}
                className="rounded-2xl border p-5"
                style={{ backgroundColor: "white", borderColor: "var(--lavender-200)" }}
              >
                <div className="flex flex-wrap justify-between gap-4">
                  <div className="min-w-0 flex-1">
                    <Link
                      to={detailHref}
                      className="font-medium text-left hover:underline block"
                      style={{ color: "var(--lavender-700)" }}
                    >
                      {r.providerName ?? r.providerId}
                    </Link>
                    <div className="text-sm mt-1" style={{ color: "var(--warm-500)" }}>
                      {reasonLine} · {when}
                    </div>
                    <div className="text-xs mt-2 opacity-70">
                      Report id: <code>{r.id}</code> · Provider id: <code>{r.providerId}</code> · User:{" "}
                      <code>{r.userId}</code>
                    </div>
                    {!isEditing && r.details ? (
                      <p className="text-sm mt-3" style={{ color: "var(--warm-600)" }}>
                        {r.details}
                      </p>
                    ) : null}
                    <div className="text-xs mt-2">
                      Status: <strong>{r.status ?? "open"}</strong>
                    </div>

                    {isEditing ? (
                      <div
                        className="mt-4 space-y-3 rounded-xl border p-4 text-sm"
                        style={{ borderColor: "var(--lavender-200)" }}
                      >
                        <label className="block">
                          <span className="text-xs font-medium opacity-80">Reason category</span>
                          <select
                            className="mt-1 w-full px-3 py-2 rounded-lg border text-sm"
                            style={{ borderColor: "var(--lavender-200)" }}
                            value={editReason}
                            onChange={(e) => setEditReason(e.target.value)}
                          >
                            {Object.entries(REASON_LABELS).map(([k, lab]) => (
                              <option key={k} value={k}>
                                {lab}
                              </option>
                            ))}
                          </select>
                        </label>
                        <label className="block">
                          <span className="text-xs font-medium opacity-80">Details</span>
                          <textarea
                            className="mt-1 w-full px-3 py-2 rounded-lg border text-sm min-h-[88px]"
                            style={{ borderColor: "var(--lavender-200)" }}
                            value={editDetails}
                            onChange={(e) => setEditDetails(e.target.value)}
                          />
                        </label>
                        <label className="block">
                          <span className="text-xs font-medium opacity-80">Status</span>
                          <select
                            className="mt-1 w-full px-3 py-2 rounded-lg border text-sm"
                            style={{ borderColor: "var(--lavender-200)" }}
                            value={editStatus}
                            onChange={(e) => setEditStatus(e.target.value)}
                          >
                            {STATUS_OPTIONS.map((s) => (
                              <option key={s} value={s}>
                                {s}
                              </option>
                            ))}
                          </select>
                        </label>
                        <div className="flex flex-wrap gap-2">
                          <button
                            type="button"
                            disabled={busy}
                            onClick={() => void saveEdit(r.id)}
                            className="px-3 py-2 rounded-xl text-sm text-white disabled:opacity-50"
                            style={{ backgroundColor: "var(--lavender-600)" }}
                          >
                            {busy ? <Loader2 className="h-4 w-4 animate-spin inline" /> : null}
                            Save changes
                          </button>
                          <button
                            type="button"
                            disabled={busy}
                            onClick={cancelEdit}
                            className="px-3 py-2 rounded-xl text-sm border"
                            style={{ borderColor: "var(--lavender-200)" }}
                          >
                            Cancel
                          </button>
                        </div>
                      </div>
                    ) : null}
                  </div>
                  <div className="flex flex-col gap-2 shrink-0">
                    <Link
                      to={detailHref}
                      className="px-3 py-2 rounded-xl text-sm text-center border"
                      style={{ borderColor: "var(--lavender-300)", color: "var(--lavender-700)" }}
                    >
                      Provider detail
                    </Link>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => (isEditing ? cancelEdit() : beginEdit(r))}
                      className="px-3 py-2 rounded-xl text-sm border disabled:opacity-50"
                      style={{ borderColor: "var(--lavender-300)", color: "var(--lavender-700)" }}
                    >
                      {isEditing ? "Close editor" : "Edit report"}
                    </button>
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
                    <button
                      type="button"
                      disabled={busy || r.status === "removed"}
                      onClick={() => setStatus(r.id, "removed")}
                      className="px-3 py-2 rounded-xl text-sm border disabled:opacity-50"
                      style={{ borderColor: "var(--lavender-200)" }}
                    >
                      Dismiss (report only)
                    </button>
                    <button
                      type="button"
                      disabled={
                        removeBusy || !r.providerId || listingRemoved
                      }
                      onClick={() => void removeProviderListing(r)}
                      className="px-3 py-2 rounded-xl text-sm border disabled:opacity-50"
                      style={{
                        borderColor: "#fecaca",
                        color: "#b91c1c",
                        backgroundColor: "#fef2f2",
                      }}
                    >
                      {removeBusy ? <Loader2 className="h-4 w-4 animate-spin inline" /> : null}
                      Remove listing
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
