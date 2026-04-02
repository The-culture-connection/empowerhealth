import { collection, getDocs, query, Timestamp, where, type Firestore } from "firebase/firestore";
import type { NormalizedModuleFeedback } from "../reports/types";

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

function num(v: unknown): number | null {
  if (typeof v === "number" && !Number.isNaN(v)) return v;
  return null;
}

export function normalizeModuleFeedback(docId: string, data: Record<string, unknown>): NormalizedModuleFeedback {
  const understanding =
    num(data.understandingRating) ?? num(data.understandingScore) ?? num(data.rating) ?? null;
  const helpfulness =
    num(data.nextStepsRating) ?? num(data.helpfulness) ?? num(data.helpfulnessScore) ?? null;
  const confidence = num(data.confidenceRating) ?? num(data.confidenceScore) ?? null;
  const moduleId =
    (typeof data.taskId === "string" && data.taskId) ||
    (typeof data.moduleId === "string" && data.moduleId) ||
    null;
  const moduleTitle = typeof data.moduleTitle === "string" ? data.moduleTitle : null;
  const userId = typeof data.userId === "string" ? data.userId : null;
  const freeText =
    (typeof data.comments === "string" && data.comments) ||
    (typeof data.notes === "string" && data.notes) ||
    (typeof data.freeTextFeedback === "string" && data.freeTextFeedback) ||
    null;
  const timestamp =
    tsToDate(data.createdAt) ?? tsToDate(data.updatedAt) ?? tsToDate(data.timestamp) ?? null;

  return {
    id: docId,
    userId,
    moduleId,
    moduleTitle,
    understandingScore: understanding,
    helpfulnessScore: helpfulness,
    confidenceScore: confidence,
    freeTextFeedback: freeText,
    timestamp,
  };
}

export async function listModuleFeedbackByDateRange(
  db: Firestore,
  start: Date,
  end: Date,
): Promise<NormalizedModuleFeedback[]> {
  const endDay = new Date(end);
  endDay.setHours(23, 59, 59, 999);
  const startTs = Timestamp.fromDate(start);
  const endTs = Timestamp.fromDate(endDay);

  const q = query(collection(db, "ModuleFeedback"), where("createdAt", ">=", startTs), where("createdAt", "<=", endTs));
  const snap = await getDocs(q);
  return snap.docs.map((d) => normalizeModuleFeedback(d.id, d.data() as Record<string, unknown>));
}
