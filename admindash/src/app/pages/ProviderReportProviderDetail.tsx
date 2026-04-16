import { useEffect, useState } from "react";
import { Link, useParams } from "react-router";
import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  serverTimestamp,
  setDoc,
  where,
  Timestamp,
} from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { firestore, functions } from "../../firebase/firebase";
import { ArrowLeft, Loader2 } from "lucide-react";

const REASON_LABELS: Record<string, string> = {
  inaccurate_info: "Information looks wrong",
  harmful_or_unsafe: "Harmful or unsafe",
  wrong_identity_tags: "Identity / cultural tags",
  spam_or_duplicate: "Spam or duplicate",
  other: "Other",
};

const removeListingCallable = httpsCallable(functions, "adminRemoveProviderListing");

/** Round-trip Timestamps in JSON editor (Firestore rejects undefined in writes). */
const TS_KEY = "__firestoreTimestamp";

function firestoreDocToJsonText(data: Record<string, unknown>): string {
  const replacer = (_k: string, value: unknown): unknown => {
    if (value instanceof Timestamp) return { [TS_KEY]: value.toMillis() };
    if (
      value &&
      typeof value === "object" &&
      "toMillis" in value &&
      typeof (value as { toMillis: () => number }).toMillis === "function"
    ) {
      try {
        return { [TS_KEY]: (value as { toMillis: () => number }).toMillis() };
      } catch {
        return value;
      }
    }
    return value;
  };
  return JSON.stringify(data, replacer, 2);
}

function parseJsonToProviderPayload(text: string): Record<string, unknown> {
  const raw = JSON.parse(text) as unknown;
  const revive = (v: unknown): unknown => {
    if (v && typeof v === "object" && !Array.isArray(v)) {
      const o = v as Record<string, unknown>;
      if (typeof o[TS_KEY] === "number" && Object.keys(o).length === 1) {
        return Timestamp.fromMillis(o[TS_KEY]);
      }
      const out: Record<string, unknown> = {};
      for (const [k, val] of Object.entries(o)) out[k] = revive(val);
      return out;
    }
    if (Array.isArray(v)) return v.map(revive);
    return v;
  };
  const r = revive(raw);
  if (!r || typeof r !== "object" || Array.isArray(r)) {
    throw new Error("JSON root must be an object");
  }
  return r as Record<string, unknown>;
}

function stripUndefinedDeep(value: unknown): unknown {
  if (value === undefined) return undefined;
  if (value === null || typeof value !== "object") return value;
  if (Array.isArray(value)) {
    return value.map(stripUndefinedDeep).filter((x) => x !== undefined);
  }
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(value)) {
    if (v === undefined) continue;
    const s = stripUndefinedDeep(v);
    if (s !== undefined) out[k] = s as unknown;
  }
  return out;
}

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
    return JSON.stringify(v, null, 2);
  } catch {
    return String(v);
  }
}

function sortedKeys(obj: Record<string, unknown>): string[] {
  return Object.keys(obj).sort((a, b) => a.localeCompare(b));
}

type ReportRow = { id: string; data: Record<string, unknown> };
type ReviewRow = { id: string; data: Record<string, unknown> };

