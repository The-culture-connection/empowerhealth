import {
  collection,
  getDocs,
  query,
  where,
  Timestamp,
  type Firestore,
} from "firebase/firestore";
import type { NormalizedEvent, ReportDataset } from "../reports/types";
import { listModuleFeedbackByDateRange } from "./moduleFeedbackRepo";
import { listCareSurveyByDateRange } from "./careSurveyRepo";
import { listCareNavigationOutcomesByDateRange } from "./careNavigationOutcomesRepo";

function tsToDate(v: unknown): Date | null {
  if (v instanceof Timestamp) return v.toDate();
  if (v && typeof v === "object" && "toDate" in (v as object)) {
    try {
      return (v as { toDate: () => Date }).toDate();
    } catch {
      return null;
    }
  }
  if (typeof v === "string" || typeof v === "number") {
    const d = new Date(v);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  return null;
}

export function normalizeAnalyticsEvent(docId: string, data: Record<string, unknown>): NormalizedEvent {
  return {
    id: docId,
    eventName: String(data.eventName || ""),
    feature: String(data.feature || ""),
    timestamp: tsToDate(data.timestamp) ?? tsToDate(data.clientTimestamp),
    uid: typeof data.uid === "string" ? data.uid : typeof data.userId === "string" ? data.userId : undefined,
    anonUserId: typeof data.anonUserId === "string" ? data.anonUserId : undefined,
    metadata: (data.metadata && typeof data.metadata === "object" ? data.metadata : {}) as Record<string, unknown>,
    durationMs: typeof data.durationMs === "number" ? data.durationMs : null,
  };
}

export async function listAnalyticsEventsByDateRange(
  db: Firestore,
  start: Date,
  end: Date,
): Promise<NormalizedEvent[]> {
  const endDay = new Date(end);
  endDay.setHours(23, 59, 59, 999);
  const startTs = Timestamp.fromDate(start);
  const endTs = Timestamp.fromDate(endDay);

  const q = query(
    collection(db, "analytics_events"),
    where("timestamp", ">=", startTs),
    where("timestamp", "<=", endTs),
  );
  const snap = await getDocs(q);
  const out = snap.docs.map((d) => normalizeAnalyticsEvent(d.id, d.data() as Record<string, unknown>));
  out.sort((a, b) => (b.timestamp?.getTime() || 0) - (a.timestamp?.getTime() || 0));
  return out;
}

export async function getReportDataset(db: Firestore, start: Date, end: Date): Promise<ReportDataset> {
  const [events, moduleFeedback, careSurveys, careNavigationOutcomes] = await Promise.all([
    listAnalyticsEventsByDateRange(db, start, end),
    listModuleFeedbackByDateRange(db, start, end),
    listCareSurveyByDateRange(db, start, end),
    listCareNavigationOutcomesByDateRange(db, start, end),
  ]);

  return {
    events,
    moduleFeedback,
    careSurveys,
    careNavigationOutcomes,
    coverageFlags: [],
  };
}
