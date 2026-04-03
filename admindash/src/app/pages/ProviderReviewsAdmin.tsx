import { useEffect, useState } from "react";
import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  limit,
  Timestamp,
  updateDoc,
  serverTimestamp,
} from "firebase/firestore";
import { auth, firestore } from "../../firebase/firebase";
import { CheckCircle, Loader2, XCircle } from "lucide-react";

function safeJson(obj: Record<string, unknown>): string {
  return JSON.stringify(
    obj,
    (_, v) => {
      if (v && typeof v === "object" && v !== null && "toDate" in v) {
        try {
          return (v as { toDate: () => Date }).toDate().toISOString();
        } catch {
          return String(v);
        }
      }
      return v;
    },
    2,
  );
}

function strList(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v.map((x) => String(x)).filter(Boolean);
}

type Row = {
  id: string;
  providerId: string;
  userId: string;
  userName?: string;
  rating: number;
  reviewText?: string;
  wouldRecommend?: boolean;
  feltHeard?: boolean;
  feltRespected?: boolean;
  explainedClearly?: boolean;
  whatWentWell?: string;
  reviewerRaceEthnicity: string[];
  reviewerLanguages: string[];
  reviewerCulturalTags: string[];
  status?: string;
  createdAt?: Timestamp | null;
  raw: Record<string, unknown>;
};

