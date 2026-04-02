import type { EventEvidenceRow, EventImplementationStatus, NormalizedEvent } from "./types";
import { dictionaryRowsForEvents, dictionaryRowsForSources } from "./eventDictionary";
import * as M from "./reportMetrics";

export function filterEvents(events: NormalizedEvent[], whitelist: Set<string>): NormalizedEvent[] {
  return events.filter((e) => whitelist.has(e.eventName));
}

export function buildEventRows(
  eventNames: readonly string[],
  extraSources: readonly string[],
): EventEvidenceRow[] {
  const ev = dictionaryRowsForEvents(eventNames).map((r) => ({
    eventName: r.eventName,
    whatItMeasures: r.measures,
    status: r.status as EventImplementationStatus,
  }));
  const src = dictionaryRowsForSources(extraSources).map((r) => ({
    eventName: r.eventName,
    whatItMeasures: r.measures,
    status: r.status as EventImplementationStatus,
  }));
  return [...ev, ...src];
}

/** Compare average daily counts first vs second half of window for a primary event. */
export function mainTrendFromDaily(events: NormalizedEvent[], primaryEvent: string): string {
  const daily = M.dailyCounts(events, [primaryEvent]);
  const labels = [...daily.keys()].sort();
  if (labels.length < 4) {
    return "Not enough distinct days with this event to describe a trend; widen the date range if possible.";
  }
  const mid = Math.floor(labels.length / 2);
  const first = labels.slice(0, mid);
  const second = labels.slice(mid);
  const avg = (labs: string[]) =>
    labs.length === 0 ? 0 : labs.reduce((s, l) => s + (daily.get(l) || 0), 0) / labs.length;
  const a1 = avg(first);
  const a2 = avg(second);
  const delta = a2 - a1;
  if (Math.abs(delta) < 0.05) {
    return `Daily ${primaryEvent} activity is relatively steady across the window (≈${a1.toFixed(2)} vs ≈${a2.toFixed(2)} per day, first vs second half).`;
  }
  if (delta > 0) {
    return `Daily ${primaryEvent} activity increased in the second half of the window (≈${a1.toFixed(2)} → ≈${a2.toFixed(2)} per day on average).`;
  }
  return `Daily ${primaryEvent} activity decreased in the second half of the window (≈${a1.toFixed(2)} → ≈${a2.toFixed(2)} per day on average).`;
}

export function coverageNoteFromRows(rows: EventEvidenceRow[], zeroCountEvents: string[]): string {
  const partial = rows.filter((r) => r.status === "partial" || r.status === "needs-implementation");
  const parts: string[] = [];
  if (partial.length > 0) {
    parts.push(
      `Some listed streams are partial or not fully instrumented everywhere: ${partial.map((p) => p.eventName).join(", ")}.`,
    );
  }
  if (zeroCountEvents.length > 0) {
    parts.push(`No rows in this date range for: ${zeroCountEvents.join(", ")} (does not imply the feature is unused globally).`);
  }
  if (parts.length === 0) {
    return "All listed event streams are marked tracked in Analytics Info; sparse counts still reflect real usage in this window.";
  }
  return parts.join(" ");
}
