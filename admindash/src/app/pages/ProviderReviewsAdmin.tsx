import { useEffect, useState } from "react";
import {
  collection,
  onSnapshot,
  orderBy,
  query,
  limit,
  Timestamp,
} from "firebase/firestore";
import { firestore } from "../../firebase/firebase";
import { Loader2 } from "lucide-react";

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
  status?: string;
  createdAt?: Timestamp | null;
};

export function ProviderReviewsAdmin() {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

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
            status: x.status != null ? String(x.status) : "published",
            createdAt: x.createdAt as Timestamp | null | undefined,
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
        Recent rows from <code className="text-xs">reviews</code> (newest 150). Use Firestore or future tools to change{" "}
        <code className="text-xs">status</code> (e.g. removed).
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
                  Provider: <code>{r.providerId}</code> · status: {r.status}
                </div>
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
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