export function ProviderReviewsAdmin() {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(firestore, "reviews"),
      orderBy("createdAt", "desc"),
      limit(150),
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
            userId: String(x.userId ?? ""),
            userName: x.userName != null ? String(x.userName) : undefined,
            rating: typeof x.rating === "number" ? x.rating : 0,
            reviewText: x.reviewText != null ? String(x.reviewText) : undefined,
            wouldRecommend: x.wouldRecommend === true,
            feltHeard: x.feltHeard === true,
            feltRespected: x.feltRespected === true,
            explainedClearly: x.explainedClearly === true,
            whatWentWell: x.whatWentWell != null ? String(x.whatWentWell) : undefined,
            reviewerRaceEthnicity: strList(x.reviewerRaceEthnicity),
            reviewerLanguages: strList(x.reviewerLanguages),
            reviewerCulturalTags: strList(x.reviewerCulturalTags),
            status: x.status != null ? String(x.status) : "published",
            createdAt: x.createdAt as Timestamp | null | undefined,
            raw: { ...x },
          });
        });
        setRows(next);
        setLoading(false);
        setError("");
      },
      (err) => {
        console.error(err);
        setError(err.message || "Failed to load reviews");
        setLoading(false);
      },
    );
    return () => unsub();
  }, []);

  async function setReviewStatus(id: string, status: "resolved" | "removed") {
    setBusyId(id);
    setError("");
    const uid = auth.currentUser?.uid ?? null;
    try {
      await updateDoc(doc(firestore, "reviews", id), {
        status,
        updatedAt: serverTimestamp(),
        ...(status === "resolved"
          ? { moderationResolvedAt: serverTimestamp() }
          : { moderationRemovedAt: serverTimestamp() }),
        ...(uid ? { moderatedBy: uid } : {}),
      });
      setRows((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)));
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
        Loading reviews…
      </div>
    );
  }

  return (
    <div className="p-8 max-w-5xl">
      <h1 className="text-2xl font-semibold mb-2" style={{ color: "var(--warm-600)" }}>
        Provider reviews
      </h1>
      <p className="text-sm mb-6" style={{ color: "var(--warm-500)" }}>
        Recent rows from <code className="text-xs">reviews</code> (newest 150). Each card lists experience flags and
        self-reported race/ethnicity, language, and cultural tags when present; expand <strong>All stored fields</strong>{" "}
        for the full Firestore document. Only <code className="text-xs">published</code> appears in the app.{" "}
        <strong>Resolve</strong> / <strong>Remove</strong> change <code className="text-xs">status</code>.
      </p>
      {error ? (
        <div className="mb-4 p-4 rounded-xl text-sm bg-red-50 text-red-700">{error}</div>
      ) : null}
      {rows.length === 0 ? (
        <p style={{ color: "var(--warm-500)" }}>No reviews.</p>
      ) : (
        <ul className="space-y-3 max-h-[70vh] overflow-y-auto pr-2">
          {rows.map((r) => {
            const when = r.createdAt?.toDate?.()?.toLocaleString?.() ?? "—";
            const exp = [
              r.feltHeard ? "Heard" : null,
              r.feltRespected ? "Respected" : null,
              r.explainedClearly ? "Explained" : null,
            ]
              .filter(Boolean)
              .join(" · ");
            const busy = busyId === r.id;
            const st = r.status ?? "published";
            const canModerate = st === "published";
            return (
              <li
                key={r.id}
                className="rounded-xl border p-4 text-sm"
                style={{ backgroundColor: "white", borderColor: "var(--lavender-200)" }}
              >
                <div className="flex flex-wrap justify-between gap-2">
                  <span className="font-medium" style={{ color: "var(--warm-600)" }}>
                    {r.userName ?? "Anonymous"} · {r.rating}★
                  </span>
                  <span className="text-xs opacity-70">{when}</span>
                </div>
                <div className="text-xs mt-1 opacity-80">
                  Provider: <code className="break-all">{r.providerId}</code> · doc:{" "}
                  <code className="text-xs">{r.id}</code> · status: <strong>{st}</strong>
                </div>
                {r.reviewerRaceEthnicity.length +
                  r.reviewerLanguages.length +
                  r.reviewerCulturalTags.length >
                0 ? (
                  <div className="text-xs mt-2 space-y-1" style={{ color: "var(--warm-600)" }}>
                    {r.reviewerRaceEthnicity.length > 0 ? (
                      <div>
                        <span className="font-medium">Race/ethnicity: </span>
                        {r.reviewerRaceEthnicity.join(", ")}
                      </div>
                    ) : null}
                    {r.reviewerLanguages.length > 0 ? (
                      <div>
                        <span className="font-medium">Language: </span>
                        {r.reviewerLanguages.join(", ")}
                      </div>
                    ) : null}
                    {r.reviewerCulturalTags.length > 0 ? (
                      <div>
                        <span className="font-medium">Cultural tags: </span>
                        {r.reviewerCulturalTags.join(", ")}
                      </div>
                    ) : null}
                  </div>
                ) : null}
                {r.wouldRecommend ? (
                  <div className="text-xs text-green-700 mt-1">Would recommend</div>
                ) : null}
                {exp ? <div className="text-xs mt-1" style={{ color: "var(--warm-600)" }}>{exp}</div> : null}
                {r.whatWentWell ? (
                  <div className="mt-2 text-xs" style={{ color: "var(--warm-500)" }}>
                    <span className="font-medium">Did well: </span>
                    {r.whatWentWell}
                  </div>
                ) : null}
                {r.reviewText ? (
                  <p className="mt-2" style={{ color: "var(--warm-600)" }}>
                    {r.reviewText}
                  </p>
                ) : null}
                <details className="mt-3 text-xs">
                  <summary className="cursor-pointer opacity-70 font-medium">All stored fields (metadata)</summary>
                  <pre
                    className="mt-2 p-3 rounded-lg overflow-x-auto max-h-64 overflow-y-auto text-[11px] leading-relaxed"
                    style={{ backgroundColor: "#f8f5fc", color: "var(--warm-600)" }}
                  >
                    {safeJson(r.raw)}
                  </pre>
                </details>
                {canModerate ? (
                  <div className="flex flex-wrap gap-2 mt-3">
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => void setReviewStatus(r.id, "resolved")}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium text-white disabled:opacity-50"
                      style={{ backgroundColor: "var(--lavender-600)" }}
                    >
                      {busy ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <CheckCircle className="h-3.5 w-3.5" />}
                      Resolve
                    </button>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => void setReviewStatus(r.id, "removed")}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium border border-red-200 text-red-700 disabled:opacity-50"
                      style={{ backgroundColor: "#fef2f2" }}
                    >
                      {busy ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <XCircle className="h-3.5 w-3.5" />}
                      Remove
                    </button>
                  </div>
                ) : null}
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
