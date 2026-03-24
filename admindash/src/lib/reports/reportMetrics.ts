import type { NormalizedCareSurvey, NormalizedEvent, NormalizedModuleFeedback } from "./types";

export type CohortKey = "navigator" | "self_directed" | "unknown";

export function userKey(e: NormalizedEvent, anonymized: boolean): string | null {
  if (anonymized) {
    return e.anonUserId || null;
  }
  return e.anonUserId || e.uid || null;
}

export function cohortOf(e: NormalizedEvent): CohortKey {
  const m = e.metadata || {};
  const ct = m.cohortType;
  if (ct === "navigator") return "navigator";
  if (ct === "self_directed") return "self_directed";
  if (m.navigator === true) return "navigator";
  if (m.self_directed === true) return "self_directed";
  return "unknown";
}

export function uniqueUsers(events: NormalizedEvent[], anonymized: boolean): Set<string> {
  const s = new Set<string>();
  for (const e of events) {
    const k = userKey(e, anonymized);
    if (k) s.add(k);
  }
  return s;
}

export function usersWithAnyOf(events: NormalizedEvent[], names: string[], anonymized: boolean): Set<string> {
  const want = new Set(names);
  const s = new Set<string>();
  for (const e of events) {
    if (!want.has(e.eventName)) continue;
    const k = userKey(e, anonymized);
    if (k) s.add(k);
  }
  return s;
}

export function countByEvent(events: NormalizedEvent[], name: string): number {
  return events.filter((e) => e.eventName === name).length;
}

export function countByEvents(events: NormalizedEvent[], names: string[]): number {
  const set = new Set(names);
  return events.reduce((n, e) => n + (set.has(e.eventName) ? 1 : 0), 0);
}

export function safeRate(num: number, den: number): number {
  if (den <= 0) return 0;
  return num / den;
}

export function pct(x: number): string {
  return `${Math.round(x * 1000) / 10}%`;
}

/** yyyy-MM-dd in local time */
export function dayKey(d: Date | null): string | null {
  if (!d) return null;
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

export function dailyCounts(events: NormalizedEvent[], eventNames: string[]): Map<string, number> {
  const want = new Set(eventNames);
  const map = new Map<string, number>();
  for (const e of events) {
    if (!want.has(e.eventName)) continue;
    const k = dayKey(e.timestamp);
    if (!k) continue;
    map.set(k, (map.get(k) || 0) + 1);
  }
  return map;
}

export function mergeDailySeries(maps: Map<string, number>[]): { labels: string[]; values: number[] } {
  const keys = new Set<string>();
  for (const m of maps) {
    for (const k of m.keys()) keys.add(k);
  }
  const labels = Array.from(keys).sort();
  const values = labels.map((lab) => maps.reduce((sum, m) => sum + (m.get(lab) || 0), 0));
  return { labels, values };
}

export function avgMetadataNumber(events: NormalizedEvent[], eventName: string, field: string): number | null {
  const vals: number[] = [];
  for (const e of events) {
    if (e.eventName !== eventName) continue;
    const v = e.metadata[field];
    if (typeof v === "number" && !Number.isNaN(v)) vals.push(v);
  }
  if (vals.length === 0) return null;
  return vals.reduce((a, b) => a + b, 0) / vals.length;
}

export function avgModuleUnderstanding(feedback: NormalizedModuleFeedback[]): number | null {
  const vals = feedback.map((f) => f.understandingScore).filter((n): n is number => typeof n === "number");
  if (vals.length === 0) return null;
  return vals.reduce((a, b) => a + b, 0) / vals.length;
}

export function avgCareComposite(surveys: NormalizedCareSurvey[]): number | null {
  const vals = surveys.map((s) => s.confidenceComposite).filter((n): n is number => typeof n === "number");
  if (vals.length === 0) return null;
  return vals.reduce((a, b) => a + b, 0) / vals.length;
}

export function outcomeDistribution(surveys: NormalizedCareSurvey[]): Record<string, number> {
  const dist: Record<string, number> = {};
  for (const s of surveys) {
    for (const v of Object.values(s.rawOutcomes)) {
      dist[v] = (dist[v] || 0) + 1;
    }
  }
  return dist;
}

/** Average duration in seconds for events that carry `duration_seconds` or `durationMs` (e.g. screen_time_spent, session_ended). */
export function avgSecondsForEventNames(events: NormalizedEvent[], names: string[]): number | null {
  const set = new Set(names);
  const vals: number[] = [];
  for (const e of events) {
    if (!set.has(e.eventName)) continue;
    const sec = e.metadata["duration_seconds"];
    const ms = e.durationMs;
    if (typeof sec === "number") vals.push(sec);
    else if (typeof ms === "number") vals.push(ms / 1000);
  }
  if (vals.length === 0) return null;
  return vals.reduce((a, b) => a + b, 0) / vals.length;
}

export function featureDwellSecondsByCohort(events: NormalizedEvent[]): Map<CohortKey, Record<string, number>> {
  const out = new Map<CohortKey, Record<string, number>>();
  const keys: CohortKey[] = ["navigator", "self_directed", "unknown"];
  for (const k of keys) out.set(k, {});

  for (const e of events) {
    if (e.eventName !== "feature_time_spent") continue;
    const sec = e.metadata["duration_seconds"];
    const ms = e.durationMs;
    const seconds =
      typeof sec === "number" ? sec : typeof ms === "number" ? ms / 1000 : 0;
    if (seconds <= 0) continue;
    const feat = String(e.feature || "unknown");
    const c = cohortOf(e);
    const bucket = out.get(c)!;
    bucket[feat] = (bucket[feat] || 0) + seconds;
  }
  return out;
}
