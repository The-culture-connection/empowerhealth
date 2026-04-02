import { collection, getDocs, query, Timestamp, where, type Firestore } from "firebase/firestore";
import type { NormalizedCareSurvey } from "../reports/types";

const ACCESS_SCORE: Record<string, number> = {
  yes: 5,
  partly: 3,
  no: 1,
  "didnt-try": 2,
  "didnt-know": 2,
  "couldnt-access": 1,
};

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

function compositeFromAccess(accessResponses: Record<string, string>): number | null {
  const vals = Object.values(accessResponses)
    .map((v) => (typeof v === "string" ? ACCESS_SCORE[v] : undefined))
    .filter((n): n is number => typeof n === "number");
  if (vals.length === 0) return null;
  return vals.reduce((a, b) => a + b, 0) / vals.length;
}

export function normalizeCareSurvey(docId: string, data: Record<string, unknown>): NormalizedCareSurvey {
  const selectedNeeds = Array.isArray(data.selectedNeeds)
    ? (data.selectedNeeds as unknown[]).filter((x): x is string => typeof x === "string")
    : [];
  const accessResponses: Record<string, string> =
    data.accessResponses && typeof data.accessResponses === "object"
      ? Object.fromEntries(
          Object.entries(data.accessResponses as Record<string, unknown>).filter(
            ([, v]) => typeof v === "string",
          ) as [string, string][],
        )
      : {};
  const userId = typeof data.userId === "string" ? data.userId : null;
  const timestamp =
    tsToDate(data.completedAt) ?? tsToDate(data.createdAt) ?? tsToDate(data.timestamp) ?? null;

  const confidenceComposite =
    typeof data.confidenceScore === "number" && !Number.isNaN(data.confidenceScore)
      ? data.confidenceScore
      : typeof data.navigationConfidence === "number"
        ? data.navigationConfidence
        : compositeFromAccess(accessResponses);

  return {
    id: docId,
    userId,
    selectedNeeds,
    accessResponses,
    rawOutcomes: { ...accessResponses },
    confidenceComposite,
    timestamp,
  };
}

export async function listCareSurveyByDateRange(
  db: Firestore,
  start: Date,
  end: Date,
): Promise<NormalizedCareSurvey[]> {
  const endDay = new Date(end);
  endDay.setHours(23, 59, 59, 999);
  const startTs = Timestamp.fromDate(start);
  const endTs = Timestamp.fromDate(endDay);

  const q = query(collection(db, "CareSurvey"), where("createdAt", ">=", startTs), where("createdAt", "<=", endTs));
  const snap = await getDocs(q);
  return snap.docs.map((d) => normalizeCareSurvey(d.id, d.data() as Record<string, unknown>));
}

export function careNeedCategoryLabel(needId: string): string {
  const map: Record<string, string> = {
    "prenatal-postpartum": "Prenatal/postpartum care",
    "labor-delivery": "Labor prep",
    "blood-pressure": "Medical follow-up",
    "mental-health": "Mental health",
    lactation: "Lactation",
    "infant-pediatric": "Pediatric care",
    benefits: "Benefits/resources",
    transportation: "Transportation/logistics",
    other: "Other",
  };
  return map[needId] ?? needId;
}
