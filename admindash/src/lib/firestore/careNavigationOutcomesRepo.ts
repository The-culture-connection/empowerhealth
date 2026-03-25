import { collection, getDocs, query, Timestamp, where, type Firestore } from "firebase/firestore";
import type { NormalizedCareNavigationOutcome } from "../reports/types";

function tsToDate(v: unknown): Date | null {
  if (v instanceof Timestamp) return v.toDate();
  if (v && typeof v === "object" && "toDate" in (v as object)) {
    try {
      return (v as { toDate: () => Date }).toDate();
    } catch {
      return null;
    }
  }
  return null;
}

export async function listCareNavigationOutcomesByDateRange(
  db: Firestore,
  start: Date,
  end: Date,
): Promise<NormalizedCareNavigationOutcome[]> {
  const endDay = new Date(end);
  endDay.setHours(23, 59, 59, 999);
  const startTs = Timestamp.fromDate(start);
  const endTs = Timestamp.fromDate(endDay);
  try {
    const q = query(
      collection(db, "care_navigation_outcomes"),
      where("timestamp", ">=", startTs),
      where("timestamp", "<=", endTs),
    );
    const snap = await getDocs(q);
    return snap.docs.map((d) => {
      const data = d.data() as Record<string, unknown>;
      return {
        id: d.id,
        userId: typeof data.userId === "string" ? data.userId : null,
        needType: typeof data.needType === "string" ? data.needType : null,
        outcome: typeof data.outcome === "string" ? data.outcome : null,
        timestamp: tsToDate(data.timestamp),
      };
    });
  } catch {
    return [];
  }
}
