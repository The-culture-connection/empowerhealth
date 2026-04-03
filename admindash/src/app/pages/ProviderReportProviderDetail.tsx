import { useEffect, useState } from "react";
import { Link, useParams } from "react-router";
import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  where,
  Timestamp,
} from "firebase/firestore";
import { firestore } from "../../firebase/firebase";
import { ArrowLeft, Loader2 } from "lucide-react";

const REASON_LABELS: Record<string, string> = {
  inaccurate_info: "Information looks wrong",
  harmful_or_unsafe: "Harmful or unsafe",
  wrong_identity_tags: "Identity / cultural tags",
  spam_or_duplicate: "Spam or duplicate",
  other: "Other",
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

      {providerMissing ? (
        <p className="text-sm mb-6 p-4 rounded-xl bg-amber-50 text-amber-900 border border-amber-200">
          No <code className="text-xs">providers</code> document for this id (it may have been deleted or only exists in
          API results). Reports and reviews below may still reference this id.
        </p>
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
                    {when} · status: {st}
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