export function ProviderReportProviderDetail() {
  const { providerId: rawParam } = useParams<{ providerId: string }>();
  const providerId = rawParam ? decodeURIComponent(rawParam) : "";

  const [providerData, setProviderData] = useState<Record<string, unknown> | null>(null);
  const [providerMissing, setProviderMissing] = useState(false);
  const [reports, setReports] = useState<ReportRow[]>([]);
  const [reviews, setReviews] = useState<ReviewRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [removeListingBusy, setRemoveListingBusy] = useState(false);

  const [providerJsonOpen, setProviderJsonOpen] = useState(false);
  const [providerJsonDraft, setProviderJsonDraft] = useState("");
  const [providerSaveBusy, setProviderSaveBusy] = useState(false);
  const [providerJsonMessage, setProviderJsonMessage] = useState("");

  useEffect(() => {
    if (!providerId) {
      setLoading(false);
      setError("Missing provider id");
      return;
    }
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError("");
      try {
        const pSnap = await getDoc(doc(firestore, "providers", providerId));
        if (cancelled) return;
        if (pSnap.exists()) {
          setProviderData(pSnap.data() as Record<string, unknown>);
          setProviderMissing(false);
        } else {
          setProviderData(null);
          setProviderMissing(true);
        }

        const rq = query(
          collection(firestore, "provider_reports"),
          where("providerId", "==", providerId),
        );
        const rSnap = await getDocs(rq);
        if (cancelled) return;
        const rRows: ReportRow[] = [];
        rSnap.forEach((d) => rRows.push({ id: d.id, data: d.data() as Record<string, unknown> }));
        rRows.sort((a, b) => {
          const ta = (a.data.createdAt as Timestamp | undefined)?.toMillis?.() ?? 0;
          const tb = (b.data.createdAt as Timestamp | undefined)?.toMillis?.() ?? 0;
          return tb - ta;
        });
        setReports(rRows);

        const vq = query(
          collection(firestore, "reviews"),
          where("providerId", "==", providerId),
          limit(200),
        );
        const vSnap = await getDocs(vq);
        if (cancelled) return;
        const vRows: ReviewRow[] = [];
        vSnap.forEach((d) => vRows.push({ id: d.id, data: d.data() as Record<string, unknown> }));
        vRows.sort((a, b) => {
          const ta = (a.data.createdAt as Timestamp | undefined)?.toMillis?.() ?? 0;
          const tb = (b.data.createdAt as Timestamp | undefined)?.toMillis?.() ?? 0;
          return tb - ta;
        });
        setReviews(vRows);
      } catch (e) {
        if (!cancelled) {
          console.error(e);
          setError(e instanceof Error ? e.message : "Failed to load");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [providerId]);

  useEffect(() => {
    if (!providerJsonOpen) return;
    if (providerData) {
      try {
        setProviderJsonDraft(firestoreDocToJsonText(providerData));
      } catch {
        setProviderJsonDraft("{}");
      }
    }
  }, [providerJsonOpen, providerData]);

  async function saveProviderDoc() {
    setProviderSaveBusy(true);
    setProviderJsonMessage("");
    try {
      const payload = parseJsonToProviderPayload(providerJsonDraft);
      const cleaned = stripUndefinedDeep(payload) as Record<string, unknown>;
      await setDoc(
        doc(firestore, "providers", providerId),
        { ...cleaned, updatedAt: serverTimestamp() },
        { merge: true },
      );
      const snap = await getDoc(doc(firestore, "providers", providerId));
      if (snap.exists()) setProviderData(snap.data() as Record<string, unknown>);
      setProviderJsonOpen(false);
      setProviderJsonMessage("Listing saved.");
    } catch (e) {
      console.error(e);
      setProviderJsonMessage(e instanceof Error ? e.message : "Save failed");
    } finally {
      setProviderSaveBusy(false);
    }
  }

  async function removeListing() {
    if (
      !window.confirm(
        `Remove directory listing for ${providerId}?\n\n` +
          `Deletes the providers document if present, blocks search, clears Storage under providers/${providerId}/, updates UserProviders, and marks all reports for this id listing_removed.`,
      )
    ) {
      return;
    }
    setRemoveListingBusy(true);
    setError("");
    try {
      await removeListingCallable({ providerId });
    } catch (e) {
      console.error(e);
      setError(e instanceof Error ? e.message : "Remove listing failed");
    } finally {
      setRemoveListingBusy(false);
    }
  }

  const canEditProviderDoc = Boolean(providerData && reports.length > 0);

  if (loading) {
    return (
      <div className="p-8 flex items-center gap-2" style={{ color: "var(--warm-500)" }}>
        <Loader2 className="h-5 w-5 animate-spin" />
        Loading provider…
      </div>
    );
  }

  return (
    <div className="p-8 max-w-5xl">
      <Link
        to="/moderation/reports"
        className="inline-flex items-center gap-2 text-sm mb-6"
        style={{ color: "var(--lavender-600)" }}
      >
        <ArrowLeft className="h-4 w-4" />
        Back to listing reports
      </Link>

      <h1 className="text-2xl font-semibold mb-1" style={{ color: "var(--warm-600)" }}>
        Provider detail
      </h1>
      <p className="text-sm font-mono mb-6 opacity-80 break-all">{providerId}</p>

      {error ? (
        <div className="mb-4 p-4 rounded-xl text-sm bg-red-50 text-red-700">{error}</div>
      ) : null}

      <div className="mb-6 flex flex-wrap gap-2">
        <button
          type="button"
          disabled={removeListingBusy || !providerId}
          onClick={() => void removeListing()}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium border border-red-300 text-red-700 disabled:opacity-50"
          style={{ backgroundColor: "#fef2f2" }}
        >
          {removeListingBusy ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
          Remove listing from directory
        </button>
      </div>

      {providerMissing ? (
        <p className="text-sm mb-6 p-4 rounded-xl bg-amber-50 text-amber-900 border border-amber-200">
          No <code className="text-xs">providers</code> document for this id (it may have been deleted or only exists in
          API results). Reports and reviews below may still reference this id.
        </p>
      ) : null}

      {providerData && reports.length === 0 ? (
        <p className="text-sm mb-6 p-4 rounded-xl border" style={{ borderColor: "var(--lavender-200)" }}>
          There is a <code className="text-xs">providers</code> document but no listing reports for this id yet. Open{" "}
          <strong>Provider directory</strong> to edit arbitrary ids, or edit JSON here after at least one report exists
          for this provider id.
        </p>
      ) : null}

      {canEditProviderDoc ? (
        <section className="mb-10">
          <h2 className="text-lg font-semibold mb-2" style={{ color: "var(--warm-600)" }}>
            Edit directory document
          </h2>
          {providerJsonMessage && !providerJsonOpen ? (
            <p
              className="text-sm mb-3 rounded-lg px-3 py-2"
              style={{
                backgroundColor:
                  providerJsonMessage === "Listing saved." ? "#ecfdf5" : "#fef2f2",
                color: providerJsonMessage === "Listing saved." ? "#065f46" : "#b91c1c",
              }}
            >
              {providerJsonMessage}
            </p>
          ) : null}
          <p className="text-sm mb-3" style={{ color: "var(--warm-500)" }}>
            Shown because this provider id has at least one report. Edit the full{" "}
            <code className="text-xs">providers</code> payload as JSON (timestamps appear as{" "}
            <code className="text-xs">{`{"${TS_KEY}": millis}`}</code>). Save uses{" "}
            <code className="text-xs">setDoc(..., merge: true)</code> and sets <code className="text-xs">updatedAt</code>.
            Invalid JSON or the wrong root type will show an error.
          </p>
          {!providerJsonOpen ? (
            <button
              type="button"
              onClick={() => {
                setProviderJsonMessage("");
                setProviderJsonOpen(true);
              }}
              className="px-4 py-2 rounded-xl text-sm font-medium text-white"
              style={{ backgroundColor: "var(--lavender-600)" }}
            >
              Edit listing JSON
            </button>
          ) : (
            <div className="space-y-3">
              <textarea
                className="w-full min-h-[320px] font-mono text-xs p-3 rounded-xl border"
                style={{ borderColor: "var(--lavender-200)" }}
                value={providerJsonDraft}
                onChange={(e) => setProviderJsonDraft(e.target.value)}
                spellCheck={false}
              />
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  disabled={providerSaveBusy}
                  onClick={() => void saveProviderDoc()}
                  className="px-4 py-2 rounded-xl text-sm font-medium text-white disabled:opacity-50"
                  style={{ backgroundColor: "var(--lavender-600)" }}
                >
                  {providerSaveBusy ? <Loader2 className="h-4 w-4 animate-spin inline" /> : null}
                  Save listing
                </button>
                <button
                  type="button"
                  disabled={providerSaveBusy}
                  onClick={() => {
                    setProviderJsonOpen(false);
                    setProviderJsonMessage("");
                  }}
                  className="px-4 py-2 rounded-xl text-sm border"
                  style={{ borderColor: "var(--lavender-200)" }}
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={providerSaveBusy || !providerData}
                  onClick={() => {
                    setProviderJsonDraft(firestoreDocToJsonText(providerData!));
                    setProviderJsonMessage("Reset draft from last loaded document.");
                  }}
                  className="px-4 py-2 rounded-xl text-sm border"
                  style={{ borderColor: "var(--lavender-200)" }}
                >
                  Reset from server
                </button>
              </div>
              {providerJsonMessage && providerJsonOpen ? (
                <p
                  className={`text-sm ${providerJsonMessage.startsWith("Reset") ? "opacity-80" : "text-red-700"}`}
                  style={
                    providerJsonMessage.startsWith("Reset")
                      ? { color: "var(--warm-600)" }
                      : undefined
                  }
                >
                  {providerJsonMessage}
                </p>
              ) : null}
            </div>
          )}
        </section>
      ) : null}

      {providerData ? (
        <section className="mb-10">
          <h2 className="text-lg font-semibold mb-3" style={{ color: "var(--warm-600)" }}>
            Directory metadata (all fields)
          </h2>
          <dl
            className="rounded-2xl border p-4 text-sm space-y-2"
            style={{ borderColor: "var(--lavender-200)", backgroundColor: "white" }}
          >
            {sortedKeys(providerData).map((k) => (
              <div
                key={k}
                className="grid grid-cols-1 sm:grid-cols-[minmax(0,220px)_1fr] gap-x-4 gap-y-1 border-b border-gray-100 pb-2 last:border-0 last:pb-0"
              >
                <dt className="font-mono text-xs opacity-80 shrink-0">{k}</dt>
                <dd className="break-words" style={{ color: "var(--warm-600)" }}>
                  {typeof providerData[k] === "object" &&
                  providerData[k] !== null &&
                  !(providerData[k] instanceof Timestamp) ? (
                    <pre className="text-xs whitespace-pre-wrap bg-gray-50 p-2 rounded-lg overflow-x-auto max-h-48 overflow-y-auto">
                      {formatValue(providerData[k])}
                    </pre>
                  ) : (
                    formatValue(providerData[k])
                  )}
                </dd>
              </div>
            ))}
          </dl>
        </section>
      ) : null}

      <section className="mb-10">
        <h2 className="text-lg font-semibold mb-3" style={{ color: "var(--warm-600)" }}>
          Listing reports ({reports.length})
        </h2>
        {reports.length === 0 ? (
          <p className="text-sm" style={{ color: "var(--warm-500)" }}>
            No reports for this provider id.
          </p>
        ) : (
          <ul className="space-y-3">
            {reports.map((r) => {
              const st = String(r.data.status ?? "open");
              const cat = String(r.data.reasonCategory ?? "");
              const label =
                (r.data.reasonCategoryLabel as string | undefined) ??
                REASON_LABELS[cat] ??
                cat;
              const when =
                (r.data.createdAt as Timestamp | undefined)?.toDate?.()?.toLocaleString?.() ?? "—";
              return (
                <li
                  key={r.id}
                  className="rounded-xl border p-4 text-sm"
                  style={{ backgroundColor: "white", borderColor: "var(--lavender-200)" }}
                >
                  <div className="font-medium">{label}</div>
                  <div className="text-xs opacity-70 mt-1">
                    {when} · status: {st} · doc: <code className="text-xs">{r.id}</code>
                  </div>
                  {r.data.details != null ? (
                    <p className="mt-2" style={{ color: "var(--warm-600)" }}>
                      {String(r.data.details)}
                    </p>
                  ) : null}
                  <details className="mt-2 text-xs">
                    <summary className="cursor-pointer opacity-70">All report fields</summary>
                    <pre className="mt-2 p-2 bg-gray-50 rounded-lg overflow-x-auto max-h-40 overflow-y-auto">
                      {JSON.stringify(r.data, null, 2)}
                    </pre>
                  </details>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      <section>
        <h2 className="text-lg font-semibold mb-3" style={{ color: "var(--warm-600)" }}>
          Reviews ({reviews.length})
        </h2>
        {reviews.length === 0 ? (
          <p className="text-sm" style={{ color: "var(--warm-500)" }}>
            No reviews for this provider id.
          </p>
        ) : (
          <ul className="space-y-4">
            {reviews.map((r) => {
              const when =
                (r.data.createdAt as Timestamp | undefined)?.toDate?.()?.toLocaleString?.() ?? "—";
              return (
                <li
                  key={r.id}
                  className="rounded-xl border p-4 text-sm"
                  style={{ backgroundColor: "white", borderColor: "var(--lavender-200)" }}
                >
                  <div className="flex flex-wrap justify-between gap-2">
                    <span className="font-medium">
                      {String(r.data.userName ?? "Anonymous")} · {String(r.data.rating ?? "—")}★
                    </span>
                    <span className="text-xs opacity-70">{when}</span>
                  </div>
                  <div className="text-xs mt-1">
                    status: <strong>{String(r.data.status ?? "published")}</strong> · doc:{" "}
                    <code className="text-xs">{r.id}</code>
                  </div>
                  {r.data.reviewText != null ? (
                    <p className="mt-2" style={{ color: "var(--warm-600)" }}>
                      {String(r.data.reviewText)}
                    </p>
                  ) : null}
                  <details className="mt-2 text-xs">
                    <summary className="cursor-pointer opacity-70">All review fields</summary>
                    <pre className="mt-2 p-2 bg-gray-50 rounded-lg overflow-x-auto max-h-56 overflow-y-auto">
                      {JSON.stringify(r.data, null, 2)}
                    </pre>
                  </details>
                </li>
              );
            })}
          </ul>
        )}
      </section>
    </div>
  );
}
